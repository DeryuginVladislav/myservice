use myservice
go

create procedure [dbo].[dish_get] (@js nvarchar(max),
										 @rp nvarchar(max) output)
	as
	begin
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	  uniqueidentifier = json_value(@js, '$.id')

				--выводим
				set @rp = (select [d].[id],
								  [d].[name],
								  [d].[restaurant_id],
								  [d].[description],
								  [d].[price],
								  [d].[calories],
								  [i].[id],
								  [i].[name]
						   from [dbo].[dishes] as [d]
						   join [ingredients] as [i] on [d].[id] = [i].[dish_id]
						   where [d].[id] = @id
							 and [d].[status] = 'Y'
							 and [i].[status] = 'Y'
						   for json auto, without_array_wrapper)
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
