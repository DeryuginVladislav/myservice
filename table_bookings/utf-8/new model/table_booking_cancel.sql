use myservice
go

create procedure [dbo].[table_booking.cancel] (@js nvarchar(max),
											   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@table_booking_id	uniqueidentifier = json_value(@js, '$.id'),
					@table_booking_status varchar(10)

			--проверка на наличие id
			if (@table_booking_id is null)
				begin
					set @err = 'err.table_booking_cancel.unset_field'
					set @errdesc = 'Бронь не найдена'

					goto err
				end

			select @table_booking_status = [status]
			from [dbo].[table_bookings] 
			where [id] = @table_booking_id

			--проверка на существование брони с таким id
			if @table_booking_status is null
				begin
					set @err = 'err.table_booking_cancel.table_booking_not_found'
					set @errdesc = 'Бронь не найдена'

					goto err
				end


			--проверка на статус 
			if @table_booking_status in ('cancel', 'success')
				begin
					set @err = 'err.table_booking_cancel.booking_ended'
					set @errdesc = 'Бронь уже закончилась'

					goto err
				end	

	

			--изменяем бронь
			update [dbo].[table_bookings] 
			set [status] = 'cancel'
			where [id] = @table_booking_id
		
			--выводим
			set @rp = (select @table_booking_id as [id],
							  'cancel' as [status]
					   for json path, without_array_wrapper)

			goto ok

		end try

		begin catch
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