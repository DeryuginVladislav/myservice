use myservice
go

create procedure [dbo].[ingredient_deactive] (@js nvarchar(max),
											  @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@status char(1)

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.ingredient_deactive.unset_field'
					set @errdesc = 'Ќе указан id'

					goto err
				end


			select @status = [status]
			from [dbo].[ingredients] 
			where [id] = @id

			
			--проверка на существование ингредиента с таким id
			if (@status is null)
				begin
					set @err = 'err.ingredient_deactive.ingredient_not_found'
					set @errdesc = '»нгредиент с таким id не найден'

					goto err
				end

			--проверка статуса клиента
			if (@status = 'N')
				begin
					set @err = 'err.ingredient_deactive.ingredient_already_deactive'
					set @errdesc = '»нгредиент уже деактивирован'

					goto err
				end

			--деактивируем ингредиент
			update [dbo].[ingredients] 
			set [status] = 'N'
			where [id] = @id and [status] = 'Y'


			--выводим
			set @rp = (select @id as [id],
							  'N' as [status]
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