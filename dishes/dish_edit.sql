use myservice
go

create procedure [dbo].[dish_edit] (@js nvarchar(max),
									@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@name nvarchar(20) = json_value(@js, '$.name'),
					@restaurant_id uniqueidentifier,
					@description nvarchar(150) = json_value(@js, '$.description'),
					@price decimal(7,2) = json_value(@js, '$.price'),
					@calories int = json_value(@js, '$.calories')

			--�������� �� ������� id
			if (@id is null)
				begin
					set @err = 'err.dish_edit.unset_field'
					set @errdesc = '�� ������ id'

					goto err
				end

			--�������� �� ������� ������������� ����������
			if (@name is null 
				and @description is null
				and @price is null
				and @calories is null)
				begin
					set @err = 'err.dish_edit.hasnt_data'
					set @errdesc = '����������� ������ ��������������'

					goto err
				end

			--�������� �� ������������ �����
			if (@name is not null
				and @name like '%[0-9]%')
				begin
					set @err = 'err.dish_edit.invalid_name'
					set @errdesc = '��� �����������'

					goto err
				end

			--�������� �� ������������ ��������
			if (@description is not null 
				and @description not like '%[^0-9]%')
				begin
					set @err = 'err.dish_edit.invalid_description'
					set @errdesc = '������������ ��������'

					goto err
				end


			--�������� �� ������������ ����	
			if (@price < 0
				and @price is not null
				and isnumeric(@price) = 0)
				begin
					set @err = 'err.dish_edit.invalid_price'
					set @errdesc = '������������ ����'

					goto err
				end

			--�������� �� ������������ ��������
			if (@calories is not null
				and @calories < 0)
				begin
					set @err = 'err.dish_edit.invalid_calories'
					set @errdesc = '������������ �������'

					goto err
				end


			select @restaurant_id = [restaurant_id] 
			from [dbo].[dishes] 
			where [id] = @id
				and [status] = 'Y'


			--�������� �� ������������ ����� � ����� id
			if (@restaurant_id is null)
				begin
					set @err = 'err.dish_edit.object_not_found'
					set @errdesc = '����� � ����� id �� �������'

					goto err
				end

			--�������� �� �������� ����� � ���������
			if exists (select 1 
					   from [dbo].[dishes] 
					   where [restaurant_id] = @restaurant_id
							and [name] = @name
							and [id] <> @id
							and [status] = 'Y')
				begin
					set @err = 'err.dish_edit.duplicate'
					set @errdesc = '����� ����� ��� ����������'

					goto err
				end

			--�������� �����
			update [dbo].[dishes] 
			set [name] = isnull(@name, [name]),
				[description] = isnull(@description, [description]),
				[price] = isnull(@price, [price]),
				[calories] = isnull(@calories, [calories])
			where [id] = @id
		
			--�������
			set @rp = (select @id as [id],
							  @name as [name],
							  @restaurant_id as [restaurant_id],
							  @description as [description],
							  @price as [price],
							  @calories as [calories]
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