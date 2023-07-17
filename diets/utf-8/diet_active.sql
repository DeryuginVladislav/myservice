use myservice
go

create procedure [dbo].[diet.active] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@diet_id	uniqueidentifier = json_value(@js, '$.id'),
					@diet_status char(1),
					@diet_name nvarchar(25)

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
			if exists (select top 1 1 from [dbo].[diets] where [name] = @diet_name and [status] = 'Y')
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

		end try

		begin catch
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