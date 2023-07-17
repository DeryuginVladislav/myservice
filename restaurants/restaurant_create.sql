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

			--�������� ������������ ���������� �� null
			if (@name is null
				or @address is null
				or @phone is null
				or @email is null
				or @work_start is null
				or @work_end is null)
				begin
					set @err = 'err.restaurant_create.unset_field'
					set @errdesc = '������� �� ��� ����������� ���������'

					goto err
				end

			--�������� �� ������������ �����
			if (@name like '%[0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_name'
					set @errdesc = '��� �����������'

					goto err
				end

			--�������� �� ������������ ������
			if (@address not like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_adress'
					set @errdesc = '����� �����������'

					goto err
				end


			--�������� �� ������������ phone	
			if (@phone like '%[^0-9]%')
				begin
					set @err = 'err.restaurant_create.invalid_phone'
					set @errdesc = '������������ �������'

					goto err
				end

			--�������� �� ������������ email
			if (@email not like '%_@_%._%')
				begin
					set @err = 'err.restaurant_create.invalid_email'
					set @errdesc = '������������ email'

					goto err
				end

			--�������� �� ������������ ����� ������
			if (try_convert(time, @work_start) is null or try_convert(time, @work_end) is null)
				begin
					set @err = 'err.restaurant_create.invalid_time'
					set @errdesc = '������������ �����'

					goto err
				end

			--�������� �� ������������ ������ + �����
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [address] = @address
							and [name] = @name
							and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_address_and_name'
					set @errdesc = '����� �������� ��� ����������'

					goto err
				end

			--�������� �� ������������ ��������
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [phone] = @phone and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_phone'
					set @errdesc = '�������� c ����� ��������� ��� ����������'

					goto err
				end

			--�������� �� ������������ email
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [email] = @email and [status] = 'Y')
				begin
					set @err = 'err.restaurant_create.not_unique_email'
					set @errdesc = '�������� c ����� email ��� ����������'

					goto err
				end

		
			--��������� �������� � �������
			set @id = newid()
			insert into [dbo].[restaurants] ([id], [name], [address], [phone], [email], [work_start], [work_end])
				values (@id,
						@name,
						@address,
						@phone,
						@email,
						@work_start,
						@work_end)
		
			--�������
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