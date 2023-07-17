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

							if json_value(@jsT, '$.response.id') is not null
								begin
									set @err = 'err.client_create.not_unique_phone'
									set @errdesc = '������ c ����� ��������� ��� ����������'

									goto err
								end

							--�������� �� ������������ email
							set @rp_ = null
							set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@jsT, '$.response.id') is not null
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

									if json_value(@jsT, '$.response.id') is not null
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

									if json_value(@jsT, '$.response.id') is not null										
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

							if json_value(@jsT, '$.response.id') is not null
								begin
									set @err = 'err.client_active.not_unique_phone'
									set @errdesc = '��������� ������� ��� ������������'

									goto err
								end

							--�������� �� ������������ email
							set @rp_ = null
							set @jsT = (select @client_email as [email] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'client.get', @jsT, @rp_ out

							if json_value(@jsT, '$.response.id') is not null								
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


			if @sba in ('diets')
				begin

					declare @diet_id	  uniqueidentifier = json_value(@js, '$.id'),
							@diet_name	  nvarchar(25) = json_value(@js, '$.name'),
							@diet_description  nvarchar(150) = json_value(@js, '$.description')

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

							if json_value(@jsT, '$.response.id') is not null
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

							if json_value(@jsT, '$.response.id') is null
								begin
									set @err = 'err.diet_edit.object_not_found'
									set @errdesc = '����� �� �������'

									goto err
								end

							--�������� �� ��� ������������ �������� �����
							set @rp_ = null
							set @jsT = (select @diet_name as [name] for json path, without_array_wrapper)
							exec [dbo].[ms_api] 'diet.get', @jsT, @rp_ out

							if json_value(@jsT, '$.response.id') is not null
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

				end


			if @sba in ('table_booking')
				begin

					declare @table_booking_id	uniqueidentifier
						  , @client_id_tb uniqueidentifier = json_value(@js, '$.client_id')
						  , @table_id_tb uniqueidentifier = json_value(@js, '$.table_id')
						  , @date date = json_value(@js, '$.date')
						  , @start_time time = json_value(@js, '$.start_time')
						  , @end_time time = json_value(@js, '$.end_time')
						  , @guests_count int = json_value(@js, '$.guests_count')
						  , @table_booking_status varchar(10) = json_value(@js, '$.status')

					if @action in ('table_booking.get')
						begin

							set @rp = (select *
									   from [dbo].[table_bookings]
									   where ([id] = @table_booking_id or [client_id] = @client_id_tb) and [status] in ('wait_conf', 'confirm')
									   for json path)
							goto ok

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