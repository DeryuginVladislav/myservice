USE [myservice]
GO

/****** Object:  StoredProcedure [dbo].[diet_edit]    Script Date: 04.07.2023 17:15:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create procedure [dbo].[diet_edit] (@js nvarchar(max),
									@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	  uniqueidentifier = json_value(@js, '$.id'),
					@name	  nvarchar(25) = json_value(@js, '$.name'),
					@description  nvarchar(150) = json_value(@js, '$.description')

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.diet_edit.unset_field'
					set @errdesc = 'Не указан id'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@name is null and @description is null)
				begin
					set @err = 'err.diet_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность имени
			if (@name like '%[0 - 9]%')
				begin
					set @err = 'err.diet_edit.invalid_name'
					set @errdesc = 'Имя содержит цифры'

					goto err
				end

			--проверка на существование диеты
			if not exists (select 1 
						   from [dbo].[diets] 
						   where [id] = @id and [status] = 'Y')
				begin
					set @err = 'err.diet_edit.object_not_found'
					set @errdesc = 'Диета не найдена'

					goto err
				end

			--проверка на уже существующее название диеты
			if (@name is not null and exists (select 1 
											  from [dbo].[diets] 
											  where [name] = @name
												and [id] <> @id
												and [status] = 'Y'))
				begin
					set @err = 'err.diet_edit.not_unique_name'
					set @errdesc = 'Диета c таким названием уже существует'

					goto err
				end


			--изменяем диету
			update [dbo].[diets] 
			set [name] = isnull(@name, [name]),
				[description] = isnull(@description, [description])
			where [id] = @id
		
			--выводим
			set @rp = (select @id as [id],
							  @name as [name],
							  @description as [description]  		                 
					   for json path, without_array_wrapper)

			goto ok

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

