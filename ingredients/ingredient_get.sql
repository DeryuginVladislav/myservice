use myservice
go

create procedure [dbo].[ingredient_get] (@js nvarchar(max),
										 @rp nvarchar(max) output)
	as
	begin
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	  uniqueidentifier = json_value(@js, '$.id'),
					@dish_id uniqueidentifier = json_value(@js, '$.dish_id')

				--выводим
				set @rp = (select [id],
								  [dish_id],
								  [name]
						   from [dbo].[ingredients]
						   where ([id] = @id or [dish_id] = @dish_id)
							 and ((@id is null or [id] = @id) and (@dish_id is null or [dish_id] = @dish_id)) 
							 and [status] = 'Y'
						   for json path, without_array_wrapper)
				return
					  
		end try

		begin catch
			set @err = error_number()
			set @errdesc = error_message()

			goto err
		end catch

		err: 
			set @rp = (select 'err' as [status],
							  lower(@err) as [err],
							  @errdesc as [errdesc] 
					   for json path, without_array_wrapper)
			set nocount off
			return

		ok: 
			set @rp = (select 'ok' as [status],
							  json_query(@rp) as [response] 
					   for json path, without_array_wrapper)
			set nocount off
			return

	end
