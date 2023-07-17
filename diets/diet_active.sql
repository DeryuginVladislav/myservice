use myservice
go

create procedure [dbo].[diet_active] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@status char(1),
					@name nvarchar(25)

			--�������� �� ������� id
			if (@id is null)
				begin
					set @err = 'err.diet_active.unset_field'
					set @errdesc = '�� ������ id'

					goto err
				end

			select @status = [status],
				   @name = [name]
			from [diets]
			where [id] = @id

			--�������� �� ������������� ����� � ����� id
			if (@status is null)
				begin
					set @err = 'err.diet_active.diet_not_found'
					set @errdesc = '����� � ����� id �� �������'

					goto err
				end

			--�������� �� �������� ������
			if (@status = 'Y')
				begin
					set @err = 'err.diet_active.diet_already_active'
					set @errdesc = '����� ��� �������'

					goto err
				end

			--�������� �� ������� ���
			if (@name is not null and exists (select 1 
											  from [dbo].[diets] 
											  where [name] = @name
												and [status] = 'Y'))
				begin
					set @err = 'err.diet_active.not_unique_name'
					set @errdesc = '����� c ����� ��������� ��� ����������'

					goto err
				end

			--������ ������
			update [dbo].[diets] 
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