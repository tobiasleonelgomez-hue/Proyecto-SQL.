CREATE DATABASE com3900g04
ON 
( 
    NAME = com3900g04_Data, 
    FILENAME = 'C:\SQLData\MSSQL\Data\com3900g04.mdf', 
    SIZE = 2GB, 
    MAXSIZE = 10GB, 
    FILEGROWTH = 2GB 
)
LOG ON 
( 
    NAME = MiBaseDeDatos_Log, 
    FILENAME = 'C:\SQLLogs\MSSQL\Log\MiBaseDeDatos.ldf', 
    SIZE = 500MB, 
    FILEGROWTH = 100MB 
);