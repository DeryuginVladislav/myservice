use myservice
go 

create procedure [dbo].[restaurant_create] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier,
					@name nvarchar(25) = json_value(@js, '$.name'),
					@address nvarchar(50) = json_value(@js, '$.address'),
					@phone nvarchar(11) = json_value(@js, '$.phone'),
					@email nvarchar(64) = json_value(@js, '$.email'),
					@work_start time = json_value(@js, '$.work_start'),
					@work_end time = json_value(@js, '$.work_end')

			--проверка обязательных параметров на null
			if (@name is null
				or @address is null
				or @phone is null
				or @email is null
				or @work_start is null
				or @work_end is null)
				begin
					set @err = 'err.restaurant_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность имени
			if (@name like '%[0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_name'
					set @errdesc = 'Имя некорректно'

					goto err
				end

			--проверка на корректность адреса
			if (@address not like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_adress'
					set @errdesc = 'Адрес некорректен'

					goto err
				end


			--проверка на корректность phone	
			if (@phone like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_phone'
					set @errdesc = 'Некорректный телефон'

					goto err
				end

			--проверка на корректность email
			if (@email not like '%_@_%._%')
				begin
					set @err = 'err.restaurant_create.invalid_email'
					set @errdesc = 'Некорректный email'

					goto err
				end

			--проверка на корректность часов работы
			if (try_convert(time, @work_start) is null or try_convert(time, @work_end) is null)
				begin
					set @err = 'err.restaurant_create.invalid_time'
					set @errdesc = 'Некорректное время'

					goto err
				end

			--проверка на уникальность адреса + имени
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [address] = @address
							and [name] = @name
							and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_address_and_name'
					set @errdesc = 'Такой ресторан уже существует'

					goto err
				end

			--проверка на уникальность телефона
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [phone] = @phone and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_phone'
					set @errdesc = 'Ресторан c таким телефоном уже существует'

					goto err
				end

			--проверка на уникальность email
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [email] = @email and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_email'
					set @errdesc = 'Ресторан c таким email уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @id = newid()
			insert into [dbo].[restaurants] ([id], [name], [address], [phone], [email], [work_start], [work_end])
				values (@id,
						@name,
						@address,
						@phone,
						@email,
						@work_start,
						@work_end)
		
			--выводим
			set @rp = (select @id as [id],
							  @name as [name],
							  @address as [address],
							  @phone as [phone],
							  @email as [email],
							  @work_start as [work_start],
							  @work_end as [work_end]
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