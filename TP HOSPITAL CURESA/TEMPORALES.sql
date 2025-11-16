CREATE OR ALTER PROCEDURE datos_turno.PasarEspecialidadesTemporalesAPermanentes
AS
BEGIN
    DECLARE @especialidad VARCHAR(30);
    DECLARE @id_especialidad INT;
    DECLARE @i INT = 1;
    DECLARE @total INT;

    -- Tabla temporal para almacenar las especialidades nuevas
    DECLARE @EspecialidadesNuevas TABLE (
        especialidad VARCHAR(30)
    );

    -- Insertar las especialidades nuevas en la tabla temporal
    INSERT INTO @EspecialidadesNuevas (especialidad)
        SELECT DISTINCT T.especialidad
        FROM #MedicoTemporal T
        WHERE T.especialidad NOT IN (SELECT E.nombre_especialidad
                                    FROM datos_turno.Especialidad E)

    -- Obtener el número total de especialidades nuevas
    SET @total = (SELECT COUNT(*) FROM @EspecialidadesNuevas);

    -- Bucle para insertar cada especialidad nueva
    WHILE @i <= @total
    BEGIN
        -- Obtener la especialidad actual
        SET @especialidad = (SELECT especialidad FROM (SELECT especialidad, ROW_NUMBER() OVER (ORDER BY especialidad) row_n FROM @EspecialidadesNuevas) s  WHERE s.row_n = @i);

        -- Intentar insertar la especialidad usando el SP IngresarEspecialidad
        BEGIN TRY
            EXEC datos_turno.IngresarEspecialidad @nombre_especialidad = @especialidad, @id_especialidad = @id_especialidad OUTPUT;
            
            -- Verificar si la inserción fue exitosa
            IF @id_especialidad IS NULL
            BEGIN
                RAISERROR('No se pudo insertar la especialidad: %s', 16, 1, @especialidad);
                RETURN;
            END
        END TRY
        BEGIN CATCH
            RAISERROR('Error al insertar la especialidad: %s.', 16, 1, @especialidad);
            RETURN;
        END CATCH;

        -- Incrementar el índice
        SET @i = @i + 1;
    END
END

GO

CREATE OR ALTER PROCEDURE datos_turno.ImportarMedicosDesdeCSV @filepath varchar(max)
AS
BEGIN
    CREATE TABLE #MedicoTemporal
    (
        nombre varchar(30),
        apellido varchar(30),
        especialidad varchar(30),
        nro_colegiado int
    )

    DECLARE @SQL nvarchar(max)
    SET @SQL= '
    BULK INSERT #MedicoTemporal
    FROM ''' + @filepath + '''
    WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''65001''
        )'
    EXEC sp_executesql @SQL

    EXEC datos_turno.PasarEspecialidadesTemporalesAPermanentes

    INSERT INTO datos_turno.Medico(nombre, apellido, nro_matricula, id_especialidad)
        SELECT T.nombre,T.apellido,T.nro_colegiado,E.id_especialidad
        FROM #MedicoTemporal T 
        JOIN datos_turno.Especialidad E 
        ON T.especialidad LIKE E.nombre_especialidad
        WHERE T.nro_colegiado NOT IN (SELECT M.nro_matricula
                                    FROM datos_turno.Medico M)

    DROP TABLE #MedicoTemporal
END

GO

EXEC datos_turno.ImportarMedicosDesdeCSV 'C:\Dataset\Medicos.csv'

GO

