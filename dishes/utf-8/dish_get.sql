use myservice
go

create procedure [dbo].[dish.get] (@js nvarchar(max),
								   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@dish_id	  uniqueidentifier = json_value(@js, '$.id'),
					@dish_name nvarchar(20) = json_value(@js, '$.name'),
					@restaurant_id_d uniqueidentifier = json_value(@js, '$.restaurant_id')

				--выводим
				set @rp = (select *
						   from [dbo].[dishes] as [d]
						   join [ingredients] as [i] on [d].[id] = [i].[dish_id]
						   where ([d].[id] = @dish_id or ([d].[name] = @dish_name and [d].[restaurant_id] = @restaurant_id_d))
							 and [d].[status] = 'Y'
							 and [i].[status] = 'Y'
						   for json auto, without_array_wrapper)
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
