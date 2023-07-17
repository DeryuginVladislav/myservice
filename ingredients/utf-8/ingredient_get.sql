use myservice
go

create procedure [dbo].[ingredient.get] (@js nvarchar(max),
										 @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@ingredient_id	  uniqueidentifier = json_value(@js, '$.id'),
					@dish_id_i uniqueidentifier = json_value(@js, '$.dish_id'),
					@ingredient_name nvarchar(30) = json_value(@js, '$.name')


				--выводим
				set @rp = (select *
						   from [dbo].[ingredients]
						   where ([id] = @ingredient_id 
							   or ([name] = @ingredient_name and [dish_id] = @dish_id_i)
							   or [dish_id] = @dish_id_i) 
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