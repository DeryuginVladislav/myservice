use [myservice]
go

create procedure [dbo].[ms_api]
	@action varchar(50),
	@js varchar(max),
	@rp varchar(max) out
	
	as
	begin

		set nocount on

		begin try

			declare @err nvarchar(100),
					@errdesc nvarchar(max),
					@sba nvarchar(50) = substring(@action,1,charindex('.',@action)-1),

					@rp_ nvarchar(max),
					@jsT nvarchar(max)

			set dateformat dmy

			if @sba in ('client')
				begin

					declare @client_id	uniqueidentifier = json_value(@js, '$.id')
						  , @firstname	  nvarchar(20) = json_value(@js, '$.firstname')
						  , @lastname	  nvarchar(20) = json_value(@js, '$.lastname')
						  , @client_email  nvarchar(64) = json_value(@js, '$.email')
						  , @client_phone nvarchar(11) = json_value(@js, '$.phone')
						  , @dob date = json_value(@js, '$.dob')

					if @action in ('client.get')
						begin
							
							set @rp = (select *
									   from [dbo].[clients]
									   where ([id] = @client_id 
											or [phone] = @client_phone
											or ([email] is not null and [email] = @client_email)) 
											and [status] = 'Y'
									   for json path, without_array_wrapper)
							goto ok

						end


					if @action in ('client.create')
						begin
							
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
							set @rp_ = null
							set @jsT = (select @client_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.client_create.not_unique_phone'
									set @errdesc = 'Клиент c таким телефоном уже существует'

									goto err
								end

							--проверка на уникальность email
							set @rp_ = null
							set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
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

						end


					if @action in ('client.edit')
						begin

							--проверка на наличие id
							if (@client_id is null)
								begin
									set @err = 'err.client_edit.unset_field'
									set @errdesc = 'Клиент не найден'

									goto err
								end

							--проверка на наличие редактируемых параметров
							if (@firstname is null 
								and @lastname is null
								and @client_email is null
								and @client_phone is null
								and @dob is null)
								begin
									set @err = 'err.client_edit.hasnt_data'
									set @errdesc = 'Отсутствуют данные редактирования'

									goto err
								end

							--проверка на корректность email
							if (@client_email is not null and @client_email not like '%_@_%._%')
								begin
									set @err = 'err.client_edit.invalid_email'
									set @errdesc = 'Некорректный email'

									goto err
								end

							--проверка на корректность имени
							if (@firstname is not null and @firstname like '%[0-9]%')
								begin
									set @err = 'err.client_edit.invalid_firstname'
									set @errdesc = 'Имя некорректно'

									goto err
								end

							--проверка на корректность фамилии
							if (@lastname is not null and @lastname like '%[0-9]%')
								begin
									set @err = 'err.client_edit.invalid_lastname'
									set @errdesc = 'Фамилия некорректна'

									goto err
								end

							--проверка на корректность dob
							if (@dob is not null and @dob > getdate())
								begin
									set @err = 'err.client_edit.invalid_dob'
									set @errdesc = 'Некорректная дата'

									goto err
								end

							--проверка на корректность phone	
							if (@client_phone is not null and @client_phone like '%[^0-9]%')
								begin
									set @err = 'err.client_edit.invalid_phone'
									set @errdesc = 'Некорректный телефон'

									goto err
								end

							--проверка на существование клиента с таким id
							set @rp_ = null
							set @jsT = (select @client_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.client_edit.object_not_found'
									set @errdesc = 'Клиент не найден'

									goto err
								end

							--проверка на занятый телефон
							if @client_phone is not null
								begin
									set @rp_ = null
									set @jsT = (select @client_phone as [phone] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
										begin
											set @err = 'err.client_edit.not_unique_phone'
											set @errdesc = 'Телефон уже используется'

											goto err
										end
								end

							--проверка на занятый email
							if @client_email is not null
								begin
									set @rp_ = null
									set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null										
										begin
											set @err = 'err.client_edit.not_unique_email'
											set @errdesc = 'Email уже используется'

											goto err
										end
								end

							--изменяем клиента
							update [dbo].[clients] 
							set [firstname] = isnull(@firstname, [firstname]),
								[lastname] = isnull(@lastname, [lastname]),
								[email] = isnull(@client_email, [email]),
								[phone] = isnull(@client_phone, [phone]),
								[dob] = isnull(@dob, [dob])
							where [id] = @client_id
		
							--выводим
							set @rp = (select * from [dbo].[clients]
									   where [id] = @client_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('client.deactive')
						begin

							declare @client_status char(1)

							--проверка на наличие id
							if (@client_id is null)
								begin
									set @err = 'err.client_deactive.unset_field'
									set @errdesc = 'Клиент не найден'

									goto err
								end


							select @client_status = [status]
							from [dbo].[clients] 
							where [id] = @client_id

			
							--проверка на существование клиента с таким id
							if (@client_status is null)
								begin
									set @err = 'err.client_deactive.object_not_found'
									set @errdesc = 'Клиент не найден'

									goto err
								end

							--проверка статуса клиента
							if (@client_status = 'N')
								begin
									set @err = 'err.client_deactive.client_already_deactive'
									set @errdesc = 'Клиент уже деактивирован'

									goto err
								end

							--проверка активных броней
							set @rp_ = null
							set @jsT = (select @client_id as [id] for json path, without_array_wrapper)
							exec [dbo].ms_api 'table_booking.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.client_deactive.client_has_bookings'
									set @errdesc = 'У клиента есть активные брони'

									goto err
								end


							begin transaction

								--изменяем клиента
								update [dbo].[clients] 
								set [status] = 'N'
								where [id] = @client_id and [status] = 'Y'

								--деактивируем его диеты
								update [dbo].[clients_diet]
								set [status] = 'N'
								where [client_id] = @client_id and [status] = 'Y'

							commit transaction


							--выводим
							set @rp = (select @client_id as [id],
											  'N' as [status]
									   for json path, without_array_wrapper)
			
							goto ok

						end


					if @action in ('client.active')
						begin
							
							--проверка на  id
							if (@client_id is null)
								begin
									set @err = 'err.client_active.unset_field'
									set @errdesc = 'Клиент не найден'

									goto err
								end

							select @client_status = [status],
								   @client_phone = [phone],
								   @client_email = [email]
							from [clients]
							where [id] = @client_id

							--проверка существует ли клиент с таким id
							if (@client_status is null)
								begin
									set @err = 'err.client_active.client_not_found'
									set @errdesc = 'Клиент не обнаружен'

									goto err
								end

							--проверка на то что клиент уже активен
							if (@client_status = 'Y')
								begin
									set @err = 'err.client_active.client_already_active'
									set @errdesc = 'Клиент уже активен'

									goto err
								end

							--проверка на уникальность телефона
							set @rp_ = null
							set @jsT = (select @client_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.client_active.not_unique_phone'
									set @errdesc = 'Указанный телефон уже используется'

									goto err
								end

							--проверка на уникальность email
							set @rp_ = null
							set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null								
								begin
									set @err = 'err.client_active.not_unique_email'
									set @errdesc = 'Email уже используется'

									goto err
								end

							--изменяем статус клиента
							update [dbo].[clients] 
							set [status] = 'Y'
							where [id] = @client_id

							--выводим
							set @rp = (select @client_id as [id],
											  'Y' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end

				end


			if @sba in ('diet')
				begin

					declare @diet_id	  uniqueidentifier = json_value(@js, '$.id')
						  , @diet_name	  nvarchar(25) = json_value(@js, '$.name')
						  , @diet_description  nvarchar(150) = json_value(@js, '$.description')

					if @action in ('diet.get')
						begin

							set @rp = (select *
									   from [dbo].[diets]
									   where ([id] = @diet_id or [name] = @diet_name) and [status] = 'Y'
									   for json path, without_array_wrapper)
							goto ok

						end


					if @action in ('diet.create')
						begin

							--проверка обязательных параметров на null
							if (@diet_name is null)
								begin
									set @err = 'err.diet_create.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на корректность названия
							if (@diet_name like '%[0-9]%')
								begin
									set @err = 'err.diet_create.invalid_name'
									set @errdesc = 'Название диеты содержит цифры'

									goto err
								end

							--проверка на уже существующее название диеты
							set @rp_ = null
							set @jsT = (select @diet_name as [name] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.diet_create.not_unique_name'
									set @errdesc = 'Диета c таким названием уже существует'

									goto err
								end

							--добавляем значения в таблицу
							set @diet_id = newid()
							insert into [dbo].[diets] ([id], [name], [description])
							values (@diet_id,
									@diet_name,
									@diet_description)
		
							--выводим
							set @rp = (select @diet_id as [id],
											  @diet_name as [name],
											  @diet_description as [description]   		                 
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('diet.edit')
						begin

							--проверка на наличие id
							if (@diet_id is null)
								begin
									set @err = 'err.diet_edit.unset_field'
									set @errdesc = 'Диета не найдена'

									goto err
								end

							--проверка на наличие редактируемых параметров
							if (@diet_name is null and @diet_description is null)
								begin
									set @err = 'err.diet_edit.hasnt_data'
									set @errdesc = 'Отсутствуют данные редактирования'

									goto err
								end

							--проверка на корректность названия
							if (@diet_name is not null and @diet_name like '%[0-9]%')
								begin
									set @err = 'err.diet_edit.invalid_name'
									set @errdesc = 'Название содержит цифры'

									goto err
								end

							--проверка на существование диеты
							set @rp_ = null
							set @jsT = (select @diet_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.diet_edit.object_not_found'
									set @errdesc = 'Диета не найдена'

									goto err
								end

							--проверка на уже существующее название диеты
							set @rp_ = null
							set @jsT = (select @diet_name as [name] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.diet_edit.not_unique_name'
									set @errdesc = 'Диета c таким названием уже существует'

									goto err
								end

							--изменяем диету
							update [dbo].[diets] 
							set [name] = isnull(@diet_name, [name]),
								[description] = isnull(@diet_description, [description])
							where [id] = @diet_id
		
							--выводим
							set @rp = (select * from [dbo].[diets]
									   where [id] = @diet_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('diet.deactive')
						begin

							declare @diet_status char(1)

							--проверка на наличие id
							if (@diet_id is null)
								begin
									set @err = 'err.diet_deactive.unset_field'
									set @errdesc = 'Диета не найдена'

									goto err
								end


							select @diet_status = [status]
							from [dbo].[diets] 
							where [id] = @diet_id

			
							--проверка на существование диеты с таким id
							if (@diet_status is null)
								begin
									set @err = 'err.diet_deactive.object_not_found'
									set @errdesc = 'Диета не найдена'

									goto err
								end

							--проверка статуса диеты
							if (@diet_status = 'N')
								begin
									set @err = 'err.diet_deactive.diet_already_deactive'
									set @errdesc = 'Диета уже деактивирована'

									goto err
								end

							begin transaction

								--изменяем диету
								update [dbo].[diets] 
								set [status] = 'N'
								where [id] = @diet_id and [status] = 'Y'

								--деактивируем связи клиент - диета
								update [dbo].[clients_diet]
								set [status] = 'N'
								where [diet_id] = @diet_id and [status] = 'Y'

								--деактивируем связи блюдо - диета
								update [dbo].[dish_type]
								set [status] = 'N'
								where [diet_id] = @diet_id and [status] = 'Y'

							commit transaction

							--выводим
							set @rp = (select @diet_id as [id],
											  'N' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('diet.active')
						begin

							--проверка на наличие id
							if (@diet_id is null)
								begin
									set @err = 'err.diet_active.unset_field'
									set @errdesc = 'Диета не найдена'

									goto err
								end

							select @diet_status = [status],
								   @diet_name = [name]
							from [diets]
							where [id] = @diet_id

							--проверка на существование диеты с таким id
							if (@diet_status is null)
								begin
									set @err = 'err.diet_active.diet_not_found'
									set @errdesc = 'Диета не найдена'

									goto err
								end

							--проверка на активный статус
							if (@diet_status = 'Y')
								begin
									set @err = 'err.diet_active.diet_already_active'
									set @errdesc = 'Диета уже активна'

									goto err
								end

							--проверка на занятое имя
							set @rp_ = null
							set @jsT = (select @diet_name as [name] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out	

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.diet_active.not_unique_name'
									set @errdesc = 'Диета c таким названием уже существует'

									goto err
								end

							--меняем статус
							update [dbo].[diets] 
							set [status] = 'Y'
							where [id] = @diet_id

							--выводим
							set @rp = (select @diet_id as [id],
											  'Y' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end

				end


			if @sba in ('client_diet')
				begin

					declare @client_diet_id	uniqueidentifier = json_value(@js, '$.id')
						  , @client_id_cd uniqueidentifier = json_value(@js, '$.client_id')
						  , @diet_id_cd uniqueidentifier = json_value(@js, '$.diet_id')

					if @action in ('client_diet.get')
						begin

							set @rp = (select *
									   from [dbo].[clients_diet]
									   where ([id] = @client_diet_id
											or ([diet_id] = @diet_id_cd and [client_id] = @client_id_cd)
											or [client_id] = @client_id_cd) 
											and [status] = 'Y'
									   for json path)
							goto ok

						end


					if @action in ('client_diet.create')
						begin

							--проверка обязательных параметров на null
							if (@client_id_cd is null
								or @diet_id_cd is null)
								begin
									set @err = 'err.client_diet_create.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на существование клиента с таким id
							set @rp_ = null
							set @jsT = (select @client_id_cd as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.client_diet_create.client_not_found'
									set @errdesc = 'Клиент не найден'

									goto err
								end

							--проверка на существование диеты
							set @rp_ = null
							set @jsT = (select @diet_id_cd as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.client_diet_create.diet_not_found'
									set @errdesc = 'Диета не найдена'

									goto err
								end


							--проверка на уникальность связи
							set @rp_ = null
							set @jsT = (select @client_id_cd as [client_id],
											   @diet_id_cd as [diet_id]
											   for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client_diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
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

						end


					if @action in ('client_diet.deactive')
						begin
							
							declare @client_diet_status char(1)

							--проверка на наличие id
							if (@client_diet_id is null)
								begin
									set @err = 'err.client_diet_deactive.unset_field'
									set @errdesc = 'Диета клиента не найдена'

									goto err
								end


							select @client_diet_status = [status]
							from [dbo].[clients_diet] 
							where [id] = @client_diet_id

			
							--проверка на существование связи с таким id
							if (@client_diet_status is null)
								begin
									set @err = 'err.client_diet_deactive.relation_not_found'
									set @errdesc = 'Диета клиента не найдена'

									goto err
								end

							--проверка статуса связи
							if (@client_diet_status = 'N')
								begin
									set @err = 'err.client_diet_deactive.relation_already_deactive'
									set @errdesc = 'Диета клиента уже деактивирована'

									goto err
								end

							--изменяем связь
							update [dbo].[clients_diet] 
							set [status] = 'N'
							where [id] = @client_diet_id and [status] = 'Y'


							--выводим
							set @rp = (select @client_diet_id as [id],
											  'N' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end

				end


			if @sba in ('dish')
				begin

					declare @dish_id	uniqueidentifier = json_value(@js, '$.id')
						  , @dish_name nvarchar(20) = json_value(@js, '$.name')
						  , @restaurant_id_d uniqueidentifier = json_value(@js, '$.restaurant_id')
						  , @dish_description nvarchar(150) = json_value(@js, '$.description')
						  , @price decimal(7,2) = json_value(@js, '$.price')
						  , @calories int = json_value(@js, '$.calories')

					if @action in ('dish.get')
						begin

							set @rp = (select *
									   from [dbo].[dishes] as [d]
									   left join [ingredients] as [i] on [d].[id] = [i].[dish_id]
									   where ([d].[id] = @dish_id or ([d].[name] = @dish_name and [d].[restaurant_id] = @restaurant_id_d))
											and [d].[status] = 'Y'
											and ([i].[status] = 'Y' or [i].[status] is null)
									   for json auto, without_array_wrapper)
							goto ok	  

						end


					if @action in ('dish.create')
						begin

							--проверка обязательных параметров на null
							if (@dish_name is null
								or @restaurant_id_d is null
								or @price is null)
								begin
									set @err = 'err.dish_create.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на корректность названия
							if (@dish_name like '%[0-9]%')
								begin
									set @err = 'err.dish_create.invalid_name'
									set @errdesc = 'Название блюда некорректно'

									goto err
								end

							--проверка на корректность описания
							if (@dish_description is not null and @dish_description not like '%[^0-9]%')
								begin
									set @err = 'err.dish_create.invalid_description'
									set @errdesc = 'Некорректное описание'

									goto err
								end


							--проверка на корректность цены	
							if (@price < 0 and @price > 20000)
								begin
									set @err = 'err.dish_create.invalid_price'
									set @errdesc = 'Некорректная цена'

									goto err
								end

							--проверка на корректность каллорий
							if (@calories is not null and @calories < 0)
								begin
									set @err = 'err.dish_create.invalid_calories'
									set @errdesc = 'Некорректные калории'

									goto err
								end

							--проверка на существование ресторана
							set @rp_ = null
							set @jsT = (select @restaurant_id_d as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.dish_create.invalid_restaurant'
									set @errdesc = 'Указанного ресторана не существует'

									goto err
								end

							--проверка на дубликат блюда в ресторане
							set @rp_ = null
							set @jsT = (select @restaurant_id_d as [restaurant_id],
											   @dish_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.dish_create.duplicate'
									set @errdesc = 'Такое блюдо уже существует'

									goto err
								end

		
							--добавляем значения в таблицу
							set @dish_id = newid()
							insert into [dbo].[dishes] ([id], [name], [restaurant_id], [description], [price], [calories])
							values (@dish_id,
										@dish_name,
										@restaurant_id_d,
										@dish_description,
										@price,
										@calories)
		
							--выводим
							set @rp = (select @dish_id as [id],
											  @dish_name as [name],
											  @restaurant_id_d as [restaurant_id],
											  @dish_description as [description],
											  @price as [price],
											  @calories as [calories]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('dish.edit')
						begin
							
							--проверка на наличие id
							if (@dish_id is null)
								begin
									set @err = 'err.dish_edit.unset_field'
									set @errdesc = 'Блюдо не найдено'

									goto err
								end

							--проверка на наличие редактируемых параметров
							if (@dish_name is null 
								and @dish_description is null
								and @price is null
								and @calories is null)
								begin
									set @err = 'err.dish_edit.hasnt_data'
									set @errdesc = 'Отсутствуют данные редактирования'

									goto err
								end

							--проверка на корректность названия
							if (@dish_name is not null and @dish_name like '%[0-9]%')
								begin
									set @err = 'err.dish_edit.invalid_name'
									set @errdesc = 'Название блюда некорректно'

									goto err
								end

							--проверка на корректность описания
							if (@dish_description is not null and @dish_description not like '%[^0-9]%')
								begin
									set @err = 'err.dish_edit.invalid_description'
									set @errdesc = 'Некорректное описание'

									goto err
								end


							--проверка на корректность цены	
							if (@price is not null and @price < 0 and @price > 20000)
								begin
									set @err = 'err.dish_edit.invalid_price'
									set @errdesc = 'Некорректная цена'

									goto err
								end

							--проверка на корректность каллорий
							if (@calories is not null and @calories < 0)
								begin
									set @err = 'err.dish_edit.invalid_calories'
									set @errdesc = 'Некорректные калории'

									goto err
								end

							
							set @rp_ = null
							set @jsT = (select @dish_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							set @restaurant_id_d = json_value(@rp_, '$.response.restaurant_id')


							--проверка на существовани блюда с таким id
							if (@restaurant_id_d is null)
								begin
									set @err = 'err.dish_edit.object_not_found'
									set @errdesc = 'Блюдо не найдено'

									goto err
								end

							--проверка на дубликат блюда в ресторане
							if @dish_name is not null
								begin
									set @rp_ = null
									set @jsT = (select @restaurant_id_d as [restaurant_id],
													   @dish_name as [name]
												for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
										begin
											set @err = 'err.dish_edit.duplicate'
											set @errdesc = 'Такое блюдо уже существует'

											goto err
										end
								end

							--изменяем блюдо
							update [dbo].[dishes] 
							set [name] = isnull(@dish_name, [name]),
								[description] = isnull(@dish_description, [description]),
								[price] = isnull(@price, [price]),
								[calories] = isnull(@calories, [calories])
							where [id] = @dish_id
		
							--выводим
							set @rp = (select * from [dbo].[dishes]
									   where [id] = @dish_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('dish.deactive')
						begin

							declare @dish_status char(1)

							--проверка на наличие id
							if (@dish_id is null)
								begin
									set @err = 'err.dish_deactive.unset_field'
									set @errdesc = 'Блюдо не найдено'

									goto err
								end


							select @dish_status = [status]
							from [dbo].[dishes] 
							where [id] = @dish_id

			
							--проверка на существование блюда с таким id
							if (@dish_status is null)
								begin
									set @err = 'err.dish_deactive.object_not_found'
									set @errdesc = 'Блюдо не найдено'

									goto err
								end

							--проверка статуса блюда
							if (@dish_status = 'N')
								begin
									set @err = 'err.dish_deactive.dish_already_deactive'
									set @errdesc = 'Блюдо уже деактивировано'

									goto err
								end

							begin transaction

								--деактивируем блюдо
								update [dbo].[dishes]
								set [status] = 'N'
								where [id] = @dish_id

								--деактивируем связи блюдо - диета
								update [dbo].[dish_type]
								set [status] = 'N'
								where [dish_id] = @dish_id and [status] = 'Y'

								--деактивируем ингридиенты
								update [dbo].[ingredients]
								set [status] = 'N'
								where [dish_id] = @dish_id and [status] = 'Y'

							commit transaction

								--выводим
								set @rp = (select @dish_id as [id],
												  'N' as [status]
										   for json path, without_array_wrapper)
			
								goto ok

						end

				end


			if @sba in ('ingredient')
				begin

					declare @ingredient_id	uniqueidentifier = json_value(@js, '$.id')
						  , @dish_id_i uniqueidentifier = json_value(@js, '$.dish_id')
						  , @ingredient_name nvarchar(30) = json_value(@js, '$.name')
						  , @ingredient_status char(1)

					if @action in ('ingredient.get')
						begin

							set @rp = (select *
									   from [dbo].[ingredients]
									   where ([id] = @ingredient_id 
											or ([name] = @ingredient_name and [dish_id] = @dish_id_i)
											or ([dish_id] = @dish_id_i and @ingredient_name is null)) 
											and [status] = 'Y'
									   for json path)
							goto ok

						end


					if @action in ('ingredient.create')
						begin

							--проверка обязательных параметров на null
							if (@dish_id_i is null
								or @ingredient_name is null)
								begin
									set @err = 'err.ingredient_create.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на корректность названия
							if (@ingredient_name like '%[0-9]%')
								begin
									set @err = 'err.ingredient_create.invalid_name'
									set @errdesc = 'Название ингредиента некорректно'

									goto err
								end

							--проверка на существование блюда
							set @rp_ = null
							set @jsT = (select @dish_id_i as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.ingredient_create.dish_not_found'
									set @errdesc = 'Блюдо не найдено'

									goto err
								end

							--проверка на дубликат
							set @rp_ = null
							set @jsT = (select @dish_id_i as [dish_id],
											   @ingredient_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.ingredient_create.duplicate'
									set @errdesc = 'Ингредиент уже существует'

									goto err
								end

		
							--добавляем значения в таблицу
							set @ingredient_id = newid()
							insert into [dbo].[ingredients] ([id], [dish_id], [name])
							values (@ingredient_id,
									@dish_id_i,
									@ingredient_name)
		
							--выводим
							set @rp = (select @ingredient_id as [id],
											  @dish_id_i as [dish_id],
											  @ingredient_name as [name]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('ingredient.edit')
						begin

							--проверка на наличие id
							if (@ingredient_id is null)
								begin
									set @err = 'err.ingredient_edit.unset_field'
									set @errdesc = 'Ингредиент не найден'

									goto err
								end

							--проверка на наличие редактируемых параметров
							if (@ingredient_name is null)
								begin
									set @err = 'err.ingredient_edit.hasnt_data'
									set @errdesc = 'Отсутствуют данные редактирования'

									goto err
								end

							--проверка на корректность имени
							if (@ingredient_name like '%[0-9]%')
								begin
									set @err = 'err.ingredient_edit.invalid_name'
									set @errdesc = 'Имя некорректно'

									goto err
								end


							set @rp_ = null
							set @jsT = (select @ingredient_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							set @dish_id_i = json_value(@rp_, '$.response[0].dish_id')


							--проверка на существование ингредиента с таким id
							if (@dish_id_i is null)
								begin
									set @err = 'err.ingredient_edit.ingredient_not_found'
									set @errdesc = 'Ингредиент не найден'

									goto err
								end

							--проверка на дубликат
							set @rp_ = null
							set @jsT = (select @dish_id_i as [dish_id],
											   @ingredient_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.ingredient_edit.duplicate'
									set @errdesc = 'Ингредиент уже существует'

									goto err
								end

							--изменяем ингредиент
							update [dbo].[ingredients] 
							set [name] = isnull(@ingredient_name, [name])
							where [id] = @ingredient_id
		
							--выводим
							set @rp = (select * from [dbo].ingredients
									   where [id] = @ingredient_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('ingredient.deactive')
						begin

							--проверка на наличие id
							if (@ingredient_id is null)
								begin
									set @err = 'err.ingredient_deactive.unset_field'
									set @errdesc = 'Ингредиент не найден'

									goto err
								end


							select @ingredient_status = [status]
							from [dbo].[ingredients] 
							where [id] = @ingredient_id

			
							--проверка на существование ингредиента с таким id
							if (@ingredient_status is null)
								begin
									set @err = 'err.ingredient_deactive.ingredient_not_found'
									set @errdesc = 'Ингредиент с таким id не найден'

									goto err
								end

							--проверка статуса клиента
							if (@ingredient_status = 'N')
								begin
									set @err = 'err.ingredient_deactive.ingredient_already_deactive'
									set @errdesc = 'Ингредиент уже деактивирован'

									goto err
								end

							--деактивируем ингредиент
							update [dbo].[ingredients] 
							set [status] = 'N'
							where [id] = @ingredient_id


							--выводим
							set @rp = (select @ingredient_id as [id],
											  'N' as [status]
									   for json path, without_array_wrapper)
			
							goto ok

						end


					if @action in ('ingredient.active')
						begin

							--проверка на наличие id
							if (@ingredient_id is null)
								begin
									set @err = 'err.ingredient_active.unset_field'
									set @errdesc = 'Ингредиент не найден'

									goto err
								end

							select @ingredient_status = [status],
								   @ingredient_name = [name],
								   @dish_id_i = [dish_id]
							from [ingredients]
							where [id] = @ingredient_id

							--проверка на существование ингредиента с таким id
							if (@ingredient_status is null)
								begin
									set @err = 'err.ingredient_active.ingredient_not_found'
									set @errdesc = 'Ингредиент не найден'

									goto err
								end

							--проверка на активный статус
							if (@ingredient_status = 'Y')
								begin
									set @err = 'err.ingredient_active.ingredient_already_active'
									set @errdesc = 'Ингредиент уже активен'

									goto err
								end

							--проверка на существование блюда
							set @rp_ = null
							set @jsT = (select @dish_id_i as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.ingredient_active.dish_not_found'
									set @errdesc = 'Блюдо не найдено'

									goto err
								end

							--проверка на дубликат
							set @rp_ = null
							set @jsT = (select @dish_id_i as [dish_id],
											   @ingredient_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.ingredient_active.ingredient_already_exist'
									set @errdesc = 'Ингредиент уже существует'

									goto err
								end

							--меняем статус
							update [dbo].[ingredients] 
							set [status] = 'Y'
							where [id] = @ingredient_id

							--выводим
							set @rp = (select @ingredient_id as [id],
											  'Y' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end

				end


			if @sba in ('dish_type')
				begin

					declare @dish_type_id	uniqueidentifier = json_value(@js, '$.id')
						  , @dish_id_dt uniqueidentifier = json_value(@js, '$.dish_id')
						  , @diet_id_dt uniqueidentifier = json_value(@js, '$.diet_id')

					if @action in ('dish_type.get')
						begin

							set @rp = (select *
									   from [dbo].[dish_type]
									   where ([id] = @dish_type_id
											or ([dish_id] = @dish_id_dt and [diet_id] = @diet_id_dt)
											or [diet_id] = @diet_id_dt)
											and [status] = 'Y'
									   for json path)
							goto ok

						end


					if @action in ('dish_type.create')
						begin

							--проверка обязательных параметров на null
							if (@dish_id_dt is null
								or @diet_id_dt is null)
								begin
									set @err = 'err.dish_type_create.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на существование блюда с таким id
							set @rp_ = null
							set @jsT = (select @dish_id_dt as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.dish_type_create.dish_not_found'
									set @errdesc = 'Блюдо не найдено'

									goto err
								end

							--проверка на существование диеты
							set @rp_ = null
							set @jsT = (select @diet_id_dt as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.dish_type_create.diet_not_found'
									set @errdesc = 'Диета не найдена'

									goto err
								end


							--проверка на уникальность связи
							set @rp_ = null
							set @jsT = (select @dish_id_dt as [dish_id],
											   @diet_id_dt as [diet_id]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish_type.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.dish_type_create.relation_already_exist'
									set @errdesc = 'Связь блюдо - диета уже существует'

									goto err
								end

		
							--добавляем значения в таблицу
							set @dish_type_id = newid()
							insert into [dbo].[dish_type] ([id], [dish_id], [diet_id])
							values (@dish_type_id,
									@dish_id_dt,
									@diet_id_dt)
		
							--выводим
							set @rp = (select @dish_type_id as [id],
											  @dish_id_dt as [dish_id],
											  @diet_id_dt as [diet_id]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('dish_type.deactive')
						begin

							declare @dish_type_status char(1)

							--проверка на наличие id
							if (@dish_type_id is null)
								begin
									set @err = 'err.dish_type_deactive.unset_field'
									set @errdesc = 'Связь блюдо - диета не найдена'

									goto err
								end


							select @dish_type_status = [status]
							from [dbo].[dish_type] 
							where [id] = @dish_type_id

			
							--проверка на существование связи с таким id
							if (@dish_type_status is null)
								begin
									set @err = 'err.dish_type_deactive.relation_not_found'
									set @errdesc = 'Связь блюдо - диета не найдена'

									goto err
								end

							--проверка статуса связи
							if (@dish_type_status = 'N')
								begin
									set @err = 'err.dish_type_deactive.relation_already_deactive'
									set @errdesc = 'Связь блюдо - диета уже деактивирована'

									goto err
								end

							--изменяем связь
							update [dbo].[dish_type] 
							set [status] = 'N'
							where [id] = @dish_type_id and [status] = 'Y'


							--выводим
							set @rp = (select @dish_type_id as [id],
												'N' as [status]
										for json path, without_array_wrapper)

							goto ok

						end

				end


			if @sba in ('restaurant')
				begin

					declare @restaurant_id	uniqueidentifier = json_value(@js, '$.id')
						  , @restaurant_name nvarchar(25) = json_value(@js, '$.name')
						  , @address nvarchar(50) = json_value(@js, '$.address')
						  , @restaurant_phone nvarchar(11) = json_value(@js, '$.phone')
						  , @restaurant_email nvarchar(64) = json_value(@js, '$.email')
						  , @work_start time = json_value(@js, '$.work_start')
						  , @work_end time = json_value(@js, '$.work_end')
						  , @restaurant_status char(1)

					if @action in ('restaurant.get')
						begin

							set @rp = (select *
									   from [dbo].[restaurants]
									   where ([id] = @restaurant_id
											or ([name] = @restaurant_name and [address] = @address)
											or [phone] = @restaurant_phone
											or [email] = @restaurant_email)
											and [status] = 'Y'
									   for json path, without_array_wrapper)
							goto ok 

						end


					if @action in ('restaurant.create')
						begin

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
							set @rp_ = null
							set @jsT = (select @restaurant_name as [name], @address as [address] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_create.not_unique_address_and_name'
									set @errdesc = 'Такой ресторан уже существует'

									goto err
								end

							--проверка на уникальность телефона
							set @rp_ = null
							set @jsT = (select @restaurant_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_create.not_unique_phone'
									set @errdesc = 'Ресторан c таким телефоном уже существует'

									goto err
								end

							--проверка на уникальность email
							set @rp_ = null
							set @jsT = (select @restaurant_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
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

						end


					if @action in ('restaurant.edit')
						begin

							declare @old_address nvarchar(50),
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

							set @rp_ = null
							set @jsT = (select @restaurant_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							set @old_address = json_value(@rp_, '$.response.address')
							set @old_restaurant_name = json_value(@rp_, '$.response.name')

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
									set @rp_ = null
									set @jsT = (select isnull(@restaurant_name, @old_restaurant_name) as [name],
													   isnull(@address, @old_address) as [address]
												for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
										begin
											set @err = 'err.restaurant_edit.not_unique_address_and_name'
											set @errdesc = 'Такой ресторан уже существует'

											goto err
										end
								end

							--проверка на уникальность телефона
							if @restaurant_phone is not null
								begin
									set @rp_ = null
									set @jsT = (select @restaurant_phone as [phone] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
										begin
											set @err = 'err.restaurant_edit.not_unique_phone'
											set @errdesc = 'Ресторан c таким телефоном уже существует'

											goto err
										end
								end

							--проверка на уникальность email
							if @restaurant_email is not null
								begin
									set @rp_ = null
									set @jsT = (select @restaurant_email as [email] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
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

						end


					if @action in ('restaurant.deactive')
						begin

							--проверка на наличие id
							if (@restaurant_id is null)
								begin
									set @err = 'err.restaurant_deactive.unset_field'
									set @errdesc = 'Ресторан не найден'

									goto err
								end


							select @restaurant_status = [status]
							from [dbo].[restaurants] 
							where [id] = @restaurant_id

			
							--проверка на существование ресторана с таким id
							if (@restaurant_status is null)
								begin
									set @err = 'err.restaurant_deactive.object_not_found'
									set @errdesc = 'Ресторан не найден'

									goto err
								end

							--проверка статуса клиента
							if (@restaurant_status = 'N')
								begin
									set @err = 'err.restaurant_deactive.restaurant_already_deactive'
									set @errdesc = 'Ресторан уже деактивирован'

									goto err
								end

							--проверка активных броней
							if exists (select top 1 1
									   from [dbo].[table_bookings] as [tb]
									   join [dbo].[tables] as [t] on [tb].[table_id] = [t].[id]
									   where [t].[restaurant_id] = @restaurant_id and [tb].[status] = 'Y' and [t].[status] = 'Y')
								begin
									set @err = 'err.restaurant_deactive.restaurant_has_bookings'
									set @errdesc = 'У ресторана есть активные брони'

									goto err
								end

							begin transaction

								--деактивируем ресторан
								update [dbo].[restaurants]
								set [status] = 'N'
								where [id] = @restaurant_id

								--деактивируем его блюда
								update dt
								set [status] = 'N'
								from [dbo].[dish_type] dt
								left join [dbo].[dishes] dsh on dsh.[id] = dt.[dish_id] 
								where dsh.[restaurant_id] = @restaurant_id and dt.[status] = 'Y'

								update [dbo].[dishes]
								set [status] = 'N'
								where [restaurant_id] = @restaurant_id and [status] = 'Y'

								--деактивируем брони + столики
								update tb
								set [status] = 'N'
								from [dbo].[tables] t
								left join [dbo].[table_bookings] tb on tb.[table_id] = t.[id]
								where t.[restaurant_id] = @restaurant_id and tb.[status] = 'Y'

								update [dbo].[tables]
								set [status] = 'N'
								where [restaurant_id] = @restaurant_id and [status] = 'Y'

							commit transaction

								--выводим
								set @rp = (select @restaurant_id as [id],
												  'N' as [status]
										   for json path, without_array_wrapper)
			
								goto ok

						end


					if @action in ('restaurant.active')
						begin

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
							set @rp_ = null
							set @jsT = (select @restaurant_name as [name], @address as [address] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_active.not_unique_name_and_address'
									set @errdesc = 'Такой ресторан уже существует'

									goto err
								end

							--проверка на занятый телефон
							set @rp_ = null
							set @jsT = (select @restaurant_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_active.not_unique_phone'
									set @errdesc = 'Телефон уже используется'

									goto err
								end

							--проверка на занятый email
							set @rp_ = null
							set @jsT = (select @restaurant_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
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

						end

				end


			if @sba in ('table')
				begin

					declare @table_id	uniqueidentifier = json_value(@js, '$.id')
						  , @restaurant_id_t uniqueidentifier = json_value(@js, '$.restaurant_id')
						  , @number int = json_value(@js, '$.number')
						  , @capacity int = json_value(@js, '$.capacity')
						  , @table_status char(1)

					if @action in ('table.get')
						begin

							set @rp = (select *
									   from [dbo].[tables]
									   where ([id] = @table_id 
											or ([restaurant_id] = @restaurant_id_t and [number] = @number)
											or ([restaurant_id] = @restaurant_id_t)) 
											and [status] = 'Y'
									   for json path)
							goto ok

						end


					if @action in ('table.create')
						begin

							--проверка обязательных параметров на null
							if (@restaurant_id_t is null
								or @capacity is null
								or @number is null)
								begin
									set @err = 'err.table_create.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на корректность вместимости
							if (@capacity < 0 or @capacity > 30)
								begin
									set @err = 'err.table_create.invalid_capacity'
									set @errdesc = 'Вместимость некорректна'

									goto err
								end

							--проверка на корректность номера столика
							if (@number < 0 or @number > 100)
								begin
									set @err = 'err.table_create.invalid_number'
									set @errdesc = 'Некорректный номер столика'

									goto err
								end

							--проверка на существование ресторана
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_create.restaurant_not_found'
									set @errdesc = 'Ресторан не найден'

									goto err
								end

							--проверка на занятость номера столика
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [restaurant_id],
											   @number as [number]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.table_create.number_already_exist'
									set @errdesc = 'Номер столика занят'

									goto err
								end

		
							--добавляем значения в таблицу
							set @table_id = newid()

							insert into [dbo].[tables] ([id], [restaurant_id], [number], [capacity])
							values (@table_id,
									@restaurant_id_t,
									@number,
									@capacity)

							--выводим
							set @rp = (select @table_id as [id],
											  @restaurant_id_t as [restaurant_id],
											  @number as [number],
											  @capacity as [capacity]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table.deactive')
						begin

							--проверка на наличие id
							if (@table_id is null)
								begin
									set @err = 'err.table_deactive.unset_field'
									set @errdesc = 'Столик не найден'

									goto err
								end


							select @table_status = [status],
								   @restaurant_id_t = [restaurant_id]
							from [dbo].[tables] 
							where [id] = @table_id

			
							--проверка на существование столика с таким id
							if (@table_status is null)
								begin
									set @err = 'err.table_deactive.table_not_found'
									set @errdesc = 'Столик не найден'

									goto err
								end

							--проверка статуса столика
							if (@table_status = 'N')
								begin
									set @err = 'err.table_deactive.table_already_deactive'
									set @errdesc = 'Столик уже деактивирован'

									goto err
								end

							--проверяем на активные брони
							set @rp_ = null
							set @jsT = (select @table_id as [table_id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table_booking.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.table_deactive.active_bookings_exists'
									set @errdesc = 'У столика есть активные брони'

									goto err
								end

							--деактивируем столик
							update [dbo].[tables]
							set [status] = 'N'
							where [id] = @table_id

							--выводим
							set @rp = (select @table_id as [id],
												'N' as [status]
										for json path, without_array_wrapper)
			
							goto ok

						end


					if @action in ('table.active')
						begin

							--проверка на наличие id
							if (@table_id is null)
								begin
									set @err = 'err.table_active.unset_field'
									set @errdesc = 'Столик не найден'

									goto err
								end


							select @table_status = [status],
								   @restaurant_id_t = [restaurant_id],
								   @number = [number]
							from [dbo].[tables]
							where [id] = @table_id

							--проверка на существование столика с таким id
							if (@table_status is null)
								begin
									set @err = 'err.table_active.table_not_found'
									set @errdesc = 'Столик не найден'

									goto err
								end

							--проверка на активный статус
							if (@table_status = 'Y')
								begin
									set @err = 'err.table_active.table_already_active'
									set @errdesc = 'Столик уже активен'

									goto err
								end

							--проверка на существование ресторана c таким id
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_active.restaurant_not_found'
									set @errdesc = 'Ресторан не найден'

									goto err
								end

							--проверка на занятость номера столика
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [restaurant_id],
											   @number as [number]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.table_active.number_already_exist'
									set @errdesc = 'Номер столика занят'

									goto err
								end

							--меняем статус
							update [dbo].[tables] 
							set [status] = 'Y'
							where [id] = @table_id

							--выводим
							set @rp = (select @table_id as [id],
											  'Y' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end

				end


			if @sba in ('table_booking')
				begin

					declare @table_booking_id	uniqueidentifier = json_value(@js, '$.id')
						  , @client_id_tb uniqueidentifier = json_value(@js, '$.client_id')
						  , @table_id_tb uniqueidentifier = json_value(@js, '$.table_id')
						  , @date date = json_value(@js, '$.date')
						  , @start_time time = json_value(@js, '$.start_time')
						  , @end_time time = json_value(@js, '$.end_time')
						  , @guests_count int = json_value(@js, '$.guests_count')
						  , @table_booking_status varchar(10) = json_value(@js, '$.status')
						  , @capacity_tb int
						  , @restaurant_id_tb	uniqueidentifier = json_value(@js, '$.restaurant_id')

					if @action in ('table_booking.get')
						begin

							set @rp = (select *
									   from [dbo].[table_bookings]
									   where ([id] = @table_booking_id or [client_id] = @client_id_tb or [table_id] = @table_id_tb) and [status] in ('wait_conf', 'confirm')
									   for json path)
							goto ok

						end


					if @action in ('table_booking.create')
						begin

							--проверка обязательных параметров на null
							if (@table_id_tb is null
								or @date is null
								or @start_time is null
								or @end_time is null
								or @guests_count is null)
								begin
									set @err = 'err.table_booking_create.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на корректность даты
							if (@date < cast(getdate() as date))
								begin
									set @err = 'err.tabel_booking_create.invalid_date'
									set @errdesc = 'Некорректная дата'

									goto err
								end

							--проверка на корректность времени
							if (@start_time > @end_time)
								begin
									set @err = 'err.tabel_booking_create.invalid_time'
									set @errdesc = 'Некорректное время'

									goto err
								end

							--проверка на корректность статуса
							if @table_booking_status is not null and @table_booking_status not in ('wait_conf', 'confirm', 'cancel', 'success')
								begin
									set @err = 'err.tabel_booking_create.invalid_status'
									set @errdesc = 'Некорректный статус'

									goto err
								end


							set @rp_ = null
							set @jsT = (select @table_id_tb as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table.get', @jsT, @rp_ out

							set @capacity_tb = json_value(@rp_, '$.response[0].capacity')


							--проверка на сущестование столика
							if (@capacity_tb is null)
								begin
									set @err = 'err.table_booking_create.table_not_found'
									set @errdesc = 'Столик не найден'

									goto err
								end

							--проверка на корректность числа гостей
							if (@guests_count < 1 or @guests_count > @capacity_tb)
								begin
									set @err = 'err.table_booking_create.invalid_guests_count'
									set @errdesc = 'Максимальная вместимость = ' + cast(@capacity_tb as nvarchar(3))

									goto err
								end

							--проверка на сущестование клиента
							if @client_id_tb is not null
								begin
									set @rp_ = null
									set @jsT = (select @client_id_tb as [id] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is null
										begin
											set @err = 'err.table_booking_create.client_not_found'
											set @errdesc = 'Клиент не найден'

											goto err
										end
								end

							--проверка времени, что оно попадает в рабочие часы
							if not exists (select top 1 1
											from [dbo].[tables] as [t]
											join [dbo].[restaurants] as [r] on [t].[restaurant_id] = [r].[id]
											where [t].[id] = @table_id_tb
												and (@start_time between [r].[work_start] and [r].[work_end])
												and (@end_time between [r].[work_start] and [r].[work_end])
												and [t].[status] = 'Y'
												and [r].[status] = 'Y')
								begin
									set @err = 'err.table_booking_create.invalid_time'
									set @errdesc = 'Указанное время не соответствует режиму работы'

									goto err
								end

							--проверка на занятость столика
							if exists (select top 1 1
										from [dbo].[table_bookings]
										where [table_id] = @table_id_tb
											and [date] = @date
											and (([start_time] between @start_time and @end_time) or ([end_time] between @start_time and @end_time))
											and [status] in ('wait_conf', 'confirm'))
								begin
									set @err = 'err.table_booking_create.table_is_occupied'
									set @errdesc = 'Столик занят в указанное время'

									goto err
								end

		
							--добавляем значения в таблицу
							set @table_booking_id = newid()
							insert into [dbo].[table_bookings] ([id], [client_id], [table_id], [date], [start_time], [end_time], [guests_count], [status])
							values (@table_booking_id,
									@client_id_tb,
									@table_id_tb,
									@date,
									@start_time,
									@end_time,
									@guests_count,
									isnull(@table_booking_status, 'wait_conf'))
		
							--выводим
							set @rp = (select @table_booking_id as [id],
												@client_id_tb as [client_id],
												@table_id_tb as [table_id],
												@date as [date],
												@start_time as [start_time],
												@end_time as [end_time],
												@guests_count as [guests_count],
												isnull(@table_booking_status, 'wait_conf') as [status]
										for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.confirm')
						begin

							--проверка на наличие id
							if (@table_booking_id is null)
								begin
									set @err = 'err.table_booking_confirm.unset_field'
									set @errdesc = 'Бронь не найдена'

									goto err
								end

							select @table_booking_status = [status]
							from [dbo].[table_bookings] 
							where [id] = @table_booking_id

							--проверка на существование брони с таким id
							if @table_booking_status is null
								begin
									set @err = 'err.table_booking_confirm.table_booking_not_found'
									set @errdesc = 'Бронь не найдена'

									goto err
								end


							--проверка на статус 
							if @table_booking_status in ('cancel', 'success')
								begin
									set @err = 'err.table_booking_confirm.booking_ended'
									set @errdesc = 'Бронь закончилась'

									goto err
								end

							--проверка на статус 
							if @table_booking_status = 'confirm'
								begin
									set @err = 'err.table_booking_confirm.booking_already_confirm'
									set @errdesc = 'Бронь уже подтверждена'

									goto err
								end	

							--изменяем бронь
							update [dbo].[table_bookings] 
							set [status] = 'confirm'
							where [id] = @table_booking_id
		
							--выводим
							set @rp = (select @table_booking_id as [id],
											  'confirm' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.cancel')
						begin

							--проверка на наличие id
							if (@table_booking_id is null)
								begin
									set @err = 'err.table_booking_cancel.unset_field'
									set @errdesc = 'Бронь не найдена'

									goto err
								end

							select @table_booking_status = [status]
							from [dbo].[table_bookings] 
							where [id] = @table_booking_id

							--проверка на существование брони с таким id
							if @table_booking_status is null
								begin
									set @err = 'err.table_booking_cancel.table_booking_not_found'
									set @errdesc = 'Бронь не найдена'

									goto err
								end


							--проверка на статус 
							if @table_booking_status in ('cancel', 'success')
								begin
									set @err = 'err.table_booking_cancel.booking_ended'
									set @errdesc = 'Бронь уже закончилась'

									goto err
								end	

	

							--изменяем бронь
							update [dbo].[table_bookings] 
							set [status] = 'cancel'
							where [id] = @table_booking_id
		
							--выводим
							set @rp = (select @table_booking_id as [id],
											  'cancel' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.success')
						begin

							--проверка на наличие id
							if (@table_booking_id is null)
								begin
									set @err = 'err.table_booking_success.unset_field'
									set @errdesc = 'Бронь не найдена'

									goto err
								end

							select @table_booking_status = [status]
							from [dbo].[table_bookings] 
							where [id] = @table_booking_id

							--проверка на существование брони с таким id
							if @table_booking_status is null
								begin
									set @err = 'err.table_booking_success.table_booking_not_found'
									set @errdesc = 'Бронь не найдена'

									goto err
								end

							--проверка на статус 
							if @table_booking_status = 'wait_conf'
								begin
									set @err = 'err.table_booking_success.booking_not_confirm'
									set @errdesc = 'Бронь не подтверждена'

									goto err
								end	

							--проверка на статус 
							if @table_booking_status = 'cancel'
								begin
									set @err = 'err.table_booking_success.booking_canceled'
									set @errdesc = 'Бронь отменена'

									goto err
								end	

							--проверка на статус 
							if @table_booking_status = 'success'
								begin
									set @err = 'err.table_booking_success.booking_already_success'
									set @errdesc = 'Бронь уже закончилась'

									goto err
								end	

	

							--изменяем бронь
							update [dbo].[table_bookings] 
							set [status] = 'success'
							where [id] = @table_booking_id
		
							--выводим
							set @rp = (select @table_booking_id as [id],
											  'success' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.search_free_table')
						begin

							--проверка на наличие id
							if (@restaurant_id_tb is null)
								begin
									set @err = 'err.table_booking_search_free_table.unset_field'
									set @errdesc = 'Ресторан не найден'

									goto err
								end

							--проверка обязательных параметров на null
							if (@date is null
								or @start_time is null
								or @end_time is null
								or @guests_count is null)
								begin
									set @err = 'err.table_booking_search_free_table.hasnt_data'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--проверка на корректность даты
							if (@date < cast(getdate() as date))
								begin
									set @err = 'err.tabel_booking_search_free_tables.invalid_date'
									set @errdesc = 'Некорректная дата'

									goto err
								end

							--проверка на корректность времени
							if (@start_time > @end_time)
								begin
									set @err = 'err.tabel_booking_create.invalid_time'
									set @errdesc = 'Некорректное время'

									goto err
								end

							--проверка на корректность числа гостей
							if (@guests_count < 1 or @guests_count > 30)
								begin
									set @err = 'err.table_booking_search_free_table.invalid_guests_count'
									set @errdesc = 'Некорректное число гостей'

									goto err
								end

							--проверка на существование ресторана
							set @rp_ = null
							set @jsT = (select @restaurant_id_tb as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_booking_search_free_table.restaurant_not_found'
									set @errdesc = 'Ресторан не найден'

									goto err
								end

							--проверка корректности времени, что оно попадает в рабочие часы
							if not exists (select top 1 1
										   from [dbo].[restaurants]
										   where [id] = @restaurant_id_tb
												and (@start_time between [work_start] and [work_end])
												and (@end_time between [work_start] and [work_end])
												and [status] = 'Y')
								begin
									set @err = 'err.table_booking_search_free_table.invalid_time'
									set @errdesc = 'Указанное время не соответствует режиму работы'

									goto err
								end
		
							--выводим
							set @rp = (select top 1 t.*
									   from [dbo].[tables] t
									   left join [dbo].[table_bookings] tb on tb.[table_id] = t.id
									   where (tb.[id] is null 
											or (@date = [date] and (@start_time not between [start_time] and [end_time]) 
															   and (@end_time not between [start_time] and [end_time])
															   and ([start_time] not between @start_time and @end_time)
															   and ([end_time] not between @start_time and @end_time)
											or @date <> [date])
											and t.[capacity] >= @guests_count
											and t.[status] = 'Y')
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.seat_now')
						begin

							set @date = cast(getdate() as date)

							--проверка обязательных параметров на null
							if (@restaurant_id_tb is null
								or @start_time is null
								or @end_time is null
								or @guests_count is null)
								begin
									set @err = 'err.table_booking_seat_now.unset_field'
									set @errdesc = 'Указаны не все необходимые параметры'

									goto err
								end

							--ищем столик
							set @rp_ = null
							set @jsT = (select @restaurant_id_tb as [restaurant_id],
											   @date as [date],
											   @start_time as [start_time],
											   @end_time as [end_time],
											   @guests_count as [guests_count]
										for json path, without_array_wrapper)

							exec [dbo].[ms_api] 'table_booking.search_free_table', @jsT, @rp_ out

							--проверяю на ошибки по вложенной процедуре
							if json_value(@rp_, '$.status') = 'err'
								begin
									set @err = json_value(@rp_, '$.err')
									set @errdesc = json_value(@rp_, '$.errdesc')

									goto err
								end

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_booking_seat_now.table_not_found'
									set @errdesc = 'Свободных столиков нет'

									goto err
								end
							else
								begin

									--создаем бронь
									set @jsT = (select @client_id_tb as [client_id],
													   json_value(@rp_, '$.response.id') as [table_id],
													   @date as [date],
													   @start_time as [start_time],
													   @end_time as [end_time],
													   @guests_count as [guests_count],
													   'confirm' as [status]
												for json path, without_array_wrapper)

									set @rp_ = null

									exec [dbo].[ms_api] 'table_booking.create', @jsT, @rp_ out

									--проверяю на ошибки по вложенной процедуре
									if json_value(@rp_, '$.status') = 'err'
										begin
											set @err = json_value(@rp_, '$.err')
											set @errdesc = json_value(@rp_, '$.errdesc')

											goto err
										end


									set @rp = @rp_
									return

								end

						end

				end

		end try

		begin catch

			if @@trancount > 0
				rollback transaction

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