CREATE OR ALTER PROCEDURE datos_paciente.InsertarPacientes @filepath varchar(max)
AS
BEGIN
    CREATE TABLE #PacientesTemporal
    (
        nombre varchar(80),
        apellido varchar(30),
        fecha_nac varchar(20),
        tipo_doc varchar(30),
        nro_doc int,
        sexo varchar(10),
        genero varchar(20),
        tel_fijo char(14),
        nacionalidad varchar(30),
        mail varchar(30),
        direccion varchar(100),
        localidad varchar(40),
        provincia varchar(40)
    )

    DECLARE @SQL nvarchar(max)
    SET @SQL= '
    BULK INSERT #PacientesTemporal
    FROM ''' + @filepath + '''
    WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''65001''
        )'

    EXEC sp_executesql @SQL

    --Se actualizan los datos de los pacientes existentes.

    UPDATE datos_paciente.Paciente SET 
        genero = T.genero,
        nacionalidad = T.nacionalidad,
        mail = T.mail,
        telefono_fijo = T.tel_fijo,
        activo = 1
    FROM #PacientesTemporal T
    WHERE T.nro_doc LIKE datos_paciente.Paciente.nro_documento

    --Se insertan los pacientes nuevos.

    INSERT INTO datos_paciente.Paciente (nombre, apellido, fecha_nacimiento, tipo_documento, nro_documento, sexo_biologico, genero, telefono_fijo, nacionalidad, mail)
        SELECT T.nombre, T.apellido, CONVERT(date,T.fecha_nac,103), T.tipo_doc, T.nro_doc, T.sexo, T.genero, T.tel_fijo, T.nacionalidad, T.mail
        FROM #PacientesTemporal T
        WHERE T.nro_doc NOT IN (SELECT P.nro_documento
                                FROM datos_paciente.Paciente P)
    --Tuvimos que adaptar la fecha del CSV que estaba en formato DD/MM/YYYY a la de nuestra base de datos que es YYYY-MM-DD.

    --Se insertan los domicilios nuevos de los pacientes que no tengan dicho domicilio asociado.
    INSERT INTO datos_paciente.Domicilio (Calle, Localidad, Provincia, id_historia_clinica) --ingreso domicilios.
        SELECT DISTINCT T.direccion, T.localidad, T.provincia, P.id_historia_clinica
        FROM #PacientesTemporal T
        JOIN datos_paciente.Paciente P ON T.nro_doc LIKE P.nro_documento
        WHERE T.direccion NOT IN (SELECT DISTINCT D.calle
                                FROM datos_paciente.Domicilio D
                                WHERE D.id_historia_clinica = P.id_historia_clinica
                                )

    DROP TABLE #PacientesTemporal
END
GO

EXEC datos_paciente.InsertarPacientes 'C:\Dataset\Pacientes.csv'
GO


CREATE OR ALTER PROCEDURE datos_paciente.InsertarPrestadores @filepath VARCHAR(max)
AS
BEGIN
    CREATE TABLE #PrestadoresTemporal
    (
        nombre VARCHAR(80),
        nombre_plan VARCHAR(80)
    )
    
    DECLARE @SQL NVARCHAR(max)
    SET @SQL= '
    BULK INSERT #PrestadoresTemporal
    FROM ''' + @filepath + '''
    WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''65001''
        )'
    EXEC sp_executesql @SQL

	
    UPDATE #PrestadoresTemporal
    SET nombre_plan = REPLACE(nombre_plan, ';;', '');

    INSERT INTO datos_paciente.Prestador (nombre_prestador, plan_prestador) --agregamos los prestadores nuevos a la tabla de prestadores.
        SELECT DISTINCT TRIM(T.nombre), TRIM(T.nombre_plan)
        FROM #PrestadoresTemporal T
        WHERE TRIM(T.nombre) + TRIM(T.nombre_plan) NOT IN (SELECT P.nombre_prestador + P.plan_prestador
                                            FROM datos_paciente.Prestador P)
    DROP TABLE #PrestadoresTemporal

END
GO 

EXEC datos_paciente.InsertarPrestadores 'C:\Dataset\Prestador.csv'

GO

CREATE OR ALTER PROCEDURE datos_turno.InsertarSedes @filepath VARCHAR(max)
AS
BEGIN
    CREATE TABLE #SedesTemporal
    (
        nombre_sede VARCHAR(100),
        direccion VARCHAR(200),
        localidad VARCHAR(50),
        provincia VARCHAR(50)
    )
    
    DECLARE @SQL NVARCHAR(max)
    SET @SQL= '
    BULK INSERT #SedesTemporal
    FROM ''' + @filepath + '''
    WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''65001''
        )'
    EXEC sp_executesql @SQL

    INSERT INTO datos_turno.SedeAtencion (nombre_sede, direccion_sede) --agregamos los prestadores nuevos a la tabla de prestadores.
        SELECT DISTINCT TRIM(T.nombre_sede), TRIM(T.direccion) + ', ' + TRIM(T.localidad) + ', ' + TRIM(T.provincia)
        FROM #SedesTemporal T
        WHERE TRIM(T.nombre_sede) NOT IN (SELECT S.nombre_sede
                                    FROM datos_turno.SedeAtencion S)
    DROP TABLE #SedesTemporal

