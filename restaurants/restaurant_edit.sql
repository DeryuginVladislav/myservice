use myservice
go

create procedure [dbo].[restaurant_edit] (@js nvarchar(max),
										  @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@name nvarchar(25) = json_value(@js, '$.name'),
					@address nvarchar(50) = json_value(@js, '$.address'),
					@phone nvarchar(11) = json_value(@js, '$.phone'),
					@email nvarchar(64) = json_value(@js, '$.email'),
					@work_start time = json_value(@js, '$.work_start'),
					@work_end time = json_value(@js, '$.work_end')

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.restaurant_edit.unset_field'
					set @errdesc = 'Не указан id'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@name is null 
				and @address is null
				and @phone is null
				and @email is null
				and @work_start is null
				and @work_end is null)
				begin
					set @err = 'err.restautant_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность имени
			if (@name like '%[0-9]%')
				begin
					set @err = 'err.restaurant_edit.invalid_name'
					set @errdesc = 'Имя некорректно'

					goto err
				end

			--проверка на корректность адреса
			if (@address not like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_edit.invalid_adress'
					set @errdesc = 'Адрес некорректен'

					goto err
				end


			--проверка на корректность phone	
			if (@phone like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_edit.invalid_phone'
					set @errdesc = 'Некорректный телефон'

					goto err
				end

			--проверка на корректность email
			if (@email not like '%_@_%._%')
				begin
					set @err = 'err.restaurant_edit.invalid_email'
					set @errdesc = 'Некорректный email'

					goto err
				end

			--проверка на корректность часов работы
			if (try_convert(time, @work_start) is null or try_convert(time, @work_end) is null)
				begin
					set @err = 'err.restaurant_edit.invalid_time'
					set @errdesc = 'Некорректное время'

					goto err
				end

			--проверка на существовани ресторана с таким id
			if not exists (select 1 
						   from [dbo].[restaurants] 
						   where [id] = @id and [status] = 'Y')
				begin
					set @err = 'err.restaurant_edit.object_not_found'
					set @errdesc = 'Ресторан с таким id не найден'

					goto err
				end

			--проверка на уникальность адреса + имени
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [address] = @address
							and [name] = @name
							and [status] = 'Y')
				begin
					set @err = 'err.restaurant_edit.not_unique_address_and_name'
					set @errdesc = 'Такой ресторан уже существует'

					goto err
				end

			--проверка на уникальность телефона
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [phone] = @phone
							and [status] = 'Y')
				begin
					set @err = 'err.restaurant_edit.not_unique_phone'
					set @errdesc = 'Ресторан c таким телефоном уже существует'

					goto err
				end

			--проверка на уникальность email
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [email] = @email
							and [id] <> @id
							and [status] = 'Y')
				begin
					set @err = 'err.restaurant_edit.not_unique_email'
					set @errdesc = 'Ресторан c таким email уже существует'

					goto err
				end

			--изменяем ресторан
			update [dbo].[restaurants] 
			set [name] = isnull(@name, [name]),
				[address] = isnull(@address, [address]),
				[phone] = isnull(@phone, [phone]),
				[email] = isnull(@email, [email]),
				[work_start] = isnull(@work_start, [work_start]),
				[work_end] = isnull(@work_end, [work_end])
			where [id] = @id
		
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