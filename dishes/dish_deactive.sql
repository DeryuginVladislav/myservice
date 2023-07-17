use myservice
go

create procedure [dbo].[dish_deactive] (@js nvarchar(max),
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
					set @err = 'err.dish_deactive.unset_field'
					set @errdesc = 'Не указан id'

					goto err
				end


			select @status = [status]
			from [dbo].[dishes] 
			where [id] = @id

			
			--проверка на существование блюда с таким id
			if (@status is null)
				begin
					set @err = 'err.dish_deactive.object_not_found'
					set @errdesc = 'Блюдо с таким id не найдено'

					goto err
				end

			--проверка статуса блюда
			if (@status = 'N')
				begin
					set @err = 'err.dish_deactive.dish_already_deactive'
					set @errdesc = 'Блюдо уже деактивировано'

					goto err
				end

			begin transaction

				--деактивируем блюдо
				update [dbo].[dishes]
				set [status] = 'N'
				where [id] = @id

				--деактивируем связи блюдо - диета
				update [dbo].[dish_type]
				set [status] = 'N'
				where [dish_id] = @id

				--деактивируем ингридиенты
				update [dbo].[ingredients]
				set [status] = 'N'
				where [dish_id] = @id

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