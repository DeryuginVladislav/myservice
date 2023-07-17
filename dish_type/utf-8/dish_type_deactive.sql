use myservice
go

create procedure [dbo].[dish_type.deactive] (@js nvarchar(max),
											 @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@dish_type_id	uniqueidentifier = json_value(@js, '$.id'),
					@dish_type_status char(1)

			--проверка на наличие id
			if (@dish_type_id is null)
				begin
					set @err = 'err.dish_type_deactive.unset_field'
					set @errdesc = 'Связь блюдо - диета не найдена'

					goto err
				end


			select @dish_type_status = [status]
			from [dbo].[dish_type] 
			where [id] = @dish_type_id

			
			--проверка на существование связи с таким id
			if (@dish_type_status is null)
				begin
					set @err = 'err.dish_type_deactive.relation_not_found'
					set @errdesc = 'Связь блюдо - диета не найдена'

					goto err
				end

			--проверка статуса связи
			if (@dish_type_status = 'N')
				begin
					set @err = 'err.dish_type_deactive.relation_already_deactive'
					set @errdesc = 'Связь блюдо - диета уже деактивирована'

					goto err
				end

			--изменяем связь
			update [dbo].[dish_type] 
			set [status] = 'N'
			where [id] = @dish_type_id and [status] = 'Y'


			--выводим
			set @rp = (select @dish_type_id as [id],
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