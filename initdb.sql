create table [clients]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[firstname] nvarchar(20) not null check([firstname] <> ''),
	[lastname] nvarchar(20) not null check([lastname] <> ''),
	[email] nvarchar(64) null unique check([email] <> ''),
	[phone] nvarchar(11) not null unique check([phone] <> ''),
	[dob] date null,
	[status] char(1) default 'Y'
)
go
create table [diets]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[name] nvarchar(25) not null unique check([name] <> ''),
	[description] nvarchar(150) null check([description] <> ''),
	[status] char(1) default 'Y'
)
go
create table [clients_diet]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[client_id] uniqueidentifier not null references [clients]([id]),
	[diet_id] uniqueidentifier not null references [diets]([id]),
	[status] char(1) default 'Y',
	unique([client_id], [diet_id])
)
go
create table [restaurants]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[name] nvarchar(25) not null check([name] <> ''),
	[address] nvarchar(50) not null check([address] <> ''),
	[email] nvarchar(64) not null unique check([email] <> ''),
	[phone] nvarchar(11) not null unique check([phone] <> ''),
	[work_start] time not null,
	[work_end] time not null,
	[status] char(1) default 'Y',
	unique([name], [address])
)
go 
create table [dishes]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[name] nvarchar(20) not null check([name] <> ''),
	[restaurant_id] uniqueidentifier not null references [restaurants]([id]),
	[description] nvarchar(150)  null check([description] <> ''),
	[price] decimal(7,2) not null check([price] > 0),
	[calories] int null check([calories] > 0),
	[status] char(1) default 'Y',
	unique([name], [restaurant_id])
)
go
create table [ingredients]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[dish_id] uniqueidentifier not null references [dishes]([id]),
	[name] nvarchar(30) not null check([name] <> ''),
	[status] char(1) default 'Y',
	unique([name], [dish_id])
)
go
create table [tables]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[restaurant_id] uniqueidentifier not null references [restaurants]([id]),
	[number] int not null check([number] > 0),
	[capacity] int not null check([capacity] > 1 and [capacity]<30),
	[status] char(1) default 'Y',
	unique([restaurant_id], [number])
)
go
create table [dish_type]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[dish_id] uniqueidentifier not null references [dishes]([id]),
	[diet_id] uniqueidentifier not null references [diets]([id]),
	[status] char(1) default 'Y',
	unique([dish_id], [diet_id])
)
go
create table [table_bookings]
(
	[id] uniqueidentifier primary key default newid(),
	[dadd] datetime default getdate(),
	[client_id] uniqueidentifier references [clients]([id]),
	[table_id] uniqueidentifier references [tables]([id]),
	[date] date not null,
	[start_time] time not null,
	[end_time] time not null,
	[guests_count] int not null default 2 check([guests_count] > 1 and [guests_count]<10000),
	[status] char(10) default 'created'
)