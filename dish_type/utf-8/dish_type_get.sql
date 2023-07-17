use myservice
go

create procedure [dbo].[dish_type.get] (@js nvarchar(max),
										@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@dish_type_id	  uniqueidentifier = json_value(@js, '$.id'),
					@diet_id_dt uniqueidentifier = json_value(@js, '$.diet_id'),
					@dish_id_dt uniqueidentifier = json_value(@js, '$.dish_id')


				--выводим
				set @rp = (select *
						   from [dbo].[dish_type]
						   where ([id] = @dish_type_id
							  or ([dish_id] = @dish_id_dt and [diet_id] = @diet_id_dt)
							  or [diet_id] = @diet_id_dt)
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