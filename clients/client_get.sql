use myservice
go

create procedure [dbo].[client.get] (@js nvarchar(max),
									 @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_id	  uniqueidentifier = json_value(@js, '$.id'),
					@client_phone nvarchar(11) = json_value(@js, '$.phone'),
					@client_email nvarchar(64) = json_value(@js, '$.email')

				--выводим
				set @rp = (select *
						   from [dbo].[clients]
						   where ([id] = @client_id 
								or [phone] = @client_phone
								or ([email] is not null and [email] = @client_email)) 
								and [status] = 'Y'
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
