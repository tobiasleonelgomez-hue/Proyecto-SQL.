USE [com3900g04];

GO

CREATE OR ALTER PROCEDURE datos_paciente.ModificarPrestador
    @id_prestador INT,
    @activo BIT
AS
BEGIN
    -- Verificar si el prestador existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Prestador WHERE id_prestador = @id_prestador)
    BEGIN
        RAISERROR('El prestador no existe.', 16, 1);
        RETURN;
    END

    UPDATE datos_paciente.Prestador
    SET activo = @activo
    WHERE id_prestador = @id_prestador;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.ModificarUsuario
    @id_usuario INT,
    @contrasena VARCHAR(20),
    @activo BIT
AS
BEGIN
    -- Verificar si el usuario existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Usuario WHERE id_usuario = @id_usuario)
    BEGIN
        RAISERROR('El usuario no existe.', 16, 1);
        RETURN;
    END

    UPDATE datos_paciente.Usuario
    SET contrasena = @contrasena,
        activo = @activo
    WHERE id_usuario = @id_usuario;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.ModificarPaciente
    @id_historia_clinica INT,
    @genero VARCHAR(10),
    @nacionalidad VARCHAR(30),
    @foto_perfil VARCHAR(50) = NULL,
    @mail VARCHAR(100) = NULL,
    @telefono_fijo VARCHAR(30),
    @telefono_alternativo VARCHAR(30) = NULL,
    @telefono_trabajo VARCHAR(30) = NULL,
    @usuario_actualizacion INT,
    @activo BIT
AS
BEGIN
    -- Verificar si el paciente existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Paciente WHERE id_historia_clinica = @id_historia_clinica)
    BEGIN
        RAISERROR('El paciente no existe.', 16, 1);
        RETURN;
    END

    -- Verificar si el usuario de actualización existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Usuario WHERE id_usuario = @usuario_actualizacion)
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

    UPDATE datos_paciente.Paciente
    SET genero = @genero,
        nacionalidad = @nacionalidad,
        foto_perfil = @foto_perfil,
        mail = @mail,
        telefono_fijo = @telefono_fijo,
        telefono_alternativo = @telefono_alternativo,
        telefono_trabajo = @telefono_trabajo,
        fecha_actualizacion = GETDATE(),
        usuario_actualizacion = @usuario_actualizacion,
        activo = @activo
    WHERE id_historia_clinica = @id_historia_clinica;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.ModificarEstudioPorPrestadora
    @id_tipo_estudio INT,
    @id_prestador INT,
    @porcentaje_cobertura INT,
    @costo INT,
    @requiere_autorizacion BIT
AS
BEGIN
    -- Verificar si el estudio existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.EstudioPorPrestadora 
                    WHERE id_tipo_estudio = @id_tipo_estudio AND id_prestador = @id_prestador)
    BEGIN
        RAISERROR('El estudio no existe para esta prestadora.', 16, 1);
        RETURN;
    END

    UPDATE datos_paciente.EstudioPorPrestadora
    SET porcentaje_cobertura = @porcentaje_cobertura,
        costo = @costo,
        requiere_autorizacion = @requiere_autorizacion
    WHERE id_tipo_estudio = @id_tipo_estudio AND id_prestador = @id_prestador;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.ModificarEstudio
    @id_estudio_realizado INT,
    @fecha DATE,
    @nombre_estudio VARCHAR(100),
    @autorizado BIT,
    @documento_resultado VARCHAR(50) = NULL,
    @imagen_resultado VARCHAR(50) = NULL,
    @activo BIT
AS
BEGIN
    -- Verificar si el estudio existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.EstudioRealizado WHERE id_estudio_realizado = @id_estudio_realizado)
    BEGIN
        RAISERROR('El estudio no existe.', 16, 1);
        RETURN;
    END

    UPDATE datos_paciente.Estudio
    SET fecha = @fecha,
        nombre_estudio = @nombre_estudio,
        autorizado = @autorizado,
        documento_resultado = @documento_resultado,
        imagen_resultado = @imagen_resultado,
        activo = @activo
    WHERE id_estudio_realizado = @id_estudio_realizado;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.ModificarCobertura
    @id_cobertura INT,
    @imagen_credencial VARCHAR(50) = NULL,
    @activo BIT
AS
BEGIN
    -- Verificar si la cobertura existe
    IF NOT EXISTS (SELECT 1 FROM datos_paciente.Cobertura WHERE id_cobertura = @id_cobertura)
    BEGIN
        RAISERROR('La cobertura no existe.', 16, 1);
        RETURN;
    END

    UPDATE datos_paciente.Cobertura
    SET imagen_credencial = @imagen_credencial,
        activo = @activo
    WHERE id_cobertura = @id_cobertura;
END
GO

CREATE OR ALTER PROCEDURE datos_turno.ModificarSedeAtencion
    @id_sede INT,
    @direccion_sede VARCHAR(100),
    @activo BIT
AS
BEGIN
    -- Verificar si la sede de atención existe
    IF NOT EXISTS (SELECT 1 FROM datos_turno.SedeAtencion WHERE id_sede = @id_sede)
    BEGIN
        RAISERROR('La sede de atención no existe.', 16, 1);
        RETURN;
    END

    UPDATE datos_turno.SedeAtencion
    SET direccion_sede = @direccion_sede,
    activo = @activo
    WHERE id_sede = @id_sede;
END
GO

