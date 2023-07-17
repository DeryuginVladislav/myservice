use myservice
go

create procedure [dbo].[ingredient.deactive] (@js nvarchar(max),
											  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@ingredient_id	uniqueidentifier = json_value(@js, '$.id'),
					@ingredient_status char(1)

			--проверка на наличие id
			if (@ingredient_id is null)
				begin
					set @err = 'err.ingredient_deactive.unset_field'
					set @errdesc = 'Ингредиент не найден'

					goto err
				end


			select @ingredient_status = [status]
			from [dbo].[ingredients] 
			where [id] = @ingredient_id

			
			--проверка на существование ингредиента с таким id
			if (@ingredient_status is null)
				begin
					set @err = 'err.ingredient_deactive.ingredient_not_found'
					set @errdesc = 'Ингредиент с таким id не найден'

					goto err
				end

			--проверка статуса клиента
			if (@ingredient_status = 'N')
				begin
					set @err = 'err.ingredient_deactive.ingredient_already_deactive'
					set @errdesc = 'Ингредиент уже деактивирован'

					goto err
				end

			--деактивируем ингредиент
			update [dbo].[ingredients] 
			set [status] = 'N'
			where [id] = @ingredient_id


			--выводим
			set @rp = (select @ingredient_id as [id],
							  'N' as [status]
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