use myservice
go 

create procedure [dbo].[table.create] (@js nvarchar(max),
									   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@table_id	uniqueidentifier,
					@restaurant_id_t uniqueidentifier = json_value(@js, '$.restaurant_id'),
					@number int = json_value(@js, '$.number'),
					@capacity int = json_value(@js, '$.capacity')

			--проверка обязательных параметров на null
			if (@restaurant_id_t is null
				or @capacity is null
				or @number is null)
				begin
					set @err = 'err.table_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность вместимости
			if (@capacity < 0 or @capacity > 30)
				begin
					set @err = 'err.table_create.invalid_capacity'
					set @errdesc = 'Вместимость некорректна'

					goto err
				end

			--проверка на корректность номера столика
			if (@number < 0 or @number > 100)
				begin
					set @err = 'err.table_create.invalid_number'
					set @errdesc = 'Некорректный номер столика'

					goto err
				end

			--проверка на существование ресторана
			if not exists (select top 1 1 from [dbo].[restaurants] where [id] = @restaurant_id_t and [status] = 'Y')
				begin
					set @err = 'err.table_create.restaurant_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка на занятость номера столика
			if exists (select top 1 1 from [dbo].[tables] where [restaurant_id] = @restaurant_id_t and [number] = @number and [status] = 'Y')
				begin
					set @err = 'err.table_create.number_already_exist'
					set @errdesc = 'Номер столика занят'

					goto err
				end

		
			--добавляем значения в таблицу
			set @table_id = newid()

			insert into [dbo].[tables] ([id], [restaurant_id], [number], [capacity])
			values (@table_id,
					@restaurant_id_t,
					@number,
					@capacity)

			--выводим
			set @rp = (select @table_id as [id],
							  @restaurant_id_t as [restaurant_id],
							  @number as [number],
							  @capacity as [capacity]
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