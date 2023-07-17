use myservice
go

create procedure [dbo].[restaurant.active] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@restaurant_id	uniqueidentifier = json_value(@js, '$.id'),
					@restaurant_status char(1),
					@restaurant_name nvarchar(25),
					@address nvarchar(50),
					@restaurant_phone nvarchar(11),
					@restaurant_email nvarchar(64)

			--проверка на наличие id
			if (@restaurant_id is null)
				begin
					set @err = 'err.restaurant_active.unset_field'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			select @restaurant_status = [status],
				   @restaurant_name = [name],
				   @address = [address],
				   @restaurant_phone = [phone],
				   @restaurant_email = [email]
			from [restaurants]
			where [id] = @restaurant_id

			--проверка на существование ресторана с таким id
			if (@restaurant_status is null)
				begin
					set @err = 'err.restaurant_active.restaurant_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка на активный статус
			if (@restaurant_status = 'Y')
				begin
					set @err = 'err.restaurant_active.restaurant_already_active'
					set @errdesc = 'Ресторан уже активен'

					goto err
				end

			--проверка на существующий ресторан
			if exists (select top 1 1 from [dbo].[restaurants] where [name] = @restaurant_name and [address] = @address and [status] = 'Y')
				begin
					set @err = 'err.restaurant_active.not_unique_name_and_address'
					set @errdesc = 'Такой ресторан уже существует'

					goto err
				end

			--проверка на занятый телефон
			if exists (select top 1 1 from [dbo].[restaurants] where [phone] = @restaurant_phone and [status] = 'Y')
				begin
					set @err = 'err.restaurant_active.not_unique_phone'
					set @errdesc = 'Телефон уже используется'

					goto err
				end

			--проверка на занятый email
			if exists (select top 1 1 from [dbo].[restaurants] where [email] = @restaurant_email and [status] = 'Y')
				begin
					set @err = 'err.restaurant_active.not_unique_email'
					set @errdesc = 'Email уже используется'

					goto err
				end

			--меняем статус
			update [dbo].[restaurants] 
			set [status] = 'Y'
			where [id] = @restaurant_id

			--выводим
			set @rp = (select @restaurant_id as [id],
							  'Y' as [status]
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