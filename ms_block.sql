USE [_DV]
GO
/****** Object:  StoredProcedure [dbo].[ms_block]    Script Date: 31.07.2023 14:32:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[ms_block]
	@action varchar(50),
	@js varchar(max),
	@rp varchar(max) out

	as
	begin

		set nocount on

		begin try

			declare @err nvarchar(100),
					@errdesc nvarchar(max),
					@sba nvarchar(50) = substring(@action,1,charindex('.',@action)-1),

					@rp_ nvarchar(max),
					@jsT nvarchar(max)

			set dateformat dmy

			if @sba in ('table')
				begin

					declare @table_id	uniqueidentifier = json_value(@js, '$.id')
						  , @restaurant_id_t uniqueidentifier = json_value(@js, '$.restaurant_id')
						  , @number int = json_value(@js, '$.number')
						  , @table_status char(1)


					if @action in ('table.deactive')
						begin try

							set transaction isolation level serializable

							begin transaction

								select @table_status = [status]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

								--проверка статуса столика
								if (@table_status = 'N')
									begin
										set @err = 'err.table_deactive.table_already_deactive'
										set @errdesc = '—толик уже деактивирован'

										goto err
									end

								--провер€ем на активные брони
								set @rp_ = null
								set @jsT = (select @table_id as [table_id] for json path, without_array_wrapper)
								exec [dbo].[ms_api] 'table_booking.get', @jsT, @rp_ out

								if json_value(@rp_, '$.response[0].id') is not null
									begin
										set @err = 'err.table_deactive.active_bookings_exists'
										set @errdesc = '” столика есть активные брони'

										goto err
									end

								--деактивируем столик
								update [dbo].[tables]
								set [status] = 'N'
								where [id] = @table_id

							commit transaction

							--выводим
							set @rp = (select @table_id as [id],
												'N' as [status]
										for json path, without_array_wrapper)
			
							goto ok

						end try

						begin catch

							rollback transaction

							set @err = 'err.sys.myservice'
							set @errdesc = error_message()

							goto err
						
						end catch


					if @action in ('table.active')
						begin try

							set transaction isolation level serializable

							begin transaction

								select @table_status = [status],
									   @restaurant_id_t = [restaurant_id],
									   @number = [number]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

								--проверка на активный статус
								if (@table_status = 'Y')
									begin
										set @err = 'err.table_active.table_already_active'
										set @errdesc = '—толик уже активен'

										goto err
									end

								--проверка на существование ресторана c таким id
								set @rp_ = null
								set @jsT = (select @restaurant_id_t as [id] for json path, without_array_wrapper)
								exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

								if json_value(@rp_, '$.response.id') is null
									begin
										set @err = 'err.table_active.restaurant_not_found'
										set @errdesc = '–есторан не найден'

										goto err
									end

								--проверка на зан€тость номера столика
								set @rp_ = null
								set @jsT = (select @restaurant_id_t as [restaurant_id],
												   @number as [number]
											for json path, without_array_wrapper)
								exec [dbo].[ms_api] 'table.get', @jsT, @rp_ out

								if json_value(@rp_, '$.response[0].id') is not null
									begin
										set @err = 'err.table_active.number_already_exist'
										set @errdesc = 'Ќомер столика зан€т'

										goto err
									end

								--мен€ем статус
								update [dbo].[tables] 
								set [status] = 'Y'
								where [id] = @table_id

							commit transaction

							--выводим
							set @rp = (select @table_id as [id],
											  'Y' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end try

						begin catch

							rollback transaction

							set @err = 'err.sys.myservice'
							set @errdesc = error_message()

							goto err

						end catch

				end


			if @sba in ('table_booking')
				begin

					declare @table_booking_id	uniqueidentifier = json_value(@js, '$.id')
						  , @client_id_tb uniqueidentifier = json_value(@js, '$.client_id')
						  , @table_id_tb uniqueidentifier = json_value(@js, '$.table_id')
						  , @date date = json_value(@js, '$.date')
						  , @start_time time = json_value(@js, '$.start_time')
						  , @end_time time = json_value(@js, '$.end_time')
						  , @guests_count int = json_value(@js, '$.guests_count')
						  , @table_booking_status varchar(10) = json_value(@js, '$.status')
						  , @table_status_tb char(1)

					if @action in ('table_booking.create')
						begin try
							
							set transaction isolation level serializable

							begin transaction
							
								select @table_status_tb = [status]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

								--проверка статуса столика
								if (@table_status_tb = 'N')
									begin
										set @err = 'err.table_booking_create.table_deactive'
										set @errdesc = '—толик деактивирован'

										goto err
									end
		
								--проверка на зан€тость столика
								if exists (select top 1 1
										   from [dbo].[table_bookings] with (nolock)
										   where [table_id] = @table_id_tb
												and [date] = @date
												and (([start_time] between @start_time and @end_time) or ([end_time] between @start_time and @end_time))
												and [status] in ('wait_conf', 'confirm'))
									begin
										set @err = 'err.table_booking_create.table_is_occupied'
										set @errdesc = '—толик зан€т в указанное врем€'

										goto err
									end

								--добавл€ем значени€ в таблицу
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

							commit transaction
		
							--выводим
							set @rp = (select @table_booking_id as [id],
												@client_id_tb as [client_id],
												@table_id_tb as [table_id],
												@date as [date],
												@start_time as [start_time],
												@end_time as [end_time],
												@guests_count as [guests_count],
												isnull(@table_booking_status, 'wait_conf') as [status]
										for json path, without_array_wrapper)

							goto ok

						end try

						begin catch

							rollback transaction

							set @err = 'err.sys.myservice'
							set @errdesc = error_message()

							goto err

						end catch


					if @action in ('table_booking.confirm')
						begin try

							set transaction isolation level serializable

							begin transaction
							
								select [number]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

								select @table_booking_status = [status]
								from [dbo].[table_bookings] with (nolock)
								where [id] = @table_booking_id

								--проверка на статус 
								if @table_booking_status in ('cancel', 'success')
									begin
										set @err = 'err.table_booking_confirm.booking_ended'
										set @errdesc = 'Ѕронь закончилась'

										goto err
									end

								--проверка на статус 
								if @table_booking_status = 'confirm'
									begin
										set @err = 'err.table_booking_confirm.booking_already_confirm'
										set @errdesc = 'Ѕронь уже подтверждена'

										goto err
									end	

								--измен€ем бронь
								update [dbo].[table_bookings] 
								set [status] = 'confirm'
								where [id] = @table_booking_id

							commit transaction
		
							--выводим
							set @rp = (select @table_booking_id as [id],
											  'confirm' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end try

						begin catch

							rollback transaction

							set @err = 'err.sys.myservice'
							set @errdesc = error_message()

							goto err

						end catch


					if @action in ('table_booking.cancel')
						begin try

							set transaction isolation level serializable

							begin transaction
							
								select [number]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

								select @table_booking_status = [status]
								from [dbo].[table_bookings] with (nolock)
								where [id] = @table_booking_id

								--проверка на существование брони с таким id
								if @table_booking_status is null
									begin
										set @err = 'err.table_booking_cancel.table_booking_not_found'
										set @errdesc = 'Ѕронь не найдена'

										goto err
									end


								--проверка на статус 
								if @table_booking_status in ('cancel', 'success')
									begin
										set @err = 'err.table_booking_cancel.booking_ended'
										set @errdesc = 'Ѕронь уже закончилась'

										goto err
									end	

								--измен€ем бронь
								update [dbo].[table_bookings] 
								set [status] = 'cancel'
								where [id] = @table_booking_id

							commit transaction
		
							--выводим
							set @rp = (select @table_booking_id as [id],
											  'cancel' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end try

						begin catch

							rollback transaction

							set @err = 'err.sys.myservice'
							set @errdesc = error_message()

							goto err
							
						end catch


					if @action in ('table_booking.success')
						begin try

							set transaction isolation level serializable

							begin transaction
							
								select [number]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

								--проверка на статус 
								if @table_booking_status = 'wait_conf'
									begin
										set @err = 'err.table_booking_success.booking_not_confirm'
										set @errdesc = 'Ѕронь не подтверждена'

										goto err
									end	

								--проверка на статус 
								if @table_booking_status = 'cancel'
									begin
										set @err = 'err.table_booking_success.booking_canceled'
										set @errdesc = 'Ѕронь отменена'

										goto err
									end	

								--проверка на статус 
								if @table_booking_status = 'success'
									begin
										set @err = 'err.table_booking_success.booking_already_success'
										set @errdesc = 'Ѕронь уже закончилась'

										goto err
									end

								--измен€ем бронь
								update [dbo].[table_bookings] 
								set [status] = 'success'
								where [id] = @table_booking_id

							commit transaction
		
							--выводим
							set @rp = (select @table_booking_id as [id],
											  'success' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end try

						begin catch

							rollback transaction

							set @err = 'err.sys.myservice'
							set @errdesc = error_message()

							goto err

						end catch

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