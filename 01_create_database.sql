-- 01_create_database.sql
-- Finalidade: Criação do banco de dados para testes de carga e configuração do log

IF DB_ID('DbStressTest') IS NOT NULL
BEGIN
    ALTER DATABASE DbStressTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DbStressTest;
END;
GO

CREATE DATABASE DbStressTest;
GO

ALTER DATABASE DbStressTest SET RECOVERY SIMPLE;
GO

-- Pré-alocação de espaço para evitar fragmentação e paradas por autogrowth durante a carga
ALTER DATABASE DbStressTest 
MODIFY FILE 
(
    NAME = N'DbStressTest',
    SIZE = 2048MB,
    FILEGROWTH = 256MB
);
GO

ALTER DATABASE DbStressTest 
MODIFY FILE 
(
    NAME = N'DbStressTest_log',
    SIZE = 512MB,
    FILEGROWTH = 128MB
);
GO