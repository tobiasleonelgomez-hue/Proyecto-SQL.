USE [com3900g04];

GO

CREATE OR ALTER PROCEDURE datos_paciente.IngresarPrestador
    @nombre_prestador VARCHAR(20),
    @plan_prestador VARCHAR(20),
    @id_prestador INT OUTPUT
AS
BEGIN
    INSERT INTO datos_paciente.Prestador (nombre_prestador, plan_prestador)
    VALUES (@nombre_prestador, @plan_prestador);

    SET @id_prestador = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.IngresarUsuario
    @contrasena VARCHAR(20),
    @fecha_creacion DATE,
    @id_usuario INT OUTPUT
AS
BEGIN
    INSERT INTO datos_paciente.Usuario (contrasena)
    VALUES (@contrasena);

    SET @id_usuario = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_paciente.IngresarPaciente
    @nombre VARCHAR(30),
    @apellido VARCHAR(30),
    @apellido_materno VARCHAR(30) = NULL,
    @fecha_nacimiento DATE,
    @tipo_documento VARCHAR(3),
    @nro_documento INT,
    @sexo_biologico VARCHAR(10),
    @genero VARCHAR(10),
    @nacionalidad VARCHAR(30),
    @foto_perfil VARCHAR(50) = NULL,
    @mail VARCHAR(100) = NULL,
    @telefono_fijo VARCHAR(30),
    @telefono_alternativo VARCHAR(30) = NULL,
    @telefono_trabajo VARCHAR(30) = NULL,
    @usuario_id INT,
    @id_historia_clinica INT OUTPUT
AS
BEGIN
    -- Verificar si el usuario existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Usuario WHERE id_usuario = @usuario_id)
    BEGIN
        RAISERROR('El usuario de actualización no existe.', 16, 1);
        RETURN;
    END

    -- Verificar formato de correo electrónico
    IF @mail IS NOT NULL AND @mail NOT LIKE '%_@__%.__%'
    BEGIN
        RAISERROR('Formato de correo electrónico no válido.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_paciente.Paciente (
        nombre, apellido, apellido_materno, fecha_nacimiento, tipo_documento, nro_documento, 
        sexo_biologico, genero, nacionalidad, foto_perfil, mail, telefono_fijo, 
        telefono_alternativo, telefono_trabajo, fecha_actualizacion, usuario_actualizacion
    )
    VALUES (
        @nombre, @apellido, @apellido_materno, @fecha_nacimiento, @tipo_documento, @nro_documento, 
        @sexo_biologico, @genero, @nacionalidad, @foto_perfil, @mail, @telefono_fijo, 
        @telefono_alternativo, @telefono_trabajo, GETDATE(), @usuario_id
    );

    SET @id_historia_clinica = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_paciente.IngresarDomicilio
    @calle VARCHAR(40),
    @numero NUMERIC(6,0),
    @piso NUMERIC(3,0) = NULL,
    @departamento VARCHAR(3) = NULL,
    @codigo_postal VARCHAR(10),
    @pais VARCHAR(40),
    @provincia VARCHAR(50),
    @localidad VARCHAR(50),
    @id_historia_clinica INT,
    @id_domicilio INT OUTPUT
AS
BEGIN
    -- Verificar si el paciente existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Paciente WHERE id_historia_clinica = @id_historia_clinica)
    BEGIN
        RAISERROR('El paciente no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_paciente.Domicilio (
        calle, numero, piso, departamento, codigo_postal, pais, provincia, localidad, id_historia_clinica
    )
    VALUES (
        @calle, @numero, @piso, @departamento, @codigo_postal, @pais, @provincia, @localidad, @id_historia_clinica
    );

    SET @id_domicilio = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_paciente.IngresarEstudioPorPrestadora
    @id_tipo_estudio INT,
    @id_prestador INT,
    @porcentaje_cobertura INT,
    @costo INT,
    @requiere_autorizacion BIT,
    @id_estudio INT OUTPUT