END
GO 

EXEC datos_turno.InsertarSedes 'C:\Dataset\Sedes.csv'

GO

--Funcion que cambie los valores mal cargados a vocales con tilde y Ñ
CREATE OR ALTER FUNCTION datos_paciente.CambiarCaracteresEspeciales (@cadena VARCHAR(100))
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @cadena_corregida VARCHAR(100)
    SET @cadena_corregida = @cadena
    --vocales minúsculas
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã¡', 'á')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã©', 'é')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã­', 'í')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã³', 'ó')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ãº', 'ú')
    --vocales mayúsculas
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã', 'Á')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã‰', 'É')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã', 'Í')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã“', 'Ó')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ãš', 'Ú')
    --Caracter Ñ
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã±', 'ñ')
    SET @cadena_corregida = REPLACE(@cadena_corregida, 'Ã‘', 'Ñ')
    RETURN @cadena_corregida
END

GO

CREATE OR ALTER PROCEDURE datos_paciente.InsertarEstudios @filepath VARCHAR(max)
AS
BEGIN
    DECLARE @SQL NVARCHAR(max)
    CREATE TABLE #EstudiosPorPrestadoraTemporal
    (
        area VARCHAR(50),
        nombre_estudio VARCHAR(80),
        prestador VARCHAR(50),
        nombre_plan VARCHAR(50),
        porcentaje_cobertura INT,
        costo INT,
        requiere_autorizacion BIT
    )

    SET @SQL= N'
    INSERT INTO #EstudiosPorPrestadoraTemporal (area, nombre_estudio, prestador, nombre_plan, porcentaje_cobertura, costo, requiere_autorizacion)
    SELECT datos_paciente.CambiarCaracteresEspeciales(area), datos_paciente.CambiarCaracteresEspeciales(nombre_estudio), 
    datos_paciente.CambiarCaracteresEspeciales(prestador), datos_paciente.CambiarCaracteresEspeciales(nombre_plan), porcentaje_cobertura, costo, requiere_autorizacion
    FROM OPENROWSET (BULK '''+ @filepath +''', SINGLE_CLOB) AS JsonFile
    CROSS APPLY OPENJSON(JsonFile.BulkColumn)
    WITH (
            area varchar(50) ''$."Area"'',
            nombre_estudio varchar(80) ''$."Estudio"'',
            prestador varchar(50) ''$."Prestador"'',
            nombre_plan varchar(50) ''$."Plan"'',
            porcentaje_cobertura int ''$."Porcentaje Cobertura"'',
            costo int ''$."Costo"'',
            requiere_autorizacion bit ''$."Requiere autorizacion"''
        )'
    EXEC sp_executesql @SQL

    UPDATE datos_paciente.EstudioPorPrestadora SET
        porcentaje_cobertura = T.porcentaje_cobertura,
        costo = T.costo,
        requiere_autorizacion = T.requiere_autorizacion
    FROM #EstudiosPorPrestadoraTemporal T
    JOIN datos_paciente.TipoEstudio E ON T.area LIKE E.area AND T.nombre_estudio LIKE E.nombre_estudio
    JOIN datos_paciente.Prestador P ON T.prestador LIKE P.nombre_prestador AND T.nombre_plan LIKE P.plan_prestador
    WHERE CAST(E.id_tipo_estudio AS VARCHAR) + '/' + CAST(P.id_prestador AS VARCHAR)
    LIKE CAST(datos_paciente.EstudioPorPrestadora.id_tipo_estudio AS VARCHAR) + '/'  + CAST(datos_paciente.EstudioPorPrestadora.id_prestador AS VARCHAR)

    INSERT INTO datos_paciente.TipoEstudio (area, nombre_estudio) --agregamos los estudios nuevos a la tabla de estudios.
        SELECT DISTINCT T.area, T.nombre_estudio
        FROM #EstudiosPorPrestadoraTemporal T
        WHERE T.area + '/' + T.nombre_estudio NOT IN (SELECT TE.area + '/' + TE.nombre_estudio
                                            FROM datos_paciente.TipoEstudio TE)
        AND T.area IS NOT NULL
        AND T.nombre_estudio IS NOT NULL

    INSERT INTO datos_paciente.Prestador (nombre_prestador, plan_prestador) --agregamos los prestadores nuevos a la tabla de prestadores.
        SELECT DISTINCT T.prestador, T.nombre_plan
        FROM #EstudiosPorPrestadoraTemporal T
        WHERE T.prestador + '/' + T.nombre_plan NOT IN (SELECT P.nombre_prestador + '/' + P.plan_prestador
                                            FROM datos_paciente.Prestador P)
        AND T.prestador IS NOT NULL
        AND T.nombre_plan IS NOT NULL

    INSERT INTO datos_paciente.EstudioPorPrestadora (id_tipo_estudio, id_prestador, porcentaje_cobertura, costo, requiere_autorizacion) --agregamos los estudios a la tabla de estudios por prestadora.
        SELECT E.id_tipo_estudio, P.id_prestador, T.porcentaje_cobertura, T.costo, T.requiere_autorizacion
        FROM #EstudiosPorPrestadoraTemporal T
        JOIN datos_paciente.TipoEstudio E ON T.area LIKE E.area AND T.nombre_estudio LIKE E.nombre_estudio
        JOIN datos_paciente.Prestador P ON T.prestador LIKE P.nombre_prestador AND T.nombre_plan LIKE P.plan_prestador
        WHERE CAST(E.id_tipo_estudio AS VARCHAR) + '/' + CAST(P.id_prestador AS VARCHAR) 
        NOT IN (    SELECT CAST(EP.id_tipo_estudio AS VARCHAR) + '/' + CAST(EP.id_prestador AS VARCHAR)
                    FROM datos_paciente.EstudioPorPrestadora EP)

    DROP TABLE #EstudiosPorPrestadoraTemporal

