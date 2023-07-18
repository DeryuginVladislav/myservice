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
							
							--�������� ������������ ���������� �� null
							if (@firstname is null
								or @lastname is null
								or @client_phone is null)
								begin
									set @err = 'err.client_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ email
							if (@client_email is not null and @client_email not like '%_@_%._%')
								begin
									set @err = 'err.client_create.invalid_email'
									set @errdesc = '������������ email'

									goto err
								end

							--�������� �� ������������ �����
							if (@firstname like '%[0-9]%')
								begin
									set @err = 'err.client_create.invalid_firstname'
									set @errdesc = '��� �����������'

									goto err
								end

							--�������� �� ������������ �������
							if (@lastname like '%[0-9]%')
								begin
									set @err = 'err.client_create.invalid_lastname'
									set @errdesc = '������� �����������'

									goto err
								end

							--�������� �� ������������ dob
							if (@dob is not null and @dob > getdate())
								begin
									set @err = 'err.client_create.invalid_dob'
									set @errdesc = '������������ ����'

									goto err
								end

							--�������� �� ������������ phone	
							if @client_phone like '%[^0-9]%' and len(@client_phone) < 11
								begin
									set @err = 'err.client_create.invalid_phone'
									set @errdesc = '������������ �������'

									goto err
								end

							--�������� �� ������������ ��������
							set @rp_ = null
							set @jsT = (select @client_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.client_create.not_unique_phone'
									set @errdesc = '������ c ����� ��������� ��� ����������'

									goto err
								end

							--�������� �� ������������ email
							set @rp_ = null
							set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.client_create.not_unique_email'
									set @errdesc = '������ c ����� email ��� ����������'

									goto err
								end

		
							--��������� �������� � �������
							set @client_id = newid()
							insert into [dbo].[clients] ([id], [firstname], [lastname], [email], [phone], [dob])
							values (@client_id,
									@firstname,
									@lastname,
									@client_email,
									@client_phone,
									@dob)
		
							--�������
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

							--�������� �� ������� id
							if (@client_id is null)
								begin
									set @err = 'err.client_edit.unset_field'
									set @errdesc = '������ �� ������'

									goto err
								end

							--�������� �� ������� ������������� ����������
							if (@firstname is null 
								and @lastname is null
								and @client_email is null
								and @client_phone is null
								and @dob is null)
								begin
									set @err = 'err.client_edit.hasnt_data'
									set @errdesc = '����������� ������ ��������������'

									goto err
								end

							--�������� �� ������������ email
							if (@client_email is not null and @client_email not like '%_@_%._%')
								begin
									set @err = 'err.client_edit.invalid_email'
									set @errdesc = '������������ email'

									goto err
								end

							--�������� �� ������������ �����
							if (@firstname is not null and @firstname like '%[0-9]%')
								begin
									set @err = 'err.client_edit.invalid_firstname'
									set @errdesc = '��� �����������'

									goto err
								end

							--�������� �� ������������ �������
							if (@lastname is not null and @lastname like '%[0-9]%')
								begin
									set @err = 'err.client_edit.invalid_lastname'
									set @errdesc = '������� �����������'

									goto err
								end

							--�������� �� ������������ dob
							if (@dob is not null and @dob > getdate())
								begin
									set @err = 'err.client_edit.invalid_dob'
									set @errdesc = '������������ ����'

									goto err
								end

							--�������� �� ������������ phone	
							if (@client_phone is not null and @client_phone like '%[^0-9]%')
								begin
									set @err = 'err.client_edit.invalid_phone'
									set @errdesc = '������������ �������'

									goto err
								end

							--�������� �� ������������� ������� � ����� id
							set @rp_ = null
							set @jsT = (select @client_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.client_edit.object_not_found'
									set @errdesc = '������ �� ������'

									goto err
								end

							--�������� �� ������� �������
							if @client_phone is not null
								begin
									set @rp_ = null
									set @jsT = (select @client_phone as [phone] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
										begin
											set @err = 'err.client_edit.not_unique_phone'
											set @errdesc = '������� ��� ������������'

											goto err
										end
								end

							--�������� �� ������� email
							if @client_email is not null
								begin
									set @rp_ = null
									set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null										
										begin
											set @err = 'err.client_edit.not_unique_email'
											set @errdesc = 'Email ��� ������������'

											goto err
										end
								end

							--�������� �������
							update [dbo].[clients] 
							set [firstname] = isnull(@firstname, [firstname]),
								[lastname] = isnull(@lastname, [lastname]),
								[email] = isnull(@client_email, [email]),
								[phone] = isnull(@client_phone, [phone]),
								[dob] = isnull(@dob, [dob])
							where [id] = @client_id
		
							--�������
							set @rp = (select * from [dbo].[clients]
									   where [id] = @client_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('client.deactive')
						begin

							declare @client_status char(1)

							--�������� �� ������� id
							if (@client_id is null)
								begin
									set @err = 'err.client_deactive.unset_field'
									set @errdesc = '������ �� ������'

									goto err
								end


							select @client_status = [status]
							from [dbo].[clients] 
							where [id] = @client_id

			
							--�������� �� ������������� ������� � ����� id
							if (@client_status is null)
								begin
									set @err = 'err.client_deactive.object_not_found'
									set @errdesc = '������ �� ������'

									goto err
								end

							--�������� ������� �������
							if (@client_status = 'N')
								begin
									set @err = 'err.client_deactive.client_already_deactive'
									set @errdesc = '������ ��� �������������'

									goto err
								end

							--�������� �������� ������
							set @rp_ = null
							set @jsT = (select @client_id as [id] for json path, without_array_wrapper)
							exec [dbo].ms_api 'table_booking.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.client_deactive.client_has_bookings'
									set @errdesc = '� ������� ���� �������� �����'

									goto err
								end


							begin transaction

								--�������� �������
								update [dbo].[clients] 
								set [status] = 'N'
								where [id] = @client_id and [status] = 'Y'

								--������������ ��� �����
								update [dbo].[clients_diet]
								set [status] = 'N'
								where [client_id] = @client_id and [status] = 'Y'

							commit transaction


							--�������
							set @rp = (select @client_id as [id],
											  'N' as [status]
									   for json path, without_array_wrapper)
			
							goto ok

						end


					if @action in ('client.active')
						begin
							
							--�������� ��  id
							if (@client_id is null)
								begin
									set @err = 'err.client_active.unset_field'
									set @errdesc = '������ �� ������'

									goto err
								end

							select @client_status = [status],
								   @client_phone = [phone],
								   @client_email = [email]
							from [clients]
							where [id] = @client_id

							--�������� ���������� �� ������ � ����� id
							if (@client_status is null)
								begin
									set @err = 'err.client_active.client_not_found'
									set @errdesc = '������ �� ���������'

									goto err
								end

							--�������� �� �� ��� ������ ��� �������
							if (@client_status = 'Y')
								begin
									set @err = 'err.client_active.client_already_active'
									set @errdesc = '������ ��� �������'

									goto err
								end

							--�������� �� ������������ ��������
							set @rp_ = null
							set @jsT = (select @client_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.client_active.not_unique_phone'
									set @errdesc = '��������� ������� ��� ������������'

									goto err
								end

							--�������� �� ������������ email
							set @rp_ = null
							set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null								
								begin
									set @err = 'err.client_active.not_unique_email'
									set @errdesc = 'Email ��� ������������'

									goto err
								end

							--�������� ������ �������
							update [dbo].[clients] 
							set [status] = 'Y'
							where [id] = @client_id

							--�������
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

							--�������� ������������ ���������� �� null
							if (@diet_name is null)
								begin
									set @err = 'err.diet_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@diet_name like '%[0-9]%')
								begin
									set @err = 'err.diet_create.invalid_name'
									set @errdesc = '�������� ����� �������� �����'

									goto err
								end

							--�������� �� ��� ������������ �������� �����
							set @rp_ = null
							set @jsT = (select @diet_name as [name] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.diet_create.not_unique_name'
									set @errdesc = '����� c ����� ��������� ��� ����������'

									goto err
								end

							--��������� �������� � �������
							set @diet_id = newid()
							insert into [dbo].[diets] ([id], [name], [description])
							values (@diet_id,
									@diet_name,
									@diet_description)
		
							--�������
							set @rp = (select @diet_id as [id],
											  @diet_name as [name],
											  @diet_description as [description]   		                 
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('diet.edit')
						begin

							--�������� �� ������� id
							if (@diet_id is null)
								begin
									set @err = 'err.diet_edit.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ������� ������������� ����������
							if (@diet_name is null and @diet_description is null)
								begin
									set @err = 'err.diet_edit.hasnt_data'
									set @errdesc = '����������� ������ ��������������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@diet_name is not null and @diet_name like '%[0-9]%')
								begin
									set @err = 'err.diet_edit.invalid_name'
									set @errdesc = '�������� �������� �����'

									goto err
								end

							--�������� �� ������������� �����
							set @rp_ = null
							set @jsT = (select @diet_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.diet_edit.object_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ��� ������������ �������� �����
							set @rp_ = null
							set @jsT = (select @diet_name as [name] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.diet_edit.not_unique_name'
									set @errdesc = '����� c ����� ��������� ��� ����������'

									goto err
								end

							--�������� �����
							update [dbo].[diets] 
							set [name] = isnull(@diet_name, [name]),
								[description] = isnull(@diet_description, [description])
							where [id] = @diet_id
		
							--�������
							set @rp = (select * from [dbo].[diets]
									   where [id] = @diet_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('diet.deactive')
						begin

							declare @diet_status char(1)

							--�������� �� ������� id
							if (@diet_id is null)
								begin
									set @err = 'err.diet_deactive.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end


							select @diet_status = [status]
							from [dbo].[diets] 
							where [id] = @diet_id

			
							--�������� �� ������������� ����� � ����� id
							if (@diet_status is null)
								begin
									set @err = 'err.diet_deactive.object_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� ������� �����
							if (@diet_status = 'N')
								begin
									set @err = 'err.diet_deactive.diet_already_deactive'
									set @errdesc = '����� ��� ��������������'

									goto err
								end

							begin transaction

								--�������� �����
								update [dbo].[diets] 
								set [status] = 'N'
								where [id] = @diet_id and [status] = 'Y'

								--������������ ����� ������ - �����
								update [dbo].[clients_diet]
								set [status] = 'N'
								where [diet_id] = @diet_id and [status] = 'Y'

								--������������ ����� ����� - �����
								update [dbo].[dish_type]
								set [status] = 'N'
								where [diet_id] = @diet_id and [status] = 'Y'

							commit transaction

							--�������
							set @rp = (select @diet_id as [id],
											  'N' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('diet.active')
						begin

							--�������� �� ������� id
							if (@diet_id is null)
								begin
									set @err = 'err.diet_active.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end

							select @diet_status = [status],
								   @diet_name = [name]
							from [diets]
							where [id] = @diet_id

							--�������� �� ������������� ����� � ����� id
							if (@diet_status is null)
								begin
									set @err = 'err.diet_active.diet_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� �������� ������
							if (@diet_status = 'Y')
								begin
									set @err = 'err.diet_active.diet_already_active'
									set @errdesc = '����� ��� �������'

									goto err
								end

							--�������� �� ������� ���
							set @rp_ = null
							set @jsT = (select @diet_name as [name] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out	

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.diet_active.not_unique_name'
									set @errdesc = '����� c ����� ��������� ��� ����������'

									goto err
								end

							--������ ������
							update [dbo].[diets] 
							set [status] = 'Y'
							where [id] = @diet_id

							--�������
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

							--�������� ������������ ���������� �� null
							if (@client_id_cd is null
								or @diet_id_cd is null)
								begin
									set @err = 'err.client_diet_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������� ������� � ����� id
							set @rp_ = null
							set @jsT = (select @client_id_cd as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.client_diet_create.client_not_found'
									set @errdesc = '������ �� ������'

									goto err
								end

							--�������� �� ������������� �����
							set @rp_ = null
							set @jsT = (select @diet_id_cd as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.client_diet_create.diet_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end


							--�������� �� ������������ �����
							set @rp_ = null
							set @jsT = (select @client_id_cd as [client_id],
											   @diet_id_cd as [diet_id]
											   for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client_diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.client_diet_create.relation_already_exist'
									set @errdesc = '����� � ������� ��� ����������'

									goto err
								end

		
							--��������� �������� � �������
							set @client_diet_id = newid()
							insert into [dbo].[clients_diet] ([id], [client_id], [diet_id])
								values (@client_diet_id,
										@client_id_cd,
										@diet_id_cd)
		
							--�������
							set @rp = (select @client_diet_id as [id],
											  @client_id_cd as [client_id],
											  @diet_id_cd as [diet_id]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('client_diet.deactive')
						begin
							
							declare @client_diet_status char(1)

							--�������� �� ������� id
							if (@client_diet_id is null)
								begin
									set @err = 'err.client_diet_deactive.unset_field'
									set @errdesc = '����� ������� �� �������'

									goto err
								end


							select @client_diet_status = [status]
							from [dbo].[clients_diet] 
							where [id] = @client_diet_id

			
							--�������� �� ������������� ����� � ����� id
							if (@client_diet_status is null)
								begin
									set @err = 'err.client_diet_deactive.relation_not_found'
									set @errdesc = '����� ������� �� �������'

									goto err
								end

							--�������� ������� �����
							if (@client_diet_status = 'N')
								begin
									set @err = 'err.client_diet_deactive.relation_already_deactive'
									set @errdesc = '����� ������� ��� ��������������'

									goto err
								end

							--�������� �����
							update [dbo].[clients_diet] 
							set [status] = 'N'
							where [id] = @client_diet_id and [status] = 'Y'


							--�������
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

							--�������� ������������ ���������� �� null
							if (@dish_name is null
								or @restaurant_id_d is null
								or @price is null)
								begin
									set @err = 'err.dish_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@dish_name like '%[0-9]%')
								begin
									set @err = 'err.dish_create.invalid_name'
									set @errdesc = '�������� ����� �����������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@dish_description is not null and @dish_description not like '%[^0-9]%')
								begin
									set @err = 'err.dish_create.invalid_description'
									set @errdesc = '������������ ��������'

									goto err
								end


							--�������� �� ������������ ����	
							if (@price < 0 and @price > 20000)
								begin
									set @err = 'err.dish_create.invalid_price'
									set @errdesc = '������������ ����'

									goto err
								end

							--�������� �� ������������ ��������
							if (@calories is not null and @calories < 0)
								begin
									set @err = 'err.dish_create.invalid_calories'
									set @errdesc = '������������ �������'

									goto err
								end

							--�������� �� ������������� ���������
							set @rp_ = null
							set @jsT = (select @restaurant_id_d as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.dish_create.invalid_restaurant'
									set @errdesc = '���������� ��������� �� ����������'

									goto err
								end

							--�������� �� �������� ����� � ���������
							set @rp_ = null
							set @jsT = (select @restaurant_id_d as [restaurant_id],
											   @dish_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.dish_create.duplicate'
									set @errdesc = '����� ����� ��� ����������'

									goto err
								end

		
							--��������� �������� � �������
							set @dish_id = newid()
							insert into [dbo].[dishes] ([id], [name], [restaurant_id], [description], [price], [calories])
							values (@dish_id,
										@dish_name,
										@restaurant_id_d,
										@dish_description,
										@price,
										@calories)
		
							--�������
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
							
							--�������� �� ������� id
							if (@dish_id is null)
								begin
									set @err = 'err.dish_edit.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ������� ������������� ����������
							if (@dish_name is null 
								and @dish_description is null
								and @price is null
								and @calories is null)
								begin
									set @err = 'err.dish_edit.hasnt_data'
									set @errdesc = '����������� ������ ��������������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@dish_name is not null and @dish_name like '%[0-9]%')
								begin
									set @err = 'err.dish_edit.invalid_name'
									set @errdesc = '�������� ����� �����������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@dish_description is not null and @dish_description not like '%[^0-9]%')
								begin
									set @err = 'err.dish_edit.invalid_description'
									set @errdesc = '������������ ��������'

									goto err
								end


							--�������� �� ������������ ����	
							if (@price is not null and @price < 0 and @price > 20000)
								begin
									set @err = 'err.dish_edit.invalid_price'
									set @errdesc = '������������ ����'

									goto err
								end

							--�������� �� ������������ ��������
							if (@calories is not null and @calories < 0)
								begin
									set @err = 'err.dish_edit.invalid_calories'
									set @errdesc = '������������ �������'

									goto err
								end

							
							set @rp_ = null
							set @jsT = (select @dish_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							set @restaurant_id_d = json_value(@rp_, '$.response.restaurant_id')


							--�������� �� ������������ ����� � ����� id
							if (@restaurant_id_d is null)
								begin
									set @err = 'err.dish_edit.object_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� �������� ����� � ���������
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
											set @errdesc = '����� ����� ��� ����������'

											goto err
										end
								end

							--�������� �����
							update [dbo].[dishes] 
							set [name] = isnull(@dish_name, [name]),
								[description] = isnull(@dish_description, [description]),
								[price] = isnull(@price, [price]),
								[calories] = isnull(@calories, [calories])
							where [id] = @dish_id
		
							--�������
							set @rp = (select * from [dbo].[dishes]
									   where [id] = @dish_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('dish.deactive')
						begin

							declare @dish_status char(1)

							--�������� �� ������� id
							if (@dish_id is null)
								begin
									set @err = 'err.dish_deactive.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end


							select @dish_status = [status]
							from [dbo].[dishes] 
							where [id] = @dish_id

			
							--�������� �� ������������� ����� � ����� id
							if (@dish_status is null)
								begin
									set @err = 'err.dish_deactive.object_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� ������� �����
							if (@dish_status = 'N')
								begin
									set @err = 'err.dish_deactive.dish_already_deactive'
									set @errdesc = '����� ��� ��������������'

									goto err
								end

							begin transaction

								--������������ �����
								update [dbo].[dishes]
								set [status] = 'N'
								where [id] = @dish_id

								--������������ ����� ����� - �����
								update [dbo].[dish_type]
								set [status] = 'N'
								where [dish_id] = @dish_id and [status] = 'Y'

								--������������ �����������
								update [dbo].[ingredients]
								set [status] = 'N'
								where [dish_id] = @dish_id and [status] = 'Y'

							commit transaction

								--�������
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

							--�������� ������������ ���������� �� null
							if (@dish_id_i is null
								or @ingredient_name is null)
								begin
									set @err = 'err.ingredient_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@ingredient_name like '%[0-9]%')
								begin
									set @err = 'err.ingredient_create.invalid_name'
									set @errdesc = '�������� ����������� �����������'

									goto err
								end

							--�������� �� ������������� �����
							set @rp_ = null
							set @jsT = (select @dish_id_i as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.ingredient_create.dish_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ��������
							set @rp_ = null
							set @jsT = (select @dish_id_i as [dish_id],
											   @ingredient_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.ingredient_create.duplicate'
									set @errdesc = '���������� ��� ����������'

									goto err
								end

		
							--��������� �������� � �������
							set @ingredient_id = newid()
							insert into [dbo].[ingredients] ([id], [dish_id], [name])
							values (@ingredient_id,
									@dish_id_i,
									@ingredient_name)
		
							--�������
							set @rp = (select @ingredient_id as [id],
											  @dish_id_i as [dish_id],
											  @ingredient_name as [name]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('ingredient.edit')
						begin

							--�������� �� ������� id
							if (@ingredient_id is null)
								begin
									set @err = 'err.ingredient_edit.unset_field'
									set @errdesc = '���������� �� ������'

									goto err
								end

							--�������� �� ������� ������������� ����������
							if (@ingredient_name is null)
								begin
									set @err = 'err.ingredient_edit.hasnt_data'
									set @errdesc = '����������� ������ ��������������'

									goto err
								end

							--�������� �� ������������ �����
							if (@ingredient_name like '%[0-9]%')
								begin
									set @err = 'err.ingredient_edit.invalid_name'
									set @errdesc = '��� �����������'

									goto err
								end


							set @rp_ = null
							set @jsT = (select @ingredient_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							set @dish_id_i = json_value(@rp_, '$.response[0].dish_id')


							--�������� �� ������������� ����������� � ����� id
							if (@dish_id_i is null)
								begin
									set @err = 'err.ingredient_edit.ingredient_not_found'
									set @errdesc = '���������� �� ������'

									goto err
								end

							--�������� �� ��������
							set @rp_ = null
							set @jsT = (select @dish_id_i as [dish_id],
											   @ingredient_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.ingredient_edit.duplicate'
									set @errdesc = '���������� ��� ����������'

									goto err
								end

							--�������� ����������
							update [dbo].[ingredients] 
							set [name] = isnull(@ingredient_name, [name])
							where [id] = @ingredient_id
		
							--�������
							set @rp = (select * from [dbo].ingredients
									   where [id] = @ingredient_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('ingredient.deactive')
						begin

							--�������� �� ������� id
							if (@ingredient_id is null)
								begin
									set @err = 'err.ingredient_deactive.unset_field'
									set @errdesc = '���������� �� ������'

									goto err
								end


							select @ingredient_status = [status]
							from [dbo].[ingredients] 
							where [id] = @ingredient_id

			
							--�������� �� ������������� ����������� � ����� id
							if (@ingredient_status is null)
								begin
									set @err = 'err.ingredient_deactive.ingredient_not_found'
									set @errdesc = '���������� � ����� id �� ������'

									goto err
								end

							--�������� ������� �������
							if (@ingredient_status = 'N')
								begin
									set @err = 'err.ingredient_deactive.ingredient_already_deactive'
									set @errdesc = '���������� ��� �������������'

									goto err
								end

							--������������ ����������
							update [dbo].[ingredients] 
							set [status] = 'N'
							where [id] = @ingredient_id


							--�������
							set @rp = (select @ingredient_id as [id],
											  'N' as [status]
									   for json path, without_array_wrapper)
			
							goto ok

						end


					if @action in ('ingredient.active')
						begin

							--�������� �� ������� id
							if (@ingredient_id is null)
								begin
									set @err = 'err.ingredient_active.unset_field'
									set @errdesc = '���������� �� ������'

									goto err
								end

							select @ingredient_status = [status],
								   @ingredient_name = [name],
								   @dish_id_i = [dish_id]
							from [ingredients]
							where [id] = @ingredient_id

							--�������� �� ������������� ����������� � ����� id
							if (@ingredient_status is null)
								begin
									set @err = 'err.ingredient_active.ingredient_not_found'
									set @errdesc = '���������� �� ������'

									goto err
								end

							--�������� �� �������� ������
							if (@ingredient_status = 'Y')
								begin
									set @err = 'err.ingredient_active.ingredient_already_active'
									set @errdesc = '���������� ��� �������'

									goto err
								end

							--�������� �� ������������� �����
							set @rp_ = null
							set @jsT = (select @dish_id_i as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.ingredient_active.dish_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ��������
							set @rp_ = null
							set @jsT = (select @dish_id_i as [dish_id],
											   @ingredient_name as [name]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'ingredient.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.ingredient_active.ingredient_already_exist'
									set @errdesc = '���������� ��� ����������'

									goto err
								end

							--������ ������
							update [dbo].[ingredients] 
							set [status] = 'Y'
							where [id] = @ingredient_id

							--�������
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

							--�������� ������������ ���������� �� null
							if (@dish_id_dt is null
								or @diet_id_dt is null)
								begin
									set @err = 'err.dish_type_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������� ����� � ����� id
							set @rp_ = null
							set @jsT = (select @dish_id_dt as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.dish_type_create.dish_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ������������� �����
							set @rp_ = null
							set @jsT = (select @diet_id_dt as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.dish_type_create.diet_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end


							--�������� �� ������������ �����
							set @rp_ = null
							set @jsT = (select @dish_id_dt as [dish_id],
											   @diet_id_dt as [diet_id]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'dish_type.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.dish_type_create.relation_already_exist'
									set @errdesc = '����� ����� - ����� ��� ����������'

									goto err
								end

		
							--��������� �������� � �������
							set @dish_type_id = newid()
							insert into [dbo].[dish_type] ([id], [dish_id], [diet_id])
							values (@dish_type_id,
									@dish_id_dt,
									@diet_id_dt)
		
							--�������
							set @rp = (select @dish_type_id as [id],
											  @dish_id_dt as [dish_id],
											  @diet_id_dt as [diet_id]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('dish_type.deactive')
						begin

							declare @dish_type_status char(1)

							--�������� �� ������� id
							if (@dish_type_id is null)
								begin
									set @err = 'err.dish_type_deactive.unset_field'
									set @errdesc = '����� ����� - ����� �� �������'

									goto err
								end


							select @dish_type_status = [status]
							from [dbo].[dish_type] 
							where [id] = @dish_type_id

			
							--�������� �� ������������� ����� � ����� id
							if (@dish_type_status is null)
								begin
									set @err = 'err.dish_type_deactive.relation_not_found'
									set @errdesc = '����� ����� - ����� �� �������'

									goto err
								end

							--�������� ������� �����
							if (@dish_type_status = 'N')
								begin
									set @err = 'err.dish_type_deactive.relation_already_deactive'
									set @errdesc = '����� ����� - ����� ��� ��������������'

									goto err
								end

							--�������� �����
							update [dbo].[dish_type] 
							set [status] = 'N'
							where [id] = @dish_type_id and [status] = 'Y'


							--�������
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

							--�������� ������������ ���������� �� null
							if (@restaurant_name is null
								or @address is null
								or @restaurant_phone is null
								or @restaurant_email is null
								or @work_start is null
								or @work_end is null)
								begin
									set @err = 'err.restaurant_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@restaurant_name like '%[0-9]%')
								begin
									set @err = 'err.restaurant_create.invalid_name'
									set @errdesc = '�������� �����������'

									goto err
								end

							--�������� �� ������������ ������
							if (@address not like '%[^0-9]%' or len(@address) < 2)
								begin
									set @err = 'err.restaurant_create.invalid_adress'
									set @errdesc = '����� �����������'

									goto err
								end


							--�������� �� ������������ phone	
							if (@restaurant_phone like '%[^0-9]%')
								begin
									set @err = 'err.restaurant_create.invalid_phone'
									set @errdesc = '������������ �������'

									goto err
								end

							--�������� �� ������������ email
							if (@restaurant_email not like '%_@_%._%')
								begin
									set @err = 'err.restaurant_create.invalid_email'
									set @errdesc = '������������ email'

									goto err
								end

							--�������� �� ������������ ������ + �����
							set @rp_ = null
							set @jsT = (select @restaurant_name as [name], @address as [address] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_create.not_unique_address_and_name'
									set @errdesc = '����� �������� ��� ����������'

									goto err
								end

							--�������� �� ������������ ��������
							set @rp_ = null
							set @jsT = (select @restaurant_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_create.not_unique_phone'
									set @errdesc = '�������� c ����� ��������� ��� ����������'

									goto err
								end

							--�������� �� ������������ email
							set @rp_ = null
							set @jsT = (select @restaurant_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_create.not_unique_email'
									set @errdesc = '�������� c ����� email ��� ����������'

									goto err
								end

		
							--��������� �������� � �������
							set @restaurant_id = newid()
							insert into [dbo].[restaurants] ([id], [name], [address], [phone], [email], [work_start], [work_end])
							values (@restaurant_id,
									@restaurant_name,
									@address,
									@restaurant_phone,
									@restaurant_email,
									@work_start,
									@work_end)
		
							--�������
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

							--�������� �� ������� id
							if (@restaurant_id is null)
								begin
									set @err = 'err.restaurant_edit.unset_field'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� �� ������� ������������� ����������
							if (@restaurant_name is null 
								and @address is null
								and @restaurant_phone is null
								and @restaurant_email is null
								and @work_start is null
								and @work_end is null)
								begin
									set @err = 'err.restautant_edit.hasnt_data'
									set @errdesc = '����������� ������ ��������������'

									goto err
								end

							--�������� �� ������������ ��������
							if (@restaurant_name is not null and @restaurant_email like '%[0-9]%')
								begin
									set @err = 'err.restaurant_edit.invalid_name'
									set @errdesc = '�������� �����������'

									goto err
								end

							--�������� �� ������������ ������
							if (@address is not null and @address not like '%[^0-9]%')
								begin
									set @err = 'err.restaurant_edit.invalid_adress'
									set @errdesc = '����� �����������'

									goto err
								end


							--�������� �� ������������ phone	
							if (@restaurant_phone is not null and @restaurant_phone like '%[^0-9]%')
								begin
									set @err = 'err.restaurant_edit.invalid_phone'
									set @errdesc = '������������ �������'

									goto err
								end

							--�������� �� ������������ email
							if (@restaurant_email is not null and @restaurant_email not like '%_@_%._%')
								begin
									set @err = 'err.restaurant_edit.invalid_email'
									set @errdesc = '������������ email'

									goto err
								end

							set @rp_ = null
							set @jsT = (select @restaurant_id as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							set @old_address = json_value(@rp_, '$.response.address')
							set @old_restaurant_name = json_value(@rp_, '$.response.name')

							--�������� �� ������������ ��������� � ����� id
							if @old_address is null
								begin
									set @err = 'err.restaurant_edit.restaurant_not_found'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� �� ������������ ������ + �����
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
											set @errdesc = '����� �������� ��� ����������'

											goto err
										end
								end

							--�������� �� ������������ ��������
							if @restaurant_phone is not null
								begin
									set @rp_ = null
									set @jsT = (select @restaurant_phone as [phone] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
										begin
											set @err = 'err.restaurant_edit.not_unique_phone'
											set @errdesc = '�������� c ����� ��������� ��� ����������'

											goto err
										end
								end

							--�������� �� ������������ email
							if @restaurant_email is not null
								begin
									set @rp_ = null
									set @jsT = (select @restaurant_email as [email] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is not null
										begin
											set @err = 'err.restaurant_edit.not_unique_email'
											set @errdesc = '�������� c ����� email ��� ����������'

											goto err
										end
								end

							--�������� ��������
							update [dbo].[restaurants] 
							set [name] = isnull(@restaurant_name, [name]),
								[address] = isnull(@address, [address]),
								[phone] = isnull(@restaurant_phone, [phone]),
								[email] = isnull(@restaurant_email, [email]),
								[work_start] = isnull(@work_start, [work_start]),
								[work_end] = isnull(@work_end, [work_end])
							where [id] = @restaurant_id
		
							--�������
							set @rp = (select * from [dbo].[restaurants]
									   where [id] = @restaurant_id
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('restaurant.deactive')
						begin

							--�������� �� ������� id
							if (@restaurant_id is null)
								begin
									set @err = 'err.restaurant_deactive.unset_field'
									set @errdesc = '�������� �� ������'

									goto err
								end


							select @restaurant_status = [status]
							from [dbo].[restaurants] 
							where [id] = @restaurant_id

			
							--�������� �� ������������� ��������� � ����� id
							if (@restaurant_status is null)
								begin
									set @err = 'err.restaurant_deactive.object_not_found'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� ������� �������
							if (@restaurant_status = 'N')
								begin
									set @err = 'err.restaurant_deactive.restaurant_already_deactive'
									set @errdesc = '�������� ��� �������������'

									goto err
								end

							--�������� �������� ������
							if exists (select top 1 1
									   from [dbo].[table_bookings] as [tb]
									   join [dbo].[tables] as [t] on [tb].[table_id] = [t].[id]
									   where [t].[restaurant_id] = @restaurant_id and [tb].[status] = 'Y' and [t].[status] = 'Y')
								begin
									set @err = 'err.restaurant_deactive.restaurant_has_bookings'
									set @errdesc = '� ��������� ���� �������� �����'

									goto err
								end

							begin transaction

								--������������ ��������
								update [dbo].[restaurants]
								set [status] = 'N'
								where [id] = @restaurant_id

								--������������ ��� �����
								update dt
								set [status] = 'N'
								from [dbo].[dish_type] dt
								left join [dbo].[dishes] dsh on dsh.[id] = dt.[dish_id] 
								where dsh.[restaurant_id] = @restaurant_id and dt.[status] = 'Y'

								update [dbo].[dishes]
								set [status] = 'N'
								where [restaurant_id] = @restaurant_id and [status] = 'Y'

								--������������ ����� + �������
								update tb
								set [status] = 'N'
								from [dbo].[tables] t
								left join [dbo].[table_bookings] tb on tb.[table_id] = t.[id]
								where t.[restaurant_id] = @restaurant_id and tb.[status] = 'Y'

								update [dbo].[tables]
								set [status] = 'N'
								where [restaurant_id] = @restaurant_id and [status] = 'Y'

							commit transaction

								--�������
								set @rp = (select @restaurant_id as [id],
												  'N' as [status]
										   for json path, without_array_wrapper)
			
								goto ok

						end


					if @action in ('restaurant.active')
						begin

							--�������� �� ������� id
							if (@restaurant_id is null)
								begin
									set @err = 'err.restaurant_active.unset_field'
									set @errdesc = '�������� �� ������'

									goto err
								end

							select @restaurant_status = [status],
								   @restaurant_name = [name],
								   @address = [address],
								   @restaurant_phone = [phone],
								   @restaurant_email = [email]
							from [restaurants]
							where [id] = @restaurant_id

							--�������� �� ������������� ��������� � ����� id
							if (@restaurant_status is null)
								begin
									set @err = 'err.restaurant_active.restaurant_not_found'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� �� �������� ������
							if (@restaurant_status = 'Y')
								begin
									set @err = 'err.restaurant_active.restaurant_already_active'
									set @errdesc = '�������� ��� �������'

									goto err
								end

							--�������� �� ������������ ��������
							set @rp_ = null
							set @jsT = (select @restaurant_name as [name], @address as [address] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_active.not_unique_name_and_address'
									set @errdesc = '����� �������� ��� ����������'

									goto err
								end

							--�������� �� ������� �������
							set @rp_ = null
							set @jsT = (select @restaurant_phone as [phone] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_active.not_unique_phone'
									set @errdesc = '������� ��� ������������'

									goto err
								end

							--�������� �� ������� email
							set @rp_ = null
							set @jsT = (select @restaurant_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is not null
								begin
									set @err = 'err.restaurant_active.not_unique_email'
									set @errdesc = 'Email ��� ������������'

									goto err
								end

							--������ ������
							update [dbo].[restaurants] 
							set [status] = 'Y'
							where [id] = @restaurant_id

							--�������
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

							--�������� ������������ ���������� �� null
							if (@restaurant_id_t is null
								or @capacity is null
								or @number is null)
								begin
									set @err = 'err.table_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ �����������
							if (@capacity < 0 or @capacity > 30)
								begin
									set @err = 'err.table_create.invalid_capacity'
									set @errdesc = '����������� �����������'

									goto err
								end

							--�������� �� ������������ ������ �������
							if (@number < 0 or @number > 100)
								begin
									set @err = 'err.table_create.invalid_number'
									set @errdesc = '������������ ����� �������'

									goto err
								end

							--�������� �� ������������� ���������
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_create.restaurant_not_found'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� �� ��������� ������ �������
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [restaurant_id],
											   @number as [number]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.table_create.number_already_exist'
									set @errdesc = '����� ������� �����'

									goto err
								end

		
							--��������� �������� � �������
							set @table_id = newid()

							insert into [dbo].[tables] ([id], [restaurant_id], [number], [capacity])
							values (@table_id,
									@restaurant_id_t,
									@number,
									@capacity)

							--�������
							set @rp = (select @table_id as [id],
											  @restaurant_id_t as [restaurant_id],
											  @number as [number],
											  @capacity as [capacity]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table.deactive')
						begin

							--�������� �� ������� id
							if (@table_id is null)
								begin
									set @err = 'err.table_deactive.unset_field'
									set @errdesc = '������ �� ������'

									goto err
								end


							select @table_status = [status],
								   @restaurant_id_t = [restaurant_id]
							from [dbo].[tables] 
							where [id] = @table_id

			
							--�������� �� ������������� ������� � ����� id
							if (@table_status is null)
								begin
									set @err = 'err.table_deactive.table_not_found'
									set @errdesc = '������ �� ������'

									goto err
								end

							--�������� ������� �������
							if (@table_status = 'N')
								begin
									set @err = 'err.table_deactive.table_already_deactive'
									set @errdesc = '������ ��� �������������'

									goto err
								end

							--��������� �� �������� �����
							set @rp_ = null
							set @jsT = (select @table_id as [table_id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table_booking.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.table_deactive.active_bookings_exists'
									set @errdesc = '� ������� ���� �������� �����'

									goto err
								end

							--������������ ������
							update [dbo].[tables]
							set [status] = 'N'
							where [id] = @table_id

							--�������
							set @rp = (select @table_id as [id],
												'N' as [status]
										for json path, without_array_wrapper)
			
							goto ok

						end


					if @action in ('table.active')
						begin

							--�������� �� ������� id
							if (@table_id is null)
								begin
									set @err = 'err.table_active.unset_field'
									set @errdesc = '������ �� ������'

									goto err
								end


							select @table_status = [status],
								   @restaurant_id_t = [restaurant_id],
								   @number = [number]
							from [dbo].[tables]
							where [id] = @table_id

							--�������� �� ������������� ������� � ����� id
							if (@table_status is null)
								begin
									set @err = 'err.table_active.table_not_found'
									set @errdesc = '������ �� ������'

									goto err
								end

							--�������� �� �������� ������
							if (@table_status = 'Y')
								begin
									set @err = 'err.table_active.table_already_active'
									set @errdesc = '������ ��� �������'

									goto err
								end

							--�������� �� ������������� ��������� c ����� id
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_active.restaurant_not_found'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� �� ��������� ������ �������
							set @rp_ = null
							set @jsT = (select @restaurant_id_t as [restaurant_id],
											   @number as [number]
										for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response[0].id') is not null
								begin
									set @err = 'err.table_active.number_already_exist'
									set @errdesc = '����� ������� �����'

									goto err
								end

							--������ ������
							update [dbo].[tables] 
							set [status] = 'Y'
							where [id] = @table_id

							--�������
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

							--�������� ������������ ���������� �� null
							if (@table_id_tb is null
								or @date is null
								or @start_time is null
								or @end_time is null
								or @guests_count is null)
								begin
									set @err = 'err.table_booking_create.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ ����
							if (@date < cast(getdate() as date))
								begin
									set @err = 'err.tabel_booking_create.invalid_date'
									set @errdesc = '������������ ����'

									goto err
								end

							--�������� �� ������������ �������
							if (@start_time > @end_time)
								begin
									set @err = 'err.tabel_booking_create.invalid_time'
									set @errdesc = '������������ �����'

									goto err
								end

							--�������� �� ������������ �������
							if @table_booking_status is not null and @table_booking_status not in ('wait_conf', 'confirm', 'cancel', 'success')
								begin
									set @err = 'err.tabel_booking_create.invalid_status'
									set @errdesc = '������������ ������'

									goto err
								end


							set @rp_ = null
							set @jsT = (select @table_id_tb as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'table.get', @jsT, @rp_ out

							set @capacity_tb = json_value(@rp_, '$.response[0].capacity')


							--�������� �� ������������ �������
							if (@capacity_tb is null)
								begin
									set @err = 'err.table_booking_create.table_not_found'
									set @errdesc = '������ �� ������'

									goto err
								end

							--�������� �� ������������ ����� ������
							if (@guests_count < 1 or @guests_count > @capacity_tb)
								begin
									set @err = 'err.table_booking_create.invalid_guests_count'
									set @errdesc = '������������ ����������� = ' + cast(@capacity_tb as nvarchar(3))

									goto err
								end

							--�������� �� ������������ �������
							if @client_id_tb is not null
								begin
									set @rp_ = null
									set @jsT = (select @client_id_tb as [id] for json path, without_array_wrapper)
									exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

									if json_value(@rp_, '$.response.id') is null
										begin
											set @err = 'err.table_booking_create.client_not_found'
											set @errdesc = '������ �� ������'

											goto err
										end
								end

							--�������� �������, ��� ��� �������� � ������� ����
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
									set @errdesc = '��������� ����� �� ������������� ������ ������'

									goto err
								end

							--�������� �� ��������� �������
							if exists (select top 1 1
										from [dbo].[table_bookings]
										where [table_id] = @table_id_tb
											and [date] = @date
											and (([start_time] between @start_time and @end_time) or ([end_time] between @start_time and @end_time))
											and [status] in ('wait_conf', 'confirm'))
								begin
									set @err = 'err.table_booking_create.table_is_occupied'
									set @errdesc = '������ ����� � ��������� �����'

									goto err
								end

		
							--��������� �������� � �������
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
		
							--�������
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

							--�������� �� ������� id
							if (@table_booking_id is null)
								begin
									set @err = 'err.table_booking_confirm.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end

							select @table_booking_status = [status]
							from [dbo].[table_bookings] 
							where [id] = @table_booking_id

							--�������� �� ������������� ����� � ����� id
							if @table_booking_status is null
								begin
									set @err = 'err.table_booking_confirm.table_booking_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end


							--�������� �� ������ 
							if @table_booking_status in ('cancel', 'success')
								begin
									set @err = 'err.table_booking_confirm.booking_ended'
									set @errdesc = '����� �����������'

									goto err
								end

							--�������� �� ������ 
							if @table_booking_status = 'confirm'
								begin
									set @err = 'err.table_booking_confirm.booking_already_confirm'
									set @errdesc = '����� ��� ������������'

									goto err
								end	

							--�������� �����
							update [dbo].[table_bookings] 
							set [status] = 'confirm'
							where [id] = @table_booking_id
		
							--�������
							set @rp = (select @table_booking_id as [id],
											  'confirm' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.cancel')
						begin

							--�������� �� ������� id
							if (@table_booking_id is null)
								begin
									set @err = 'err.table_booking_cancel.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end

							select @table_booking_status = [status]
							from [dbo].[table_bookings] 
							where [id] = @table_booking_id

							--�������� �� ������������� ����� � ����� id
							if @table_booking_status is null
								begin
									set @err = 'err.table_booking_cancel.table_booking_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end


							--�������� �� ������ 
							if @table_booking_status in ('cancel', 'success')
								begin
									set @err = 'err.table_booking_cancel.booking_ended'
									set @errdesc = '����� ��� �����������'

									goto err
								end	

	

							--�������� �����
							update [dbo].[table_bookings] 
							set [status] = 'cancel'
							where [id] = @table_booking_id
		
							--�������
							set @rp = (select @table_booking_id as [id],
											  'cancel' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.success')
						begin

							--�������� �� ������� id
							if (@table_booking_id is null)
								begin
									set @err = 'err.table_booking_success.unset_field'
									set @errdesc = '����� �� �������'

									goto err
								end

							select @table_booking_status = [status]
							from [dbo].[table_bookings] 
							where [id] = @table_booking_id

							--�������� �� ������������� ����� � ����� id
							if @table_booking_status is null
								begin
									set @err = 'err.table_booking_success.table_booking_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ������ 
							if @table_booking_status = 'wait_conf'
								begin
									set @err = 'err.table_booking_success.booking_not_confirm'
									set @errdesc = '����� �� ������������'

									goto err
								end	

							--�������� �� ������ 
							if @table_booking_status = 'cancel'
								begin
									set @err = 'err.table_booking_success.booking_canceled'
									set @errdesc = '����� ��������'

									goto err
								end	

							--�������� �� ������ 
							if @table_booking_status = 'success'
								begin
									set @err = 'err.table_booking_success.booking_already_success'
									set @errdesc = '����� ��� �����������'

									goto err
								end	

	

							--�������� �����
							update [dbo].[table_bookings] 
							set [status] = 'success'
							where [id] = @table_booking_id
		
							--�������
							set @rp = (select @table_booking_id as [id],
											  'success' as [status]
									   for json path, without_array_wrapper)

							goto ok

						end


					if @action in ('table_booking.search_free_table')
						begin

							--�������� �� ������� id
							if (@restaurant_id_tb is null)
								begin
									set @err = 'err.table_booking_search_free_table.unset_field'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� ������������ ���������� �� null
							if (@date is null
								or @start_time is null
								or @end_time is null
								or @guests_count is null)
								begin
									set @err = 'err.table_booking_search_free_table.hasnt_data'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--�������� �� ������������ ����
							if (@date < cast(getdate() as date))
								begin
									set @err = 'err.tabel_booking_search_free_tables.invalid_date'
									set @errdesc = '������������ ����'

									goto err
								end

							--�������� �� ������������ �������
							if (@start_time > @end_time)
								begin
									set @err = 'err.tabel_booking_create.invalid_time'
									set @errdesc = '������������ �����'

									goto err
								end

							--�������� �� ������������ ����� ������
							if (@guests_count < 1 or @guests_count > 30)
								begin
									set @err = 'err.table_booking_search_free_table.invalid_guests_count'
									set @errdesc = '������������ ����� ������'

									goto err
								end

							--�������� �� ������������� ���������
							set @rp_ = null
							set @jsT = (select @restaurant_id_tb as [id] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'restaurant.get', @jsT, @rp_ out

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_booking_search_free_table.restaurant_not_found'
									set @errdesc = '�������� �� ������'

									goto err
								end

							--�������� ������������ �������, ��� ��� �������� � ������� ����
							if not exists (select top 1 1
										   from [dbo].[restaurants]
										   where [id] = @restaurant_id_tb
												and (@start_time between [work_start] and [work_end])
												and (@end_time between [work_start] and [work_end])
												and [status] = 'Y')
								begin
									set @err = 'err.table_booking_search_free_table.invalid_time'
									set @errdesc = '��������� ����� �� ������������� ������ ������'

									goto err
								end
		
							--�������
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

							--�������� ������������ ���������� �� null
							if (@restaurant_id_tb is null
								or @start_time is null
								or @end_time is null
								or @guests_count is null)
								begin
									set @err = 'err.table_booking_seat_now.unset_field'
									set @errdesc = '������� �� ��� ����������� ���������'

									goto err
								end

							--���� ������
							set @rp_ = null
							set @jsT = (select @restaurant_id_tb as [restaurant_id],
											   @date as [date],
											   @start_time as [start_time],
											   @end_time as [end_time],
											   @guests_count as [guests_count]
										for json path, without_array_wrapper)

							exec [dbo].[ms_api] 'table_booking.search_free_table', @jsT, @rp_ out

							--�������� �� ������ �� ��������� ���������
							if json_value(@rp_, '$.status') = 'err'
								begin
									set @err = json_value(@rp_, '$.err')
									set @errdesc = json_value(@rp_, '$.errdesc')

									goto err
								end

							if json_value(@rp_, '$.response.id') is null
								begin
									set @err = 'err.table_booking_seat_now.table_not_found'
									set @errdesc = '��������� �������� ���'

									goto err
								end
							else
								begin

									--������� �����
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

									--�������� �� ������ �� ��������� ���������
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