AS
BEGIN
    -- Verificar si el tipo de estudio existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.TipoEstudio WHERE id_tipo_estudio = @id_tipo_estudio)
    BEGIN
        RAISERROR('El paciente no existe.', 16, 1);
        RETURN;
    END

    -- Verificar si el paciente existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Prestador WHERE id_prestador = @id_prestador)
    BEGIN
        RAISERROR('El prestador no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_paciente.EstudioPorPrestadora (
        id_tipo_estudio, id_prestador, porcentaje_cobertura, costo, requiere_autorizacion
    )
    VALUES (
        @id_tipo_estudio, @id_prestador, @porcentaje_cobertura, @costo, @requiere_autorizacion
    );

    SET @id_estudio = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_paciente.IngresarTipoEstudio
    @area VARCHAR(50),
    @nombre_estudio VARCHAR(100),
    @id_estudio INT OUTPUT
AS
BEGIN

    INSERT INTO datos_paciente.TipoEstudio (
        area, nombre_estudio
    )
    VALUES (
        @area, @nombre_estudio
    );

    SET @id_estudio = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_paciente.IngresarEstudioRealizado
    @fecha DATE,
    @autorizado BIT,
    @documento_resultado VARCHAR(50) = NULL,
    @imagen_resultado VARCHAR(50) = NULL,
    @id_tipo_estudio INT,
    @id_historia_clinica INT,
    @id_estudio INT OUTPUT
AS
BEGIN
    -- Verificar si el tipo de estudio existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.TipoEstudio WHERE id_tipo_estudio = @id_tipo_estudio)
    BEGIN
        RAISERROR('El paciente no existe.', 16, 1);
        RETURN;
    END

    -- Verificar si el paciente existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Paciente WHERE id_historia_clinica = @id_historia_clinica)
    BEGIN
        RAISERROR('El paciente no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_paciente.EstudioRealizado (
        fecha, autorizado, documento_resultado, imagen_resultado, id_tipo_estudio, id_historia_clinica
    )
    VALUES (
        @fecha, @autorizado, @documento_resultado, @imagen_resultado, @id_tipo_estudio, @id_historia_clinica
    );

    SET @id_estudio = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE IngresarCobertura
    @imagen_credencial VARCHAR(50) = NULL,
    @nro_socio NUMERIC(16,0),
    @fecha_registro DATE,
    @id_prestador INT,
    @id_historia_clinica INT,
    @id_cobertura INT OUTPUT
AS
BEGIN
    -- Verificar si el prestador existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Prestador WHERE id_prestador = @id_prestador)
    BEGIN
        RAISERROR('El prestador no existe.', 16, 1);
        RETURN;
    END

    -- Verificar si el paciente existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Paciente WHERE id_historia_clinica = @id_historia_clinica)
    BEGIN
        RAISERROR('El paciente no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_paciente.Cobertura (
        imagen_credencial, nro_socio, fecha_registro, id_prestador, id_historia_clinica
    )
    VALUES (
        @imagen_credencial, @nro_socio, @fecha_registro, @id_prestador, @id_historia_clinica
    );

    SET @id_cobertura = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE datos_turno.IngresarSedeAtencion
    @nombre_sede VARCHAR(50),
    @direccion_sede VARCHAR(100),
    @id_sede INT OUTPUT
AS
BEGIN
    INSERT INTO datos_turno.SedeAtencion (nombre_sede, direccion_sede)
    VALUES (@nombre_sede, @direccion_sede);

    SET @id_sede = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_turno.IngresarTipoTurno
    @nombre_tipo_turno VARCHAR(10),
    @id_tipo_turno INT OUTPUT
