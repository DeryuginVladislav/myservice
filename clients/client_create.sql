use myservice
go 

create procedure [dbo].[client.create] (@js nvarchar(max),
										@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_id	uniqueidentifier,
					@firstname	  nvarchar(20) = json_value(@js, '$.firstname'),
					@lastname	  nvarchar(20) = json_value(@js, '$.lastname'),
					@client_email  nvarchar(64) = json_value(@js, '$.email'),
					@client_phone nvarchar(11) = json_value(@js, '$.phone'),
					@dob date = json_value(@js, '$.dob')

			--проверка обязательных параметров на null
			if (@firstname is null
				or @lastname is null
				or @client_phone is null)
				begin
					set @err = 'err.client_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность email
			if (@client_email is not null and @client_email not like '%_@_%._%')
				begin
					set @err = 'err.client_create.invalid_email'
					set @errdesc = 'Некорректный email'

					goto err
				end

			--проверка на корректность имени
			if (@firstname like '%[0-9]%')
				begin
					set @err = 'err.client_create.invalid_firstname'
					set @errdesc = 'Имя некорректно'

					goto err
				end

			--проверка на корректность фамилии
			if (@lastname like '%[0-9]%')
				begin
					set @err = 'err.client_create.invalid_lastname'
					set @errdesc = 'Фамилия некорректна'

					goto err
				end

			--проверка на корректность dob
			if (@dob is not null and @dob > getdate())
				begin
					set @err = 'err.client_create.invalid_dob'
					set @errdesc = 'Некорректная дата'

					goto err
				end

			--проверка на корректность phone	
			if @client_phone like '%[^0-9]%' and len(@client_phone) < 11
				begin
					set @err = 'err.client_create.invalid_phone'
					set @errdesc = 'Некорректный телефон'

					goto err
				end

			--проверка на уникальность телефона
			if exists (select top 1 1 from [dbo].[clients] where [phone] = @client_phone and [status] = 'Y')
				begin
					set @err = 'err.client_create.not_unique_phone'
					set @errdesc = 'Клиент c таким телефоном уже существует'

					goto err
				end

			--проверка на уникальность email
			if exists (select top 1 1 from [dbo].[clients] where [email] = @client_email and [status] = 'Y')
				begin
					set @err = 'err.client_create.not_unique_email'
					set @errdesc = 'Клиент c таким email уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @client_id = newid()
			insert into [dbo].[clients] ([id], [firstname], [lastname], [email], [phone], [dob])
				values (@client_id,
						@firstname,
						@lastname,
						@client_email,
						@client_phone,
						@dob)
		
			--выводим
			set @rp = (select @client_id as [id],
							  @firstname as [firstname],
							  @lastname as [lastname],
							  @client_email as [email],
							  @client_phone as [phone],
							  @dob as [dob]
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