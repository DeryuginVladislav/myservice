use myservice
go

create procedure [dbo].[dish.deactive] (@js nvarchar(max),
										@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@dish_id	uniqueidentifier = json_value(@js, '$.id'),
					@dish_status char(1)

			--проверка на наличие id
			if (@dish_id is null)
				begin
					set @err = 'err.dish_deactive.unset_field'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end


			select @dish_status = [status]
			from [dbo].[dishes] 
			where [id] = @dish_id

			
			--проверка на существование блюда с таким id
			if (@dish_status is null)
				begin
					set @err = 'err.dish_deactive.object_not_found'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end

			--проверка статуса блюда
			if (@dish_status = 'N')
				begin
					set @err = 'err.dish_deactive.dish_already_deactive'
					set @errdesc = 'Блюдо уже деактивировано'

					goto err
				end

			begin transaction

				--деактивируем блюдо
				update [dbo].[dishes]
				set [status] = 'N'
				where [id] = @dish_id

				--деактивируем связи блюдо - диета
				update [dbo].[dish_type]
				set [status] = 'N'
				where [dish_id] = @dish_id and [status] = 'Y'

				--деактивируем ингридиенты
				update [dbo].[ingredients]
				set [status] = 'N'
				where [dish_id] = @dish_id and [status] = 'Y'

			commit transaction

				--выводим
				set @rp = (select @dish_id as [id],
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