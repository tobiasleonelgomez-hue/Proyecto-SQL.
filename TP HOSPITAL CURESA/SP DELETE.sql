USE [com3900g04];

GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarUsuario
    @id_usuario INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_paciente.Usuario
    SET activo = 0
    WHERE id_usuario = @id_usuario;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarDomicilio
    @id_domicilio INT
AS
BEGIN
    -- Hard delete
    DELETE FROM datos_paciente.Domicilio WHERE id_domicilio = @id_domicilio;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarDomicilioDePaciente
    @id_historia_clinica INT
AS
BEGIN
    -- Hard delete
    DELETE FROM datos_paciente.Domicilio WHERE id_historia_clinica = @id_historia_clinica;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarEstudioRealizado
    @id_estudio_realizado INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_paciente.EstudioRealizado
    SET activo = 0
    WHERE id_estudio_realizado = @id_estudio_realizado;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarTipoEstudio
    @id_tipo_estudio INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_paciente.EstudioRealizado
    SET activo = 0
    WHERE id_tipo_estudio = @id_tipo_estudio;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarEstudioPorPrestadora
    @id_tipo_estudio INT,
    @id_prestador INT
AS
BEGIN
    -- Soft delete
    DELETE FROM datos_paciente.EstudioPorPrestadora WHERE id_tipo_estudio = @id_tipo_estudio AND id_prestador = @id_prestador;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarEstudioDePaciente
    @id_historia_clinica INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_paciente.Estudio
    SET activo = 0
    WHERE id_historia_clinica = @id_historia_clinica;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarCobertura
    @id_cobertura INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_paciente.Cobertura
    SET activo = 0
    WHERE id_cobertura = @id_cobertura;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarCoberturaDePaciente
    @id_historia_clinica INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_paciente.Cobertura
    SET activo = 0
    WHERE id_historia_clinica = @id_historia_clinica;
END
GO

CREATE OR ALTER PROCEDURE datos_paciente.BorrarPaciente
    @id_historia_clinica INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_paciente.Paciente
    SET activo = 0
    WHERE id_historia_clinica = @id_historia_clinica;

    -- Eliminar registros relacionados
    EXEC datos_paciente.BorrarEstudioDePaciente @id_historia_clinica = @id_historia_clinica;
    EXEC datos_paciente.BorrarCoberturaDePaciente @id_historia_clinica = @id_historia_clinica;
    
    -- Liberar los turnos relacionados de la fecha de hoy en adelante
    UPDATE datos_turno.Turno 
    SET id_historia_clinica = NULL 
    WHERE id_historia_clinica = @id_historia_clinica
    AND fecha >= CAST(GETDATE() AS DATE);
    ;

END
GO

CREATE OR ALTER PROCEDURE datos_turno.BorrarTurno
    @id_turno INT
AS
BEGIN
    -- Verificar que el horario del turno no haya pasado
    IF EXISTS (SELECT 1 FROM datos_turno.Turno WHERE id_turno = @id_turno AND fecha < GETDATE())
    BEGIN
        RAISERROR('No se puede eliminar un turno que ya ha pasado.', 16, 1);
        RETURN;
    END

    DELETE FROM datos_turno.Turno WHERE id_turno = @id_turno;
END
GO

CREATE OR ALTER PROCEDURE datos_turno.BorrarDiaPorSede
    @dia DATE,
    @hora TIME,
    @id_medico INT,
    @id_especialidad INT,
    @id_sede INT
AS
BEGIN
    -- Hard delete
    DELETE FROM datos_turno.DiaPorSede WHERE dia = @dia AND hora = @hora AND id_medico = @id_medico AND id_especialidad = @id_especialidad AND id_sede = @id_sede;
END
GO

CREATE OR ALTER PROCEDURE datos_turno.BorrarMedico
    @id_medico INT,
    @id_especialidad INT
AS
BEGIN
    -- Soft delete
    UPDATE datos_turno.Medico
    SET activo = 0
    WHERE id_medico = @id_medico AND id_especialidad = @id_especialidad;

    -- Eliminar registros relacionados de la tabla Turno cuyos turnos estén disponibles, y coloca como cancelado los que estén reservados
    DELETE FROM datos_turno.Turno 
    WHERE   id_medico = @id_medico AND id_especialidad = @id_especialidad 
            AND id_estado_turno = (SELECT id_estado FROM datos_turno.EstadoTurno WHERE nombre_estado = 'Disponible');

    UPDATE datos_turno.Turno
    SET id_estado_turno = (SELECT id_estado FROM datos_turno.EstadoTurno WHERE nombre_estado = 'Cancelado')
    WHERE   id_medico = @id_medico AND id_especialidad = @id_especialidad 
            AND id_estado_turno = (SELECT id_estado FROM datos_turno.EstadoTurno WHERE nombre_estado = 'Reservado');
END
GO

