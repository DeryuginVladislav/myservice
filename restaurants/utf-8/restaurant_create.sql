use myservice
go 

create procedure [dbo].[restaurant.create] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@restaurant_id	uniqueidentifier,
					@restaurant_name nvarchar(25) = json_value(@js, '$.name'),
					@address nvarchar(50) = json_value(@js, '$.address'),
					@restaurant_phone nvarchar(11) = json_value(@js, '$.phone'),
					@restaurant_email nvarchar(64) = json_value(@js, '$.email'),
					@work_start time = json_value(@js, '$.work_start'),
					@work_end time = json_value(@js, '$.work_end')

			--проверка обязательных параметров на null
			if (@restaurant_name is null
				or @address is null
				or @restaurant_phone is null
				or @restaurant_email is null
				or @work_start is null
				or @work_end is null)
				begin
					set @err = 'err.restaurant_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность названия
			if (@restaurant_name like '%[0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_name'
					set @errdesc = 'Название некорректно'

					goto err
				end

			--проверка на корректность адреса
			if (@address not like '%[^0-9]%' or len(@address) < 2)
				begin
					set @err = 'err.restaurant_create.invalid_adress'
					set @errdesc = 'Адрес некорректен'

					goto err
				end


			--проверка на корректность phone	
			if (@restaurant_phone like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_phone'
					set @errdesc = 'Некорректный телефон'

					goto err
				end

			--проверка на корректность email
			if (@restaurant_email not like '%_@_%._%')
				begin
					set @err = 'err.restaurant_create.invalid_email'
					set @errdesc = 'Некорректный email'

					goto err
				end

			--проверка на уникальность адреса + имени
			if exists (select top 1 1 from [dbo].[restaurants] where [address] = @address and [name] = @restaurant_name and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_address_and_name'
					set @errdesc = 'Такой ресторан уже существует'

					goto err
				end

			--проверка на уникальность телефона
			if exists (select top 1 1 from [dbo].[restaurants] where [phone] = @restaurant_phone and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_phone'
					set @errdesc = 'Ресторан c таким телефоном уже существует'

					goto err
				end

			--проверка на уникальность email
			if exists (select top 1 1 from [dbo].[restaurants] where [email] = @restaurant_email and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_email'
					set @errdesc = 'Ресторан c таким email уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @restaurant_id = newid()
			insert into [dbo].[restaurants] ([id], [name], [address], [phone], [email], [work_start], [work_end])
			values (@restaurant_id,
					@restaurant_name,
					@address,
					@restaurant_phone,
					@restaurant_email,
					@work_start,
					@work_end)
		
			--выводим
			set @rp = (select @restaurant_id as [id],
							  @restaurant_name as [name],
							  @address as [address],
							  @restaurant_phone as [phone],
							  @restaurant_email as [email],
							  @work_start as [work_start],
							  @work_end as [work_end]
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