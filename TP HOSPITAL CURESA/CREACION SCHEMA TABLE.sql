/* Script creado : 2024-05-27 09:38:20 */


-- Entrega 3
-- Luego de decidirse por un motor de base de datos relacional, llegó el momento de generar la base de
-- datos.
-- Deberá instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle las
-- configuraciones aplicadas (ubicación de archivos, memoria asignada, seguridad, puertos, etc.) en un
-- documento como el que le entregaría al DBA.
-- Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar un
-- archivo .sql con el script completo de creación (debe funcionar si se lo ejecuta “tal cual” es entregado).
-- Incluya comentarios para indicar qué hace cada módulo de código.
-- Genere store procedures para manejar la inserción, modificado, borrado (si corresponde, también
-- debe decidir si determinadas entidades solo admitirán borrado lógico) de cada tabla.
-- Los nombres de los store procedures NO deben comenzar con “SP”.
-- Genere esquemas para organizar de forma lógica los componentes del sistema y aplique esto en la
-- creación de objetos. NO use el esquema “dbo”.
-- El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha de
-- entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
-- Entregar todo en un zip cuyo nombre sea Grupo_XX.zip mediante la sección de prácticas de MIEL.
-- Solo uno de los miembros del grupo debe hacer la entrega.

/* Script para fecha : 2024-05-27 12:38:01 */

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'com3900g04')
BEGIN
    DROP DATABASE com3900g04;
END

CREATE DATABASE com3900g04;

GO

USE com3900g04;

GO

CREATE SCHEMA datos_paciente;

GO

CREATE TABLE datos_paciente.Prestador
( 
    id_prestador INT IDENTITY(1,1) PRIMARY KEY,
    nombre_prestador VARCHAR(20) NOT NULL,
    plan_prestador VARCHAR(20) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL
)
GO

CREATE TABLE datos_paciente.Usuario
(
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    contrasena VARCHAR (20) NOT NULL,
    fecha_creacion DATE DEFAULT GETDATE() NOT NULL,
    activo BIT DEFAULT 1 NOT NULL
)

GO

CREATE TABLE datos_paciente.Paciente
( 
    id_historia_clinica INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(30) NOT NULL,
    apellido_materno VARCHAR(30),
    fecha_nacimiento DATE NOT NULL,
    tipo_documento VARCHAR(3) NOT NULL,
    nro_documento INT NOT NULL,
    sexo_biologico VARCHAR(10) NOT NULL,
    genero VARCHAR(10) NOT NULL,
    nacionalidad VARCHAR(30) NOT NULL,
    foto_perfil VARCHAR(50),
    mail VARCHAR(100) UNIQUE,
    telefono_fijo VARCHAR(30) NOT NULL,
    telefono_alternativo VARCHAR(30),
    telefono_trabajo VARCHAR(30),
    fecha_registro DATE NOT NULL DEFAULT GETDATE(),
    fecha_actualizacion DATE DEFAULT GETDATE() NOT NULL,
    usuario_actualizacion INT NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,
    FOREIGN KEY (usuario_actualizacion) REFERENCES datos_paciente.Usuario(id_usuario)
    ON UPDATE CASCADE
)

GO

CREATE TABLE datos_paciente.Domicilio
( 
    id_domicilio INT IDENTITY(1,1) PRIMARY KEY,
    calle VARCHAR(100) NOT NULL,
    numero NUMERIC(6,0) NOT NULL,
    piso NUMERIC(3,0),
    departamento VARCHAR(3),
    codigo_postal VARCHAR(10) NOT NULL,
    pais VARCHAR(40) NOT NULL,
    provincia VARCHAR(50) NOT NULL,
    localidad VARCHAR(50) NOT NULL,
    id_historia_clinica INT NOT NULL,
    FOREIGN KEY (id_historia_clinica) REFERENCES datos_paciente.Paciente (id_historia_clinica)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
)
ALTER TABLE datos_paciente.Domicilio
add   activo BIT DEFAULT 1 NOT NULL


GO

CREATE TABLE datos_paciente.EstudioRealizado
( 
    id_estudio_realizado INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL,
    nombre_estudio VARCHAR(80) NOT NULL,
    autorizado BIT NOT NULL DEFAULT 0,
    documento_resultado VARCHAR(50),
    imagen_resultado VARCHAR(50),
    id_tipo_estudio INT NOT NULL,
    id_historia_clinica INT NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,
    FOREIGN KEY (id_tipo_estudio) REFERENCES datos_paciente.TipoEstudio(id_tipo_estudio),
    FOREIGN KEY (id_historia_clinica) REFERENCES datos_paciente.Paciente(id_historia_clinica)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
)


GO

