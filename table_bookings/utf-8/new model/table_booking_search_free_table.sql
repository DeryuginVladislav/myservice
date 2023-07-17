use myservice
go

create procedure [dbo].[table_booking.search_free_table] (@js nvarchar(max),
														  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@restaurant_id_tb	uniqueidentifier = json_value(@js, '$.restaurant_id'),
					@date date = json_value(@js, '$.date'),
					@start_time time = json_value(@js, '$.start_time'),
					@end_time time = json_value(@js, '$.end_time'),
					@guests_count int = json_value(@js, '$.guests_count')


			--проверка на наличие id
			if (@restaurant_id_tb is null)
				begin
					set @err = 'err.table_booking_search_free_table.unset_field'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка обязательных параметров на null
			if (@date is null
				or @start_time is null
				or @end_time is null
				or @guests_count is null)
				begin
					set @err = 'err.table_booking_search_free_table.hasnt_data'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность даты
			if (@date < getdate())
				begin
					set @err = 'err.tabel_booking_search_free_tables.invalid_date'
					set @errdesc = 'Некорректная дата'

					goto err
				end

			--проверка на корректность числа гостей
			if (@guests_count < 1 and @guests_count > 30)
				begin
					set @err = 'err.table_booking_search_free_table.invalid_guests_count'
					set @errdesc = 'Некорректное число гостей'

					goto err
				end

			--проверка на существование ресторана
			if not exists (select top 1 1 from [dbo].[restaurants] where [id] = @restaurant_id_tb and [status] = 'Y')
				begin
					set @err = 'err.table_booking_search_free_table.restaurant_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка корректности времени, что оно попадает в рабочие часы
			if not exists (select top 1 1
						   from [dbo].[restaurants]
						   where [id] = @restaurant_id_tb
								and (@start_time between [work_start] and [work_end])
								and (@end_time between [work_start] and [work_end])
								and [status] = 'Y')
				begin
					set @err = 'err.table_booking_search_free_table.invalid_time'
					set @errdesc = 'Указанное время не соответствует режиму работы'

					goto err
				end
		
			--выводим
			set @rp = (select top 1 t.*
					   from [dbo].[tables] t
					   left join [dbo].[table_bookings] tb on tb.[table_id] = t.id
					   where (tb.[id] is null 
							or (@date = [date] and (@start_time not between [start_time] and [end_time]) and (@end_time not between [start_time] and [end_time]))
							and t.[status] = 'Y')
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