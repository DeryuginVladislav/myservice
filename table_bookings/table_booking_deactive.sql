use myservice
go

create procedure [dbo].[table_booking_deactive] (@js nvarchar(max),
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
					set @err = 'err.table_booking_deactive.unset_field'
					set @errdesc = 'Не указан id'

					goto err
				end


			select @status = [status]
			from [dbo].[table_bookings] 
			where [id] = @id

			
			--проверка на существование брони с таким id
			if (@status is null)
				begin
					set @err = 'err.table_booking_deactive.object_not_found'
					set @errdesc = 'Бронь с таким id не найдена'

					goto err
				end

			--проверка статуса брони
			if (@status = 'N')
				begin
					set @err = 'err.table_booking_deactive.booking_already_deactive'
					set @errdesc = 'Бронь уже деактивирована'

					goto err
				end

			--деактивируем бронь
			update [dbo].[table_bookings]
			set [status] = 'N'
			where [id] = @id

			--выводим
			set @rp = (select @id as [id],
							  'N' as [status]
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