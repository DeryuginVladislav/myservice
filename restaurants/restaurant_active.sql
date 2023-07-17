use myservice
go

create procedure [dbo].[restaurant_active] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@status char(1),
					@name nvarchar(25),
					@address nvarchar(50),
					@phone nvarchar(11),
					@email nvarchar(64)

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.restaurant_active.unset_field'
					set @errdesc = 'Ќе указан id'

					goto err
				end

			select @status = [status],
				   @name = [name],
				   @address = [address],
				   @phone = [phone],
				   @email = [email]
			from [restaurants]
			where [id] = @id

			--проверка на существование ресторана с таким id
			if (@status is null)
				begin
					set @err = 'err.restaurant_active.restaurant_not_found'
					set @errdesc = '–есторан с таким id не найден'

					goto err
				end

			--проверка на активный статус
			if (@status = 'Y')
				begin
					set @err = 'err.restaurant_active.restaurant_already_active'
					set @errdesc = '–есторан уже активен'

					goto err
				end

			--проверка на существующий ресторан
			if (exists (select 1 
						from [dbo].[restaurants] 
						where [name] = @name
							and [address] = @address
							and [status] = 'Y'))
				begin
					set @err = 'err.restaurant_active.not_unique_name_and_address'
					set @errdesc = '“акой ресторан уже существует'

					goto err
				end

			--проверка на зан€тый телефон
			if (exists (select 1 
						from [dbo].[restaurants] 
						where [phone] = @phone
							and [status] = 'Y'))
				begin
					set @err = 'err.restaurant_active.not_unique_phone'
					set @errdesc = '“елефон уже используетс€'

					goto err
				end

			--проверка на зан€тый email
			if (exists (select 1 
							from [dbo].[restaurants] 
							where ([email] = @email)
								and [status] = 'Y'))
				begin
					set @err = 'err.restaurant_active.not_unique_email'
					set @errdesc = 'Email уже используетс€'

					goto err
				end

			--мен€ем статус
			update [dbo].[restaurants] 
			set [status] = 'Y'
			where [id] = @id

			--выводим
			set @rp = (select @id as [id],
							  'Y' as [status]
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