END
GO 

EXEC datos_paciente.InsertarEstudios 'C:\Dataset\Centro_Autorizaciones.Estudios clinicos.json'
GO

CREATE OR ALTER FUNCTION datos_turno.TurnosAtendidos (@obra_social varchar(80), @fecha_inicio date, @fecha_fin date)
RETURNS varchar(max)
AS
BEGIN
DECLARE @xml varchar(max)

SET @xml=(SELECT P.apellido, P.Nombre nombre, P.nro_documento, M.Nombre nombre_medico, M.nro_matricula, T.fecha, T.hora, E.nombre_especialidad
		  FROM datos_turno.Turno T JOIN datos_paciente.Paciente P ON P.id_historia_clinica = T.id_historia_clinica
								JOIN datos_paciente.Cobertura C ON C.id_historia_clinica = P.id_historia_clinica
								JOIN datos_paciente.Prestador Pr ON Pr.id_prestador = C.id_prestador
								JOIN datos_turno.Medico M ON M.id_medico = T.id_medico
								JOIN datos_turno.Especialidad E ON E.id_especialidad = M.id_especialidad
								JOIN datos_turno.EstadoTurno ET ON ET.id_estado = T.id_estado_turno
		  WHERE Pr.nombre_prestador LIKE @obra_social
		  AND T.fecha BETWEEN @fecha_inicio AND @fecha_fin
		  AND ET.nombre_estado LIKE 'Atendido'
		  FOR xml RAW ('Turno'), ELEMENTS XSINIL)
RETURN @xml
END
GO

CREATE OR ALTER PROCEDURE datos_turno.ExportarTurnosAtendidos
    @obra_social VARCHAR(80),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @file_path VARCHAR(MAX)
