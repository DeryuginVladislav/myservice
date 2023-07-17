use myservice
go

create procedure [dbo].[restaurant.edit] (@js nvarchar(max),
										  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@restaurant_id	uniqueidentifier = json_value(@js, '$.id'),
					@restaurant_name nvarchar(25) = json_value(@js, '$.name'),
					@address nvarchar(50) = json_value(@js, '$.address'),
					@restaurant_phone nvarchar(11) = json_value(@js, '$.phone'),
					@restaurant_email nvarchar(64) = json_value(@js, '$.email'),
					@work_start time = json_value(@js, '$.work_start'),
					@work_end time = json_value(@js, '$.work_end'),
					@old_address nvarchar(50),
					@old_restaurant_name nvarchar(25)

			--проверка на наличие id
			if (@restaurant_id is null)
				begin
					set @err = 'err.restaurant_edit.unset_field'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@restaurant_name is null 
				and @address is null
				and @restaurant_phone is null
				and @restaurant_email is null
				and @work_start is null
				and @work_end is null)
				begin
					set @err = 'err.restautant_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность названия
			if (@restaurant_name is not null and @restaurant_email like '%[0-9]%')
				begin
					set @err = 'err.restaurant_edit.invalid_name'
					set @errdesc = 'Название некорректно'

					goto err
				end

			--проверка на корректность адреса
			if (@address is not null and @address not like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_edit.invalid_adress'
					set @errdesc = 'Адрес некорректен'

					goto err
				end


			--проверка на корректность phone	
			if (@restaurant_phone is not null and @restaurant_phone like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_edit.invalid_phone'
					set @errdesc = 'Некорректный телефон'

					goto err
				end

			--проверка на корректность email
			if (@restaurant_email is not null and @restaurant_email not like '%_@_%._%')
				begin
					set @err = 'err.restaurant_edit.invalid_email'
					set @errdesc = 'Некорректный email'

					goto err
				end

			select @old_address = [address],
				   @old_restaurant_name = [name]
			from [dbo].[restaurants]
			where [id] = @restaurant_id and [status] = 'Y'

			--проверка на существовани ресторана с таким id
			if @old_address is null
				begin
					set @err = 'err.restaurant_edit.restaurant_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка на уникальность адреса + имени
			if @address is not null or @restaurant_name is not null
				begin
					if exists (select top 1 1 
							   from [dbo].[restaurants] 
							   where [address] = isnull(@address, @old_address) 
									and [name] = isnull(@restaurant_name, @old_restaurant_name) 
									and [status] = 'Y')
						begin
							set @err = 'err.restaurant_edit.not_unique_address_and_name'
							set @errdesc = 'Такой ресторан уже существует'

							goto err
						end
				end

			--проверка на уникальность телефона
			if @restaurant_phone is not null
				begin
					if exists (select top 1 1 from [dbo].[restaurants] where [phone] = @restaurant_phone and [status] = 'Y')
						begin
							set @err = 'err.restaurant_edit.not_unique_phone'
							set @errdesc = 'Ресторан c таким телефоном уже существует'

							goto err
						end
				end

			--проверка на уникальность email
			if @restaurant_email is not null
				begin
					if exists (select top 1 1 from [dbo].[restaurants] where [email] = @restaurant_email and [status] = 'Y')
						begin
							set @err = 'err.restaurant_edit.not_unique_email'
							set @errdesc = 'Ресторан c таким email уже существует'

							goto err
						end
				end

			--изменяем ресторан
			update [dbo].[restaurants] 
			set [name] = isnull(@restaurant_name, [name]),
				[address] = isnull(@address, [address]),
				[phone] = isnull(@restaurant_phone, [phone]),
				[email] = isnull(@restaurant_email, [email]),
				[work_start] = isnull(@work_start, [work_start]),
				[work_end] = isnull(@work_end, [work_end])
			where [id] = @restaurant_id
		
			--выводим
			set @rp = (select * from [dbo].[restaurants]
					   where [id] = @restaurant_id
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