-- CREATE OR ALTER PROCEDURE datos_turno.ModificarTipoTurno
--     @id_tipo_turno INT,
--     @nombre_tipo_turno VARCHAR(10)
-- AS
-- BEGIN
--     -- Verificar si el tipo de turno es Presencial o Virtual.
--     IF NOT (@nombre_tipo_turno = 'Presencial' OR @nombre_tipo_turno = 'Virtual')
--     BEGIN
--         RAISERROR('Tipo de turno no válido.', 16, 1);
--         RETURN;
--     END

--     -- Verificar si el tipo de turno existe
--     IF NOT EXISTS (SELECT 1 FROM datos_turno.TipoTurno WHERE id_tipo_turno = @id_tipo_turno)
--     BEGIN
--         RAISERROR('El tipo de turno no existe.', 16, 1);
--         RETURN;
--     END

--     UPDATE datos_turno.TipoTurno
--     SET nombre_tipo_turno = @nombre_tipo_turno
--     WHERE id_tipo_turno = @id_tipo_turno;
-- END
-- GO

CREATE OR ALTER PROCEDURE datos_turno.ModificarEspecialidad
    @id_especialidad INT,
    @activo BIT
AS
BEGIN
    -- Verificar si la especialidad existe
    IF NOT EXISTS (SELECT 1 FROM datos_turno.Especialidad WHERE id_especialidad = @id_especialidad)
    BEGIN
        RAISERROR('La especialidad no existe.', 16, 1);
        RETURN;
    END

    UPDATE datos_turno.Especialidad
    SET activo = @activo
    WHERE id_especialidad = @id_especialidad;
END
GO

CREATE OR ALTER PROCEDURE datos_turno.ModificarMedico
    @id_medico INT,
    @nro_matricula VARCHAR(10),
    @id_especialidad INT,
    @activo BIT
AS
BEGIN
    -- Verificar si el médico y la especialidad existen
    IF NOT EXISTS (SELECT 1 FROM datos_turno.Medico WHERE id_medico = @id_medico AND id_especialidad = @id_especialidad)
    BEGIN
        RAISERROR('El médico y/o la especialidad no existen.', 16, 1);
        RETURN;
    END

    UPDATE datos_turno.Medico
    SET nro_matricula = @nro_matricula,
        activo = @activo
    WHERE id_medico = @id_medico AND id_especialidad = @id_especialidad;
END
GO

-- CREATE OR ALTER PROCEDURE datos_turno.ModificarDiaPorSede
--     @dia DATE,
--     @hora TIME,
--     @id_medico INT,
--     @id_especialidad INT,
--     @id_sede INT,
--     @nuevo_dia DATE,
--     @nueva_hora TIME,
--     @nuevo_id_medico INT,
--     @nuevo_id_especialidad INT,
--     @nuevo_id_sede INT
-- AS
-- BEGIN
--     -- Verificar si el turno existe
--     IF NOT EXISTS (SELECT 1 FROM datos_turno.DiaPorSede WHERE dia = @dia AND hora = @hora AND id_medico = @id_medico AND id_especialidad = @id_especialidad AND id_sede = @id_sede)
--     BEGIN
--         RAISERROR('El turno no existe.', 16, 1);
--         RETURN;
--     END

--     -- Verificar si el nuevo médico y la especialidad existen
--     IF NOT EXISTS (SELECT 1 FROM datos_turno.Medico WHERE id_medico = @nuevo_id_medico AND id_especialidad = @nuevo_id_especialidad)
--     BEGIN
--         RAISERROR('El nuevo médico y/o la especialidad no existen.', 16, 1);
--         RETURN;
--     END

--     -- Verificar si la nueva sede existe
--     IF NOT EXISTS (SELECT 1 FROM datos_turno.SedeAtencion WHERE id_sede = @nuevo_id_sede)
--     BEGIN
--         RAISERROR('La nueva sede no existe.', 16, 1);
--         RETURN;
--     END

--     UPDATE datos_turno.DiaPorSede
--     SET dia = @nuevo_dia,
--         hora = @nueva_hora,
--         id_medico = @nuevo_id_medico,
--         id_especialidad = @nuevo_id_especialidad,
--         id_sede = @nuevo_id_sede
--     WHERE dia = @dia AND hora = @hora AND id_medico = @id_medico AND id_especialidad = @id_especialidad AND id_sede = @id_sede;
-- END
-- GO

-- CREATE OR ALTER PROCEDURE datos_turno.ModificarEstadoTurno
--     @id_estado INT,
--     @nombre_estado VARCHAR(11)
-- AS
-- BEGIN
--     -- Verificar si el estado de turno existe
--     IF NOT EXISTS (SELECT 1 FROM datos_turno.EstadoTurno WHERE id_estado = @id_estado)
--     BEGIN
--         RAISERROR('El estado de turno no existe.', 16, 1);
--         RETURN;
--     END

--     UPDATE datos_turno.EstadoTurno
--     SET nombre_estado = @nombre_estado
--     WHERE id_estado = @id_estado;
-- END
-- GO

CREATE OR ALTER PROCEDURE datos_turno.ModificarTurno
    @id_turno INT,
    @id_estado_turno INT,
    @id_tipo_turno INT,
    @id_historia_clinica INT
AS
BEGIN
    -- Verificar si la reserva del turno existe
    IF NOT EXISTS (SELECT 1 FROM datos_turno.Turno WHERE id_turno = @id_turno)
    BEGIN
        RAISERROR('La reserva del turno no existe.', 16, 1);
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

    UPDATE datos_turno.Turno
    SET id_estado_turno = @id_estado_turno,
        id_tipo_turno = @id_tipo_turno,
        id_historia_clinica = @id_historia_clinica
    WHERE id_turno = @id_turno;
END
GO
