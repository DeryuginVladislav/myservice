use myservice
go

create procedure [dbo].[restaurant.get] (@js nvarchar(max),
										 @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@restaurant_id	  uniqueidentifier = json_value(@js, '$.id'),
					@restaurant_name nvarchar(25) = json_value(@js, '$.name'),
					@address nvarchar(50) = json_value(@js, '$.address'),
					@restaurant_phone nvarchar(11) = json_value(@js, '$.phone'),
					@restaurant_email nvarchar(64) = json_value(@js, '$.email')

				--выводим
				set @rp = (select *
						   from [dbo].[restaurants]
						   where ([id] = @restaurant_id
								or ([name] = @restaurant_name and [address] = @address)
								or [phone] = @restaurant_phone
								or [email] = @restaurant_email)
								and [status] = 'Y'
						   for json path, without_array_wrapper)
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
