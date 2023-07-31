use _DV
go 

create procedure [dbo].[ms_block]
	@action varchar(50),
	@js varchar(max),
	@rp varchar(max) out

	as
	begin

		set nocount on

		begin try

			declare @err nvarchar(100),
					@errdesc nvarchar(max),
					@sba nvarchar(50) = substring(@action,1,charindex('.',@action)-1)

			set dateformat dmy

			if @sba in ('table')
				begin

					declare @table_id	uniqueidentifier = json_value(@js, '$.id')


					if @action in ('table.deactive')
						begin try

							set transaction isolation level serializable

							begin transaction

								select [number]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

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

								select [number]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id

								--меняем статус
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

					if @action in ('table_booking.create')
						begin try
							
							set transaction isolation level serializable

							begin transaction
							
								select [number]
								from [dbo].[tables] with (updlock)
								where [id] = @table_id
		
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

								--изменяем бронь
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

								--изменяем бронь
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

								--изменяем бронь
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