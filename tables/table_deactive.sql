use myservice
go

create procedure [dbo].[table_deactive] (@js nvarchar(max),
										  @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@status char(1),
					@free_table_id uniqueidentifier,
					@restaurant_id uniqueidentifier,
					@capacity int

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.table_deactive.unset_field'
					set @errdesc = 'Не указан id'

					goto err
				end


			select @status = [status],
				   @restaurant_id = [restaurant_id],
				   @capacity = [capacity]
			from [dbo].[tables] 
			where [id] = @id

			
			--проверка на существование столика с таким id
			if (@status is null)
				begin
					set @err = 'err.table_deactive.table_not_found'
					set @errdesc = 'Столик с таким id не найден'

					goto err
				end

			--проверка статуса клиента
			if (@status = 'N')
				begin
					set @err = 'err.table_deactive.table_already_deactive'
					set @errdesc = 'Столик уже деактивирован'

					goto err
				end

			--ищем столик у которого отсутствуют брони (который сможет заменить его)
			select top 1 @free_table_id = [tb].[table_id]
			from [dbo].[tables] as [t]
			left join [dbo].[table_bookings] as [tb] on [t].[id] = [tb].[table_id]
			where [t].[restaurant_id] = @restaurant_id
				and [tb].[table_id] is null
				and [t].[capacity] >= @capacity
				and [t].[status] = 'Y'

			--проверка на брони
			if (@free_table_id is null)
				begin
					set @err = 'err.table_deactive.active_bookings_exist'
					set @errdesc = 'Нет возможности заменить столик'

					goto err
				end
			else
				begin transaction

					--меняем id столика в бронях
					update [dbo].[table_bookings]
					set [table_id] = @free_table_id
					where [table_id] = @id

					--деактивируем столик
					update [dbo].[tables]
					set [status] = 'N'
					where [id] = @id

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