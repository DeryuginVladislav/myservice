use myservice
go

create procedure [dbo].[table_booking_edit] (@js nvarchar(max),
										     @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@date date = json_value(@js, '$.date'),
					@start_time time = json_value(@js, '$.start_time'),
					@end_time time = json_value(@js, '$.end_time'),
					@guests_count int = json_value(@js, '$.guests_count'),
					@table_id uniqueidentifier
			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.table_booking_edit.unset_field'
					set @errdesc = 'Ќе указан id'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@date is null 
				and @start_time is null
				and @end_time is null
				and @guests_count is null)
				begin
					set @err = 'err.table_booking_edit.hasnt_data'
					set @errdesc = 'ќтсутствуют данные редактировани€'

					goto err
				end

			--проверка на корректность даты
			if (isdate(convert(nvarchar(10), @date, 104)) = 0)
				begin
					set @err = 'err.tabel_booking_edit.invalid_date'
					set @errdesc = 'Ќекорректна€ дата'

					goto err
				end

			--проверка на корректность времени
			if (try_convert(time, @start_time) is null or try_convert(time, @start_time) is null)
				begin
					set @err = 'err.table_booking_edit.invalid_time'
					set @errdesc = 'Ќекорректное врем€'

					goto err
				end

			select @table_id = [table_id]
			from [dbo].[table_bookings]
			where [id] = @id
				and [status] = 'Y'

			--проверка на существование брони с таким id
			if (@table_id is null)
				begin
					set @err = 'err.table_booking_edit.table_booking_not_found'
					set @errdesc = 'Ѕронь с таким id не найдена'

					goto err
				end


			--проверка на корректность числа гостей
			if (@guests_count < 1
				and @guests_count > (select [capacity]
									 from [dbo].[tables]
									 where [id] = @table_id))
				begin
					set @err = 'err.table_booking_edit.invalid_guests_count'
					set @errdesc = 'Ќекорректное число гостей'

					goto err
				end


			--проверка корректности времени, что оно попадает в рабочие часы
			if not exists (select 1
						   from [dbo].[tables] as [t]
						   join [dbo].[restaurants] as [r] on [t].[restaurant_id] = [r].[id]
						   where [t].[id] = @table_id
								and (@start_time between [r].[work_start] and [r].[work_end])
								and (@end_time between [r].[work_start] and [r].[work_end])
								and [t].[status] = 'Y')
				begin
					set @err = 'err.table_booking_edit.invalid_time'
					set @errdesc = '”казанное врем€ не соответствует режиму работы'

					goto err
				end

			--проверка на зан€тость столика
			if exists (select 1
					   from [dbo].[table_bookings]
					   where [table_id] = @table_id
							and [date] = @date
							and (([start_time] between @start_time and @end_time) or ([end_time] between @start_time and @end_time))
							and [status] = 'Y')
				begin
					set @err = 'err.table_booking_edit.table_is_occupied'
					set @errdesc = '—толик зан€т в указанное врем€'

					goto err
				end
	

			--измен€ем ресторан
			update [dbo].[table_bookings] 
			set [date] = isnull(@date, [date]),
				[start_time] = isnull(@start_time, [start_time]),
				[end_time] = isnull(@end_time, [end_time]),
				[guests_count] = isnull(@guests_count, [guests_count])
			where [id] = @id
		
			--выводим
			set @rp = (select @id as [id],
							  @table_id as [table_id],
							  @date as [date],
							  @start_time as [start_time],
							  @end_time as [end_time],
							  @guests_count as [guests_count]
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