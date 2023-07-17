use myservice
go

create procedure [dbo].[diet_deactive] (@js nvarchar(max),
										@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@status char(1)

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.diet_deactive.unset_field'
					set @errdesc = 'Ќе указан id'

					goto err
				end


			select @status = [status]
			from [dbo].[diets] 
			where [id] = @id

			
			--проверка на существование клиента с таким id
			if (@status is null)
				begin
					set @err = 'err.diet_deactive.object_not_found'
					set @errdesc = 'ƒиета с таким id не найдена'

					goto err
				end

			--проверка статуса клиента
			if (@status = 'N')
				begin
					set @err = 'err.diet_deactive.diet_already_deactive'
					set @errdesc = 'ƒиета уже деактивирована'

					goto err
				end

			begin transaction

				--измен€ем диету
				update [dbo].[diets] 
				set [status] = 'N'
				where [id] = @id and [status] = 'Y'

				--деактивируем св€зи клиент - диета
				update [dbo].[clients_diet]
				set [status] = 'N'
				where [diet_id] = @id and [status] = 'Y'

				--деактивируем св€зи блюдо - диета
				update [dbo].[dish_type]
				set [status] = 'N'
				where [diet_id] = @id and [status] = 'Y'

			commit transaction

			--выводим
			set @rp = (select @id as [id],
							  'N' as [status]
					   for json path, without_array_wrapper)

			goto ok

		end try

		begin catch
			rollback transaction

			set @err = error_number()
			set @errdesc = error_message()

			goto err
		end catch


		err: 
			set @rp = (select 'err' as [status],
							  lower(@err) as [err],
							  @errdesc as [errdesc] 
					   for json path, without_array_wrapper)
			set nocount off
			return

		ok: 
			set @rp = (select 'ok' as [status],
							  json_query(@rp) as [response] 
					   for json path, without_array_wrapper)
			set nocount off
			return
	end