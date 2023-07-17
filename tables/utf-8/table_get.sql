use myservice
go

create procedure [dbo].[table.get] (@js nvarchar(max),
									@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@table_id	  uniqueidentifier = json_value(@js, '$.id'),
					@restaurant_id_t uniqueidentifier = json_value(@js, '$.restaurant_id'),
					@number int = json_value(@js, '$.number')

				--выводим
				set @rp = (select *
						   from [dbo].[tables]
						   where ([id] = @table_id 
								or ([restaurant_id] = @restaurant_id_t and [number] = @number)
								or ([restaurant_id] = @restaurant_id_t)) 
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
