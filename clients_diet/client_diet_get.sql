use myservice
go

create procedure [dbo].[client_diet_get] (@js nvarchar(max),
										  @rp nvarchar(max) output)
	as
	begin
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	  uniqueidentifier = json_value(@js, '$.id'),
					@client_id uniqueidentifier = json_value(@js, '$.client_id')

				--�������
				set @rp = (select [id],
								  [client_id],
								  [diet_id]
						   from [dbo].[clients_diet]
						   where ([id] = @id or [client_id] = @client_id)
							 and ((@id is null or [id] = @id) and (@client_id is null or [client_id] = @client_id)) 
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