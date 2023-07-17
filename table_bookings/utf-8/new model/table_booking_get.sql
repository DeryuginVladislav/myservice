use myservice
go

create procedure [dbo].[table_booking.get] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@table_booking_id uniqueidentifier = json_value(@js, '$.id'),
					@client_id_tb uniqueidentifier = json_value(@js, '$.client_id')

				--выводим
				set @rp = (select *
						   from [dbo].[table_bookings]
						   where ([id] = @table_booking_id or [client_id] = @client_id_tb) and [status] in ('wait_conf', 'confirm')
						   for json path)
				return	  
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