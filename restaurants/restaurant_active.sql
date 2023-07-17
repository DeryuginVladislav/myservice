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

			--�������� �� ������� id
			if (@id is null)
				begin
					set @err = 'err.restaurant_active.unset_field'
					set @errdesc = '�� ������ id'

					goto err
				end

			select @status = [status],
				   @name = [name],
				   @address = [address],
				   @phone = [phone],
				   @email = [email]
			from [restaurants]
			where [id] = @id

			--�������� �� ������������� ��������� � ����� id
			if (@status is null)
				begin
					set @err = 'err.restaurant_active.restaurant_not_found'
					set @errdesc = '�������� � ����� id �� ������'

					goto err
				end

			--�������� �� �������� ������
			if (@status = 'Y')
				begin
					set @err = 'err.restaurant_active.restaurant_already_active'
					set @errdesc = '�������� ��� �������'

					goto err
				end

			--�������� �� ������������ ��������
			if (exists (select 1 
						from [dbo].[restaurants] 
						where [name] = @name
							and [address] = @address
							and [status] = 'Y'))
				begin
					set @err = 'err.restaurant_active.not_unique_name_and_address'
					set @errdesc = '����� �������� ��� ����������'

					goto err
				end

			--�������� �� ������� �������
			if (exists (select 1 
						from [dbo].[restaurants] 
						where [phone] = @phone
							and [status] = 'Y'))
				begin
					set @err = 'err.restaurant_active.not_unique_phone'
					set @errdesc = '������� ��� ������������'

					goto err
				end

			--�������� �� ������� email
			if (exists (select 1 
							from [dbo].[restaurants] 
							where ([email] = @email)
								and [status] = 'Y'))
				begin
					set @err = 'err.restaurant_active.not_unique_email'
					set @errdesc = 'Email ��� ������������'

					goto err
				end

			--������ ������
			update [dbo].[restaurants] 
			set [status] = 'Y'
			where [id] = @id

			--�������
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