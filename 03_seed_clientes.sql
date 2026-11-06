-- 03_seed_clientes.sql
-- Finalidade: Carga massiva da tabela de Clientes com nomes orgânicos e documentos estruturados

USE DbStressTest;
GO

SET NOCOUNT ON;

-- Parâmetro de volumetria
DECLARE @TotalRegistros INT = 100000;

-- Tabelas derivadas de nomes e sobrenomes
WITH 
PrimeirosNomes AS (
    SELECT Indice, Nome FROM (VALUES 
        (0, 'Carlos'), (1, 'Mariana'), (2, 'Fernando'), (3, 'Juliana'), 
        (4, 'Roberto'), (5, 'Patricia'), (6, 'Eduardo'), (7, 'Camila'),
        (8, 'Ricardo'), (9, 'Beatriz'), (10, 'Marcelo'), (11, 'Aline'),
        (12, 'Lucas'), (13, 'Renata'), (14, 'Gabriel'), (15, 'Vanessa')
    ) AS v(Indice, Nome)
),
Sobrenomes AS (
    SELECT Indice, Sobrenome FROM (VALUES 
        (0, 'Silva'), (1, 'Santos'), (2, 'Oliveira'), (3, 'Souza'), 
        (4, 'Rodrigues'), (5, 'Ferreira'), (6, 'Alves'), (7, 'Pereira'),
        (8, 'Lima'), (9, 'Gomes'), (10, 'Costa'), (11, 'Ribeiro'),
        (12, 'Carvalho'), (13, 'Melo'), (14, 'Barbosa'), (15, 'Martins')
    ) AS v(Indice, Sobrenome)
),
-- Gerador de sequencial em memória (até 1.000.000 de linhas sem I/O de disco)
L0 AS (SELECT 1 AS c FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(c)),
L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
Numeros AS (
    SELECT TOP (@TotalRegistros) 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM L3
)
INSERT INTO dbo.Customers (Nome, Documento, Email, DataCadastro, Ativo)
SELECT 
    -- Nome Completo: Primeiro Nome + Sobrenome 1 + Sobrenome 2
    p.Nome + ' ' + s1.Sobrenome + ' ' + s2.Sobrenome AS Nome,

    -- Documento formatado simulando CPF (11 dígitos estruturados e determinísticos)
    RIGHT('000' + CAST((N.N * 7) % 900 + 100 AS VARCHAR(3)), 3) + '.' +
    RIGHT('000' + CAST((N.N * 13) % 900 + 100 AS VARCHAR(3)), 3) + '.' +
    RIGHT('000' + CAST((N.N * 19) % 900 + 100 AS VARCHAR(3)), 3) + '-' +
    RIGHT('00' + CAST((N.N * 3) % 90 + 10 AS VARCHAR(2)), 2) AS Documento,

    -- E-mail derivado do nome e número da linha
    LOWER(p.Nome) + '.' + LOWER(s1.Sobrenome) + CAST(N.N AS VARCHAR(10)) + '@' +
    CASE (N.N % 4)
        WHEN 0 THEN 'gmail.com'
        WHEN 1 THEN 'outlook.com'
        WHEN 2 THEN 'empresa.com.br'
        ELSE 'provedor.net'
    END AS Email,

    -- Data de cadastro distribuída nos últimos 3 anos
    DATEADD(DAY, -(N.N % 1095), CAST('2026-10-01' AS DATETIME2(0))) AS DataCadastro,

    -- 90% dos registros ativos, 10% inativos
    CASE WHEN (N.N % 10) = 0 THEN 0 ELSE 1 END AS Ativo
FROM Numeros N
JOIN PrimeirosNomes p  ON p.Indice  = (N.N % 16)
JOIN Sobrenomes s1     ON s1.Indice = ((N.N / 16) % 16)
JOIN Sobrenomes s2     ON s2.Indice = ((N.N / 256) % 16);
GO