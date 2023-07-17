use myservice
go 

create procedure [dbo].[table_booking_create] (@js nvarchar(max),
											   @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier,
					@client_id uniqueidentifier = json_value(@js, '$.client_id'),
					@table_id uniqueidentifier = json_value(@js, '$.table_id'),
					@date date = json_value(@js, '$.date'),
					@start_time time = json_value(@js, '$.start_time'),
					@end_time time = json_value(@js, '$.end_time'),
					@guests_count int = json_value(@js, '$.guests_count'),
					@capacity int

			--проверка об€зательных параметров на null
			if (@client_id is null
				or @table_id is null
				or @date is null
				or @start_time is null
				or @end_time is null
				or @guests_count is null)
				begin
					set @err = 'err.table_booking_create.unset_field'
					set @errdesc = '”казаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность даты
			if (isdate(convert(nvarchar(10), @date, 104)) = 0)
				begin
					set @err = 'err.tabel_booking_create.invalid_date'
					set @errdesc = 'Ќекорректна€ дата'

					goto err
				end

			--проверка на корректность времени
			if (try_convert(time, @start_time) is null or try_convert(time, @start_time) is null)
				begin
					set @err = 'err.table_booking_create.invalid_time'
					set @errdesc = 'Ќекорректное врем€'

					goto err
				end


			select @capacity = [capacity]
			from [dbo].[tables]
			where [id] = @table_id
				and [status] = 'Y'


			--проверка на сущестование столика
			if (@capacity is null)
				begin
					set @err = 'err.table_booking_create.table_not_found'
					set @errdesc = '—толик не найден'

					goto err
				end

			--проверка на корректность числа гостей
			if (@guests_count < 1
				and @guests_count > @capacity)
				begin
					set @err = 'err.table_booking_create.invalid_guests_count'
					set @errdesc = 'Ќекорректное число гостей'

					goto err
				end

			--проверка на сущестование клиента
			if not exists (select 1
						   from [dbo].[clients]
						   where [id] = @client_id
							and [status] = 'Y')
				begin
					set @err = 'err.table_booking_create.client_not_found'
					set @errdesc = ' лиент не найден'

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
					set @err = 'err.table_booking_create.invalid_time'
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
					set @err = 'err.table_booking_create.table_is_occupied'
					set @errdesc = '—толик зан€т в указанное врем€'

					goto err
				end

		
			--добавл€ем значени€ в таблицу
			set @id = newid()
			insert into [dbo].[table_bookings] ([id], [client_id], [table_id], [date], [start_time], [end_time], [guest_count])
				values (@id,
						@client_id,
						@table_id,
						@date,
						@start_time,
						@end_time,
						@guests_count)
		
			--выводим
			set @rp = (select @id as [id],
							  @client_id as [client_id],
							  @table_id as [table_id],
							  @date as [date],
							  @start_time as [start_time],
							  @end_time as [end_time],
							  @guests_count as [guest_count]
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