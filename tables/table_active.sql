use myservice
go

create procedure [dbo].[table_active] (@js nvarchar(max),
									   @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@status char(1),
					@restaurant_id uniqueidentifier

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.table_active.unset_field'
					set @errdesc = 'Не указан id'

					goto err
				end

			select @status = [status],
				   @restaurant_id = [restaurant_id]
			from [tables]
			where [id] = @id


			--проверка на активный статус
			if (@status = 'Y')
				begin
					set @err = 'err.table_active.table_already_active'
					set @errdesc = 'Столик уже активен'

					goto err
				end

			--проверка на существование ресторана c таким id
			if not exists (select 1
						   from [dbo].[restaurants]
						   where [id] = @restaurant_id
								and [status] = 'Y')
				begin
					set @err = 'err.table_active.restaurant_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--меняем статус
			update [dbo].[tables] 
			set [status] = 'Y'
			where [id] = @id

			--выводим
			set @rp = (select @id as [id],
							  'Y' as [status]
					   for json path, without_array_wrapper)

			goto ok

		end try

		begin catch
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