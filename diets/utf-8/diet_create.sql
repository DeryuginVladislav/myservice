USE [myservice]
GO

/****** Object:  StoredProcedure [dbo].[diet.create]    Script Date: 04.07.2023 17:15:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[diet.create] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@diet_id	  uniqueidentifier,
					@diet_name	  nvarchar(25) = json_value(@js, '$.name'),
					@diet_description  nvarchar(150) = json_value(@js, '$.description')

			--проверка обязательных параметров на null
			if (@diet_name is null)
				begin
					set @err = 'err.diet_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность названия
			if (@diet_name like '%[0 - 9]%')
				begin
					set @err = 'err.diet_create.invalid_name'
					set @errdesc = 'Название диеты содержит цифры'

					goto err
				end

			--проверка на уже существующее название диеты
			if exists (select top 1 1 from [dbo].[diets] where [name] = @diet_name and [status] = 'Y')
				begin
					set @err = 'err.diet_create.not_unique_name'
					set @errdesc = 'Диета c таким названием уже существует'

					goto err
				end

			--добавляем значения в таблицу
			set @diet_id = newid()
			insert into [dbo].[diets] ([id], [name], [description])
			values (@diet_id,
					@diet_name,
					@diet_description)
		
			--выводим
			set @rp = (select @diet_id as [id],
							  @diet_name as [name],
							  @diet_description as [description]   		                 
					   for json path, without_array_wrapper)

			goto ok

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
