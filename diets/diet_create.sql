USE [myservice]
GO

/****** Object:  StoredProcedure [dbo].[diet_create]    Script Date: 04.07.2023 17:15:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[diet_create] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	  uniqueidentifier,
					@name	  nvarchar(25) = json_value(@js, '$.name'),
					@description  nvarchar(150) = json_value(@js, '$.description')

			--проверка обязательных параметров на null
			if (@name is null)
				begin
					set @err = 'err.diet_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность имени
			if (@name like '%[0 - 9]%')
				begin
					set @err = 'err.diet_create.invalid_name'
					set @errdesc = 'Имя содержит цифры'

					goto err
				end

			--проверка на корректность описания
			if (@description is not null)
				begin
					set @err = 'err.diet_create.invalid_description'
					set @errdesc = 'Слишком большое описание'

					goto err
				end

			--проверка на уже существующее название диеты
			if exists (select 1 
					   from [dbo].[diets] 
					   where [name] = @name and [status] = 'Y')
				begin
					set @err = 'err.diet_create.not_unique_name'
					set @errdesc = 'Диета c таким названием уже существует'

					goto err
				end

			--добавляем значения в таблицу
			set @id = newid()
			insert into [dbo].[diets] ([id], [name], [description])
				values (@id,
						@name,
						@description)
		
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
