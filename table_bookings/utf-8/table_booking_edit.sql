use myservice
go

create procedure [dbo].[table_booking.edit] (@js nvarchar(max),
										     @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@table_booking_id	uniqueidentifier = json_value(@js, '$.id'),
					@date date = json_value(@js, '$.date'),
					@start_time time = json_value(@js, '$.start_time'),
					@end_time time = json_value(@js, '$.end_time'),
					@guests_count int = json_value(@js, '$.guests_count'),
					@table_id_tb uniqueidentifier,
					@old_start_time time,
					@old_end_time time

			--проверка на наличие id
			if (@table_booking_id is null)
				begin
					set @err = 'err.table_booking_edit.unset_field'
					set @errdesc = 'Бронь не найдена'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@date is null 
				and @start_time is null
				and @end_time is null
				and @guests_count is null)
				begin
					set @err = 'err.table_booking_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность даты
			if (@date is not null and @date < getdate())
				begin
					set @err = 'err.tabel_booking_edit.invalid_date'
					set @errdesc = 'Некорректная дата'

					goto err
				end

			select @table_id_tb = [table_id],
				   @old_start_time = [start_time],
				   @old_end_time = [end_time]
			from [dbo].[table_bookings]
			where [id] = @table_booking_id
				and [status] = 'Y'

			--проверка на существование брони с таким id
			if (@table_id_tb is null)
				begin
					set @err = 'err.table_booking_edit.table_booking_not_found'
					set @errdesc = 'Бронь не найдена'

					goto err
				end


			--проверка на корректность числа гостей
			if ( @guests_count is not null 
				and @guests_count < 1 
				and @guests_count > (select [capacity] from [dbo].[tables] where [id] = @table_id_tb))
				begin
					set @err = 'err.table_booking_edit.invalid_guests_count'
					set @errdesc = 'Некорректное число гостей'

					goto err
				end


			--проверка корректности времени, что оно попадает в рабочие часы
			if @start_time is not null or @end_time is not null
				begin
					if not exists (select top 1 1
								   from [dbo].[tables] as [t]
								   join [dbo].[restaurants] as [r] on [t].[restaurant_id] = [r].[id]
								   where [t].[id] = @table_id_tb
										and (@start_time is null or (@start_time between [r].[work_start] and [r].[work_end]))
										and (@end_time is null or (@end_time between [r].[work_start] and [r].[work_end]))
										and [t].[status] = 'Y')
						begin
							set @err = 'err.table_booking_edit.invalid_time'
							set @errdesc = 'Указанное время не соответствует режиму работы'

							goto err
						end
				end

			--проверка на занятость столика
			if @table_id_tb is not null
				begin
					if exists (select top 1 1
							   from [dbo].[table_bookings]
							   where [table_id] = @table_id_tb
									and [date] = @date
									and (([start_time] between isnull(@start_time, @old_start_time) and isnull(@end_time, @old_end_time)) 
										or ([end_time] between isnull(@start_time, @old_start_time) and isnull(@end_time, @old_end_time)))
									and [status] = 'Y')
						begin
							set @err = 'err.table_booking_edit.table_is_occupied'
							set @errdesc = 'Столик занят в указанное время'

							goto err
						end
				end
	

			--изменяем ресторан
			update [dbo].[table_bookings] 
			set [date] = isnull(@date, [date]),
				[start_time] = isnull(@start_time, [start_time]),
				[end_time] = isnull(@end_time, [end_time]),
				[guests_count] = isnull(@guests_count, [guests_count])
			where [id] = @table_booking_id
		
			--выводим
			set @rp = (select * from [dbo].[table_bookings]
					   where [id] = @table_booking_id
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