use myservice
go 

create procedure [dbo].[table_create] (@js nvarchar(max),
									   @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier,
					@restaurant_id uniqueidentifier = json_value(@js, '$.restaurant_id'),
					@capacity int = json_value(@js, '$.capacity')

			--проверка обязательных параметров на null
			if (@restaurant_id is null
				or @capacity is null)
				begin
					set @err = 'err.table_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность вместимости
			if (@capacity < 0
				or @capacity > 30)
				begin
					set @err = 'err.table_create.invalid_capacity'
					set @errdesc = 'Вместимость некорректна'

					goto err
				end

			--проверка на существование ресторана
			if not exists (select 1
						   from [dbo].[restaurants]
						   where [id] = @restaurant_id
								and [status] = 'Y')
				begin
					set @err = 'err.table_create.restaurant_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

		
			--добавляем значения в таблицу
			set @id = newid()
			insert into [dbo].[tables] ([id], [restaurant_id], [capacity])
				values (@id,
						@restaurant_id,
						@capacity)
		
			--выводим
			set @rp = (select @id as [id],
							  @restaurant_id as [restaurant_id],
							  @capacity as [capacity]
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