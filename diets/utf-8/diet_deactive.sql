use myservice
go

create procedure [dbo].[diet.deactive] (@js nvarchar(max),
										@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@diet_id	uniqueidentifier = json_value(@js, '$.id'),
					@diet_status char(1)

			--проверка на наличие id
			if (@diet_id is null)
				begin
					set @err = 'err.diet_deactive.unset_field'
					set @errdesc = 'Диета не найдена'

					goto err
				end


			select @diet_status = [status]
			from [dbo].[diets] 
			where [id] = @diet_id

			
			--проверка на существование диеты с таким id
			if (@diet_status is null)
				begin
					set @err = 'err.diet_deactive.object_not_found'
					set @errdesc = 'Диета не найдена'

					goto err
				end

			--проверка статуса диеты
			if (@diet_status = 'N')
				begin
					set @err = 'err.diet_deactive.diet_already_deactive'
					set @errdesc = 'Диета уже деактивирована'

					goto err
				end

			begin transaction

				--изменяем диету
				update [dbo].[diets] 
				set [status] = 'N'
				where [id] = @diet_id and [status] = 'Y'

				--деактивируем связи клиент - диета
				update [dbo].[clients_diet]
				set [status] = 'N'
				where [diet_id] = @diet_id and [status] = 'Y'

				--деактивируем связи блюдо - диета
				update [dbo].[dish_type]
				set [status] = 'N'
				where [diet_id] = @diet_id and [status] = 'Y'

			commit transaction

			--выводим
			set @rp = (select @diet_id as [id],
							  'N' as [status]
					   for json path, without_array_wrapper)

			goto ok

		end try

		begin catch
			rollback transaction

			set @err = 'err.sys.myservice'
			set @errdesc = error_message()

			goto err
		end catch


	   ok: 
	       set @rp = (select 'ok' [status], json_query(@rp) [response] for json path, without_array_wrapper)
		   return
	   

	   err: 
	       set @rp = (select 'err' [status], lower(@err) [err], @errdesc [errdesc] for json path, without_array_wrapper)
		   return

	end
