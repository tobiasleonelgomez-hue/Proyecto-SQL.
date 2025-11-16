use com3900g04
go

create schema maestro
go
create table maestro.medico
(
	Nombre varchar(20),
	Apellido varchar(20),
	especialidad varchar(20),
	numero_colegiado int primary key
)
go
create table maestro.paciente
(
	nombre varchar(50),
	apellido varchar(50),
	fecha_nacimiento varchar(10),
	tipo_documento varchar(10),
	nro_documento int primary key,
	sexo varchar(12),
	genero varchar(12),
	telefono varchar(30),
	nacionalidad varchar(20),
	mail varchar(60),
	calle_y_numero varchar(50),
	localidad varchar(50),
	provincia varchar(20)
)

go
create table maestro.prestador 
(
	prestador varchar(20),
	plan_prestador varchar(30)
)
go

create table maestro.sedes
(
	sede varchar(30) primary key,
	direccion varchar(30),
	localidad varchar(30),
	provincia varchar(30)
)

go
create procedure maestro.insertar_medicos
as
begin
bulk insert com3900g04.maestro.medico
from 'D:\Dataset\Medicos.csv'
with(
	FIELDTERMINATOR = ';',
	ROWTERMINATOR = '\n',
	CODEPAGE = '65001', --UTF-8
	FIRSTROW = 2
	);
end
go
exec maestro.insertar_medicos
go
create procedure maestro.insertar_pacientes
as
begin
bulk insert com3900g04.maestro.paciente
from 'D:\Dataset\Pacientes.csv'
with(
	FIELDTERMINATOR = ';',
	ROWTERMINATOR = '\n',
	CODEPAGE = '65001', --UTF-8
	FIRSTROW = 2
	);
end
go
exec maestro.insertar_pacientes

go
create procedure maestro.insertar_prestadores
as
begin
bulk insert com3900g04.maestro.prestador
from 'D:\Dataset\Prestador.csv'
with(
	FIELDTERMINATOR = ';',
	ROWTERMINATOR = '\n',
	CODEPAGE = '65001', --UTF-8
	FIRSTROW = 2
	);
end
go
exec maestro.insertar_prestadores
go
create procedure maestro.insertar_sedes
as
begin
bulk insert com3900g04.maestro.sedes
from 'D:\Dataset\Sedes.csv'
with(
	FIELDTERMINATOR = ';',
	ROWTERMINATOR = '\n',
	CODEPAGE = '65001', --UTF-8
	FIRSTROW = 2
	);
end
GO
exec maestro.insertar_sedes
