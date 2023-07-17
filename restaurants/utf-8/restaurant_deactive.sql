use myservice
go

create procedure [dbo].[restaurant.deactive] (@js nvarchar(max),
											  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@restaurant_id	uniqueidentifier = json_value(@js, '$.id'),
					@restaurant_status char(1)

			--проверка на наличие id
			if (@restaurant_id is null)
				begin
					set @err = 'err.restaurant_deactive.unset_field'
					set @errdesc = 'Ресторан не найден'

					goto err
				end


			select @restaurant_status = [status]
			from [dbo].[restaurants] 
			where [id] = @restaurant_id

			
			--проверка на существование ресторана с таким id
			if (@restaurant_status is null)
				begin
					set @err = 'err.restaurant_deactive.object_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка статуса клиента
			if (@restaurant_status = 'N')
				begin
					set @err = 'err.restaurant_deactive.restaurant_already_deactive'
					set @errdesc = 'Ресторан уже деактивирован'

					goto err
				end

			--проверка активных броней
			if exists (select top 1 1
					   from [dbo].[table_bookings] as [tb]
					   join [dbo].[tables] as [t] on [tb].[table_id] = [t].[id]
					   where [t].[restaurant_id] = @restaurant_id and [tb].[status] = 'Y' and [t].[status] = 'Y')
				begin
					set @err = 'err.restaurant_deactive.restaurant_has_bookings'
					set @errdesc = 'У ресторана есть активные брони'

					goto err
				end

			begin transaction

				--деактивируем ресторан
				update [dbo].[restaurants]
				set [status] = 'N'
				where [id] = @restaurant_id

				--деактивируем его блюда
				update dt
				set [status] = 'N'
				from [dbo].[dish_type] dt
				left join [dbo].[dishes] dsh on dsh.[id] = dt.[dish_id] 
				where dsh.[restaurant_id] = @restaurant_id and dt.[status] = 'Y'

				update [dbo].[dishes]
				set [status] = 'N'
				where [restaurant_id] = @restaurant_id and [status] = 'Y'

				--деактивируем брони + столики
				update tb
				set [status] = 'N'
				from [dbo].[tables] t
				left join [dbo].[table_bookings] tb on tb.[table_id] = t.[id]
				where t.[restaurant_id] = @restaurant_id and tb.[status] = 'Y'

				update [dbo].[tables]
				set [status] = 'N'
				where [restaurant_id] = @restaurant_id and [status] = 'Y'

			commit transaction

				--выводим
				set @rp = (select @restaurant_id as [id],
								  'N' as [status]
						   for json path, without_array_wrapper)
			
				goto ok

		end try

		begin catch
			rollback transaction

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