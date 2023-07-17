USE [myservice]
GO

/****** Object:  StoredProcedure [dbo].[diet_get]    Script Date: 04.07.2023 17:16:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[diet_get] (@js nvarchar(max),
								   @rp nvarchar(max) output)
	as
	begin
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	  uniqueidentifier = json_value(@js, '$.id'),
					@name	  nvarchar(25) = json_value(@js, '$.name')

				--выводим
				set @rp = (select [id],
								  [name],
								  [description]
						   from [dbo].[diets]
						   where ([id] = @id or [name] = @name)
							 and ((@id is null or [id] = @id) and (@name is null or [name] = @name))
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
go

