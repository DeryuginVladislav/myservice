use myservice
go 

create procedure [dbo].[table_booking.seat_now] (@js nvarchar(max),
												 @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@restaurant_id_tb	uniqueidentifier = json_value(@js, '$.restaurant_id'),
					@client_id_tb uniqueidentifier = json_value(@js, '$.client_id'),
					@date date = cast(getdate() as date),
					@start_time time = json_value(@js, '$.start_time'),
					@end_time time = json_value(@js, '$.end_time'),
					@guests_count int = json_value(@js, '$.guests_count'),
					
					@data_for_search nvarchar(max),
					@rp_table nvarchar(max),

					@data_for_create nvarchar(max)

			--проверка обязательных параметров на null
			if (@restaurant_id_tb is null
				or @start_time is null
				or @end_time is null
				or @guests_count is null)
				begin
					set @err = 'err.table_booking_seat_now.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--ищем столик
			set @data_for_search = (select @restaurant_id_tb as [restaurant_id],
										   @date as [date],
										   @start_time as [start_time],
										   @end_time as [end_time],
										   @guests_count as [guests_count]
									for json path, without_array_wrapper)

			exec [dbo].[table_booking.search_free_table] @data_for_search, @rp_table out

			if @rp_table is null
				begin
					set @err = 'err.table_booking_seat_now.table_not_found'
					set @errdesc = 'Свободных столиков нет'

					goto err
				end
			else
				begin

					--создаем бронь
					set @data_for_create = (select @client_id_tb as [client_id],
												   json_value(@rp_table, '$.id') as [table_id],
												   @date as [date],
												   @start_time as [start_time],
												   @end_time as [end_time],
												   @guests_count as [guests_count],
												   'confirm' as [status]
											for json path, without_array_wrapper)

					exec [dbo].[table_booking.create] @data_for_create, @rp out

					goto ok

				end

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