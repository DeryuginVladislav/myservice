use myservice
go 

create procedure [dbo].[client_diet_create] (@js nvarchar(max),
											 @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier,
					@client_id uniqueidentifier = json_value(@js, '$.client_id'),
					@diet_id uniqueidentifier = json_value(@js, '$.diet_id')

			--�������� ������������ ���������� �� null
			if (@client_id is null
				or @diet_id is null)
				begin
					set @err = 'err.client_diet_create.unset_field'
					set @errdesc = '������� �� ��� ����������� ���������'

					goto err
				end

			--�������� �� ������������� ������� � ����� id
			if not exists (select 1 
						   from [dbo].[clients] 
						   where [id] = @client_id and [status] = 'Y')
				begin
					set @err = 'err.client_diet_create.client_not_found'
					set @errdesc = '������ � ����� id �� ������'

					goto err
				end

			--�������� �� ������������� �����
			if not exists (select 1 
						   from [dbo].[diets] 
						   where [id] = @diet_id and [status] = 'Y')
				begin
					set @err = 'err.client_diet_create.diet_not_found'
					set @errdesc = '����� � ����� id �� �������'

					goto err
				end


			--�������� �� ������������ �����
			if exists (select 1 
					   from [dbo].[clients_diet] 
					   where [client_id] = @client_id
							and [diet_id] = @diet_id
							and [status] = 'Y')
				begin
					set @err = 'err.client_diet_create.relation_already_exist'
					set @errdesc = '����� ����� ��� ����������'

					goto err
				end

		
			--��������� �������� � �������
			set @id = newid()
			insert into [dbo].[clients_diet] ([id], [client_id], [diet_id])
				values (@id,
						@client_id,
						@diet_id)
		
			--�������
			set @rp = (select @id as [id],
							  @client_id as [client_id],
							  @diet_id as [diet_id]
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