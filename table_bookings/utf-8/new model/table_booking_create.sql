use myservice
go 

create procedure [dbo].[table_booking.create] (@js nvarchar(max),
											   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@table_booking_id	uniqueidentifier,
					@client_id_tb uniqueidentifier = json_value(@js, '$.client_id'),
					@table_id_tb uniqueidentifier = json_value(@js, '$.table_id'),
					@date date = json_value(@js, '$.date'),
					@start_time time = json_value(@js, '$.start_time'),
					@end_time time = json_value(@js, '$.end_time'),
					@guests_count int = json_value(@js, '$.guests_count'),
					@table_booking_status varchar(10) = json_value(@js, '$.status'),
					@capacity_tb int


			--проверка обязательных параметров на null
			if (@table_id_tb is null
				or @date is null
				or @start_time is null
				or @end_time is null
				or @guests_count is null)
				begin
					set @err = 'err.table_booking_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность даты
			if (@date < getdate())
				begin
					set @err = 'err.tabel_booking_create.invalid_date'
					set @errdesc = 'Некорректная дата'

					goto err
				end

			--проверка на корректность статуса
			if @table_booking_status is not null and @table_booking_status not in ('wait_conf', 'confirm', 'cancel', 'success')
				begin
					set @err = 'err.tabel_booking_create.invalid_status'
					set @errdesc = 'Некорректный статус'

					goto err
				end


			select @capacity_tb = [capacity]
			from [dbo].[tables]
			where [id] = @table_id_tb
				and [status] = 'Y'


			--проверка на сущестование столика
			if (@capacity_tb is null)
				begin
					set @err = 'err.table_booking_create.table_not_found'
					set @errdesc = 'Столик не найден'

					goto err
				end

			--проверка на корректность числа гостей
			if (@guests_count < 1 and @guests_count > @capacity_tb)
				begin
					set @err = 'err.table_booking_create.invalid_guests_count'
					set @errdesc = 'Максимальная вместимость = ' + @capacity_tb

					goto err
				end

			--проверка на сущестование клиента
			if @client_id_tb is not null and not exists (select top 1 1 from [dbo].[clients] where [id] = @client_id_tb and [status] = 'Y')
				begin
					set @err = 'err.table_booking_create.client_not_found'
					set @errdesc = 'Клиент не найден'

					goto err
				end

			--проверка времени, что оно попадает в рабочие часы
			if not exists (select top 1 1
						   from [dbo].[tables] as [t]
						   join [dbo].[restaurants] as [r] on [t].[restaurant_id] = [r].[id]
						   where [t].[id] = @table_id_tb
								and (@start_time between [r].[work_start] and [r].[work_end])
								and (@end_time between [r].[work_start] and [r].[work_end])
								and [t].[status] = 'Y'
								and [r].[status] = 'Y')
				begin
					set @err = 'err.table_booking_create.invalid_time'
					set @errdesc = 'Указанное время не соответствует режиму работы'

					goto err
				end

			--проверка на занятость столика
			if exists (select top 1 1
					   from [dbo].[table_bookings]
					   where [table_id] = @table_id_tb
							and [date] = @date
							and (([start_time] between @start_time and @end_time) or ([end_time] between @start_time and @end_time))
							and [status] in ('wait_conf', 'confirm'))
				begin
					set @err = 'err.table_booking_create.table_is_occupied'
					set @errdesc = 'Столик занят в указанное время'

					goto err
				end

		
			--добавляем значения в таблицу
			set @table_booking_id = newid()
			insert into [dbo].[table_bookings] ([id], [client_id], [table_id], [date], [start_time], [end_time], [guests_count], [status])
			values (@table_booking_id,
					@client_id_tb,
					@table_id_tb,
					@date,
					@start_time,
					@end_time,
					@guests_count,
					isnull(@table_booking_status, 'wait_conf'))
		
			--выводим
			set @rp = (select @table_booking_id as [id],
							  @client_id_tb as [client_id],
							  @table_id_tb as [table_id],
							  @date as [date],
							  @start_time as [start_time],
							  @end_time as [end_time],
							  @guests_count as [guest_count],
							  isnull(@table_booking_status, 'wait_conf') as [status]
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