CREATE TABLE datos_paciente.Cobertura
(
    id_cobertura INT IDENTITY (1,1) PRIMARY KEY,
    imagen_credencial VARCHAR(50),
    nro_socio NUMERIC (16,0) NOT NULL,
    fecha_registro DATE NOT NULL,
    id_prestador INT NOT NULL,
    id_historia_clinica INT NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,
    FOREIGN KEY (id_prestador) REFERENCES datos_paciente.Prestador(id_prestador)
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
    FOREIGN KEY (id_historia_clinica) REFERENCES datos_paciente.Paciente(id_historia_clinica)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
)

GO

CREATE SCHEMA datos_turno;

GO

CREATE TABLE datos_turno.SedeAtencion
(
    id_sede INT IDENTITY (1,1) PRIMARY KEY,
    nombre_sede VARCHAR(50) NOT NULL,
    direccion_sede VARCHAR(100) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL
)

GO

CREATE TABLE datos_turno.TipoTurno
( 
    id_tipo_turno INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo_turno VARCHAR(10) NOT NULL CHECK (nombre_tipo_turno IN ('Presencial', 'Virtual'))
)
 
GO

CREATE TABLE datos_turno.Especialidad
( 
    id_especialidad INT IDENTITY(1,1) PRIMARY KEY,
    nombre_especialidad VARCHAR(30) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL
)

GO

CREATE TABLE datos_turno.Medico
( 
    id_medico INT IDENTITY(1,1),
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(30) NOT NULL,
    nro_matricula VARCHAR(10) NOT NULL,
    id_especialidad INT NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,
    PRIMARY KEY (id_medico, id_especialidad),
    FOREIGN KEY (id_especialidad) REFERENCES datos_turno.Especialidad(id_especialidad)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
)

GO

CREATE TABLE datos_turno.DiaPorSede
( 
    dia DATE NOT NULL,
    hora TIME NOT NULL CHECK (DATEPART(MINUTE, hora) IN (0,15,30,45)),
    id_medico INT NOT NULL,
    id_especialidad INT NOT NULL,
    id_sede INT NOT NULL,
    PRIMARY KEY (dia,hora,id_medico,id_especialidad,id_sede),
    FOREIGN KEY (id_medico, id_especialidad) REFERENCES datos_turno.Medico(id_medico, id_especialidad)
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
    FOREIGN KEY (id_sede) REFERENCES datos_turno.SedeAtencion(id_sede)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
)
GO

CREATE TABLE datos_turno.EstadoTurno
( 
    id_estado INT IDENTITY(1,1) PRIMARY KEY,
    nombre_estado VARCHAR(11) CHECK(nombre_estado IN ('Atendido', 'Ausente', 'Cancelado', 'Disponible', 'Reservado'))
)

GO

CREATE TABLE datos_turno.Turno
(
    id_turno INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    id_medico INT NOT NULL,
    id_especialidad INT NOT NULL,
    id_direccion_atencion INT NOT NULL,
    id_estado_turno INT NOT NULL,
    id_tipo_turno INT NOT NULL,
    id_historia_clinica INT,
    FOREIGN KEY (fecha, hora, id_medico, id_especialidad, id_direccion_atencion) REFERENCES datos_turno.DiaPorSede(dia,hora,id_medico,id_especialidad,id_sede)
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
    FOREIGN KEY (id_estado_turno) REFERENCES datos_turno.EstadoTurno(id_estado)
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
    FOREIGN KEY (id_tipo_turno) REFERENCES datos_turno.TipoTurno(id_tipo_turno)
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
    FOREIGN KEY (id_historia_clinica) REFERENCES datos_paciente.Paciente(id_historia_clinica)
)

GO
CREATE TABLE datos_paciente.TipoEstudio
( 
    id_tipo_estudio INT IDENTITY(1,1) PRIMARY KEY,    
    area VARCHAR(50),
    nombre_estudio VARCHAR(100) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL
)
go
CREATE TABLE datos_paciente.EstudioPorPrestadora
(
    id_tipo_estudio INT NOT NULL,
    id_prestador INT NOT NULL,
    porcentaje_cobertura INT CHECK (porcentaje_cobertura BETWEEN 0 AND 100),
    costo INT CHECK (costo >= 0),
    requiere_autorizacion BIT NOT NULL,
    PRIMARY KEY (id_tipo_estudio, id_prestador),
    FOREIGN KEY (id_tipo_estudio) REFERENCES datos_paciente.TipoEstudio(id_tipo_estudio)
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
    FOREIGN KEY (id_prestador) REFERENCES datos_paciente.Prestador(id_prestador)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
)


COSAS HAY MODIFICAR(?
UNA SOLUCION 
MODIFICAR SI HAY 100 CREO
IF EXIST SELECT 1
SI CONTRASEÑA ADMITE NULO HAY QUE PONERLE NULL
NO USAR SQL DINAMICO 
////nuestro grupo
ruta no harckodeada 
is null  remplzar en el valor nulo
dominio con mas de un punto
cuidado para no generar otro id. scope

