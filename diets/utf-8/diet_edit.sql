USE [myservice]
GO

/****** Object:  StoredProcedure [dbo].[diet_edit]    Script Date: 04.07.2023 17:15:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create procedure [dbo].[diet.edit] (@js nvarchar(max),
									@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@diet_id	  uniqueidentifier = json_value(@js, '$.id'),
					@diet_name	  nvarchar(25) = json_value(@js, '$.name'),
					@diet_description  nvarchar(150) = json_value(@js, '$.description')

			--проверка на наличие id
			if (@diet_id is null)
				begin
					set @err = 'err.diet_edit.unset_field'
					set @errdesc = 'Диета не найдена'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@diet_name is null and @diet_description is null)
				begin
					set @err = 'err.diet_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность названия
			if (@diet_name is not null and @diet_name like '%[0 - 9]%')
				begin
					set @err = 'err.diet_edit.invalid_name'
					set @errdesc = 'Название содержит цифры'

					goto err
				end

			--проверка на существование диеты
			if not exists (select top 1 1 from [dbo].[diets] where [id] = @diet_id and [status] = 'Y')
				begin
					set @err = 'err.diet_edit.object_not_found'
					set @errdesc = 'Диета не найдена'

					goto err
				end

			--проверка на уже существующее название диеты
			if exists (select top 1 1 from [dbo].[diets] where [name] = @diet_name and [status] = 'Y')
				begin
					set @err = 'err.diet_edit.not_unique_name'
					set @errdesc = 'Диета c таким названием уже существует'

					goto err
				end

			--изменяем диету
			update [dbo].[diets] 
			set [name] = isnull(@diet_name, [name]),
				[description] = isnull(@diet_description, [description])
			where [id] = @diet_id
		
			--выводим
			set @rp = (select * from [dbo].[diets]
					   where [id] = @diet_id
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

