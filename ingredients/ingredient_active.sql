use myservice
go

create procedure [dbo].[ingredient_active] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@dish_id uniqueidentifier,
					@name nvarchar(30),
					@status char(1)

			--�������� �� ������� id
			if (@id is null)
				begin
					set @err = 'err.ingredient_active.unset_field'
					set @errdesc = '�� ������ id'

					goto err
				end

			select @status = [status],
				   @name = [name],
				   @dish_id = [dish_id]
			from [ingredients]
			where [id] = @id

			--�������� �� ������������� ����������� � ����� id
			if (@status is null)
				begin
					set @err = 'err.ingredient_active.ingredient_not_found'
					set @errdesc = '���������� � ����� id �� ������'

					goto err
				end

			--�������� �� �������� ������
			if (@status = 'Y')
				begin
					set @err = 'err.ingredient_active.ingredient_already_active'
					set @errdesc = '���������� ��� �������'

					goto err
				end

			--�������� �� ��������
			if (exists (select 1 
						from [dbo].[ingredients] 
						where [name] = @name
							and [dish_id] = @dish_id
							and [status] = 'Y'))
				begin
					set @err = 'err.ingredient_active.ingredient_already_exist'
					set @errdesc = '���������� ��� ����������'

					goto err
				end

			--������ ������
			update [dbo].[ingredients] 
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