AS
BEGIN
    -- Verificar si el tipo de turno es Presencial o Virtual.
    IF NOT (@nombre_tipo_turno = 'Presencial' OR @nombre_tipo_turno = 'Virtual')
    BEGIN
        RAISERROR('Tipo de turno no válido.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_turno.TipoTurno (nombre_tipo_turno)
    VALUES (@nombre_tipo_turno);

    SET @id_tipo_turno = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_turno.IngresarEspecialidad
    @nombre_especialidad VARCHAR(30),
    @id_especialidad INT OUTPUT
AS
BEGIN
    INSERT INTO datos_turno.Especialidad (nombre_especialidad)
    VALUES (@nombre_especialidad);

    SET @id_especialidad = SCOPE_IDENTITY();
END

GO

CREATE OR ALTER PROCEDURE datos_turno.IngresarMedico
    @nombre VARCHAR(30),
    @apellido VARCHAR(30),
    @nro_matricula VARCHAR(10),
    @id_especialidad INT,
    @id_medico INT OUTPUT
AS
BEGIN
    -- Verificar si la especialidad existe
    IF NOT EXISTS (SELECT 1 FROM datos_turno.Especialidad WHERE id_especialidad = @id_especialidad)
    BEGIN
        RAISERROR('La especialidad no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_turno.Medico (nombre, apellido, nro_matricula, id_especialidad)
    VALUES (@nombre, @apellido, @nro_matricula, @id_especialidad);

    SET @id_medico = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE datos_turno.IngresarDiaPorSede
    @dia DATE,
    @hora TIME,
    @id_medico INT,
    @id_especialidad INT,
    @id_sede INT
AS
BEGIN
    -- Verificar si el médico y la especialidad existen
    IF NOT EXISTS (SELECT 1 FROM datos_turno.Medico WHERE id_medico = @id_medico AND id_especialidad = @id_especialidad)
    BEGIN
        RAISERROR('El médico y/o la especialidad no existen.', 16, 1);
        RETURN;
    END

    -- Verificar si la sede existe
    IF NOT EXISTS (SELECT 1 FROM datos_turno.SedeAtencion WHERE id_sede = @id_sede)
    BEGIN
        RAISERROR('La sede no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_turno.DiaPorSede (dia, hora, id_medico, id_especialidad, id_sede)
    VALUES (@dia, @hora, @id_medico, @id_especialidad, @id_sede);
END
GO

CREATE OR ALTER PROCEDURE datos_turno.IngresarEstadoTurno
    @nombre_estado VARCHAR(11),
    @id_estado INT OUTPUT
AS
BEGIN
    INSERT INTO datos_turno.EstadoTurno (nombre_estado)
    VALUES (@nombre_estado);

    SET @id_estado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE IngresarTurno
    @fecha DATE,
    @hora TIME,
    @id_medico INT,
    @id_especialidad INT,
    @id_direccion_atencion INT,
    @id_estado_turno INT,
    @id_tipo_turno INT,
    @id_historia_clinica INT,
    @id_turno INT OUTPUT
AS
BEGIN
    -- Verificar si el turno está disponible en DiaPorSede
    IF NOT EXISTS (SELECT 1 FROM datos_turno.DiaPorSede WHERE dia = @fecha AND hora = @hora AND id_medico = @id_medico AND id_especialidad = @id_especialidad AND id_sede = @id_direccion_atencion)
    BEGIN
        RAISERROR('El turno no está disponible en el día y hora especificados.', 16, 1);
        RETURN;
    END

    -- Verificar si el estado del turno existe
    IF NOT EXISTS (SELECT 1 FROM datos_turno.EstadoTurno WHERE id_estado = @id_estado_turno)
    BEGIN
        RAISERROR('El estado del turno no existe.', 16, 1);
        RETURN;
    END

    -- Verificar si el tipo de turno existe
    IF NOT EXISTS (SELECT 1 FROM datos_turno.TipoTurno WHERE id_tipo_turno = @id_tipo_turno)
    BEGIN
        RAISERROR('El tipo de turno no existe.', 16, 1);
        RETURN;
    END

    -- Verificar si el paciente existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Paciente WHERE id_historia_clinica = @id_historia_clinica)
    BEGIN
        RAISERROR('El paciente no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO datos_turno.Turno (
        fecha, hora, id_medico, id_especialidad, id_direccion_atencion, id_estado_turno, id_tipo_turno, id_historia_clinica
    )
    VALUES (
        @fecha, @hora, @id_medico, @id_especialidad, @id_direccion_atencion, @id_estado_turno, @id_tipo_turno, @id_historia_clinica
    );

    SET @id_turno = SCOPE_IDENTITY();
END
GO

GO
