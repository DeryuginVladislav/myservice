use myservice
go

create procedure [dbo].[ingredient_edit] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@dish_id uniqueidentifier,
					@name nvarchar(30) = json_value(@js, '$.name')

			--�������� �� ������� id
			if (@id is null)
				begin
					set @err = 'err.ingredient_edit.unset_field'
					set @errdesc = '�� ������ id'

					goto err
				end

			--�������� �� ������� ������������� ����������
			if (@name is null)
				begin
					set @err = 'err.ingredient_edit.hasnt_data'
					set @errdesc = '����������� ������ ��������������'

					goto err
				end

			--�������� �� ������������ �����
			if (@name like '%[0-9]%')
				begin
					set @err = 'err.ingredient_edit.invalid_name'
					set @errdesc = '��� �����������'

					goto err
				end


			select @dish_id = [dish_id]
			from [dbo].ingredients
			where [id] = @id
				and [status] = 'Y'


			--�������� �� ������������� ����������� � ����� id
			if (@dish_id is null)
				begin
					set @err = 'err.ingredient_edit.ingredient_not_found'
					set @errdesc = '���������� � ����� id �� ������'

					goto err
				end

			--�������� �� ��������
			if exists (select 1
					  from [dbo].[ingredients]
					  where [dish_id] = @dish_id
						and [name] = @name
						and [status] = 'Y')
				begin
					set @err = 'err.ingredient_edit.duplicate'
					set @errdesc = '���������� ��� ����������'

					goto err
				end

			--�������� �������
			update [dbo].[ingredients] 
			set [name] = isnull(@name, [name])
			where [id] = @id
		
			--�������
			set @rp = (select @id as [id],
							  @dish_id as [dish_id],
							  @name as [name]
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