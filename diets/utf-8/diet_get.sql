USE [myservice]
GO

/****** Object:  StoredProcedure [dbo].[diet.get]    Script Date: 04.07.2023 17:16:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[diet.get] (@js nvarchar(max),
								   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@diet_id	  uniqueidentifier = json_value(@js, '$.id'),
					@diet_name	  nvarchar(25) = json_value(@js, '$.name')

				--выводим
				set @rp = (select *
						   from [dbo].[diets]
						   where ([id] = @diet_id or [name] = @diet_name) and [status] = 'Y'
						   for json path, without_array_wrapper)
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

