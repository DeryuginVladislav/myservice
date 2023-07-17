use myservice
go

create procedure [dbo].[client_diet.get] (@js nvarchar(max),
										  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_diet_id	  uniqueidentifier = json_value(@js, '$.id'),
					@client_id_cd uniqueidentifier = json_value(@js, '$.client_id'),
					@diet_id_cd uniqueidentifier = json_value(@js, '$.diet_id')

				--выводим
				set @rp = (select *
						   from [dbo].[clients_diet]
						   where ([id] = @client_diet_id
							  or ([diet_id] = @diet_id_cd and [client_id] = @client_id_cd)
							  or [client_id] = @client_id_cd) 
							  and [status] = 'Y'
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