AS
BEGIN
    DECLARE @xml VARCHAR(MAX);

    -- Obtener el XML usando la función Turnos_atendidos
    SET @xml = datos_turno.TurnosAtendidos(@obra_social, @fecha_inicio, @fecha_fin);

    IF(@xml IS NULL)
    BEGIN
        RAISERROR('No se encontraron turnos atendidos para la obra social %s en el intervalo de fechas especificado.', 16, 1, @obra_social);
        RETURN;
    END

    -- Crear una tabla temporal para almacenar el XML
    IF OBJECT_ID('tempdb..##XmlTemp') IS NOT NULL
    BEGIN
        DROP TABLE ##XmlTemp;
    END

    -- Crear una tabla temporal para almacenar el XML
    CREATE TABLE ##XmlTemp (xml_data XML);

    -- Insertar el XML en la tabla temporal
    INSERT INTO ##XmlTemp (xml_data)
    VALUES (@xml);

    EXEC master.dbo.sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC master.dbo.sp_configure 'xp_cmdshell', 1;
    RECONFIGURE;

    -- Generar el comando BCP
    DECLARE @bcpCommand NVARCHAR(MAX);
    SET @bcpCommand = N'bcp "SELECT xml_data FROM ##XmlTemp" queryout ' + QUOTENAME(@file_path, '"') + ' -c -T -S ' + QUOTENAME(@@SERVERNAME, '"');

    -- Ejecutar el comando BCP
	DECLARE @sql NVARCHAR(MAX);
	SET @sql = N'EXEC xp_cmdshell ' + QUOTENAME(@bcpCommand, '''');
    EXEC sp_executesql @sql;

    -- Limpiar la tabla temporal
    DROP TABLE ##XmlTemp;

    EXEC master.dbo.sp_configure 'xp_cmdshell', 0;
    RECONFIGURE;
    EXEC master.dbo.sp_configure 'show advanced options', 0;
    RECONFIGURE;
END;
GO

EXEC datos_turno.ExportarTurnosAtendidos 'OSDE', '2021-01-01', '2031-12-31', 'C:\Dataset\test.xml';

GO

CREATE OR ALTER FUNCTION datos_turno.MedicosXML (@Medico VARCHAR(30))
RETURNS varchar(max)
AS
BEGIN
    DECLARE @xml varchar(max)

    SET @xml=(SELECT datos_turno.Medico.nombre, datos_turno.Medico.apellido, datos_turno.Medico.nro_matricula, datos_turno.Especialidad.nombre_especialidad
            FROM datos_turno.Medico JOIN datos_turno.Especialidad ON datos_turno.Medico.id_especialidad = datos_turno.Especialidad.id_especialidad
            WHERE datos_turno.Medico.nombre LIKE @Medico
            FOR xml RAW ('Medico'), ELEMENTS XSINIL)
    RETURN @xml
END
GO

CREATE OR ALTER PROCEDURE datos_turno.ExportarMedicosXML
    @Medico VARCHAR(30),
    @file_path VARCHAR(MAX)
AS
BEGIN

    DECLARE @xml VARCHAR(MAX);

    -- Obtener el XML usando la función MedicosXML
    SET @xml = datos_turno.MedicosXML(@Medico);

    IF(@xml IS NULL)
    BEGIN
        RAISERROR('No se encontraron medicos con el nombre %s.', 16, 1, @Medico);
        RETURN;
    END

    -- Crear una tabla temporal para almacenar el XML
    IF OBJECT_ID('tempdb..##XmlTemp') IS NOT NULL
    BEGIN
        DROP TABLE ##XmlTemp;
    END

    CREATE TABLE ##XmlTemp (xml_data XML);

    -- Insertar el XML en la tabla temporal
    INSERT INTO ##XmlTemp (xml_data)
    VALUES (@xml);

    
    EXEC master.dbo.sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC master.dbo.sp_configure 'xp_cmdshell', 1;
    RECONFIGURE;

    -- Generar el comando BCP
    DECLARE @bcpCommand NVARCHAR(MAX);
    SET @bcpCommand = N'bcp "SELECT xml_data FROM ##XmlTemp" queryout ' + QUOTENAME(@file_path, '"') + ' -c -T -S ' + QUOTENAME(@@SERVERNAME, '"');

	--SELECT @bcpCommand;

    -- Ejecutar el comando BCP
	DECLARE @sql NVARCHAR(MAX);
	SET @sql = N'EXEC xp_cmdshell ' + QUOTENAME(@bcpCommand, '''');
    EXEC sp_executesql @sql;

    -- Limpiar la tabla temporal
    DROP TABLE ##XmlTemp;

    EXEC master.dbo.sp_configure 'xp_cmdshell', 0;
    RECONFIGURE;
    EXEC master.dbo.sp_configure 'show advanced options', 0;
    RECONFIGURE;
END;
GO

EXEC datos_turno.ExportarMedicosXML 'Dra. ALONSO', 'C:\Dataset\Medicos.xml'