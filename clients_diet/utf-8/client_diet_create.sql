use myservice
go 

create procedure [dbo].[client_diet.create] (@js nvarchar(max),
											 @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dayformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_diet_id	uniqueidentifier,
					@client_id_cd uniqueidentifier = json_value(@js, '$.client_id'),
					@diet_id_cd uniqueidentifier = json_value(@js, '$.diet_id')

			--проверка обязательных параметров на null
			if (@client_id_cd is null
				or @diet_id_cd is null)
				begin
					set @err = 'err.client_diet_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на существование клиента с таким id
			if not exists (select top 1 1 from [dbo].[clients] where [id] = @client_id_cd and [status] = 'Y')
				begin
					set @err = 'err.client_diet_create.client_not_found'
					set @errdesc = 'Клиент не найден'

					goto err
				end

			--проверка на существование диеты
			if not exists (select top 1 1 from [dbo].[diets] where [id] = @diet_id_cd and [status] = 'Y')
				begin
					set @err = 'err.client_diet_create.diet_not_found'
					set @errdesc = 'Диета не найдена'

					goto err
				end


			--проверка на уникальность связи
			if exists (select top 1 1 from [dbo].[clients_diet] where [client_id] = @client_id_cd and [diet_id] = @diet_id_cd and [status] = 'Y')
				begin
					set @err = 'err.client_diet_create.relation_already_exist'
					set @errdesc = 'Диета у клиента уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @client_diet_id = newid()
			insert into [dbo].[clients_diet] ([id], [client_id], [diet_id])
				values (@client_diet_id,
						@client_id_cd,
						@diet_id_cd)
		
			--выводим
			set @rp = (select @client_diet_id as [id],
							  @client_id_cd as [client_id],
							  @diet_id_cd as [diet_id]
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