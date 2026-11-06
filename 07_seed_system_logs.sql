-- 07_seed_system_logs.sql
-- Finalidade: Carga massiva da tabela de Logs com cargas úteis em JSON e timestamps precisos

USE DbStressTest;
GO

SET NOCOUNT ON;

-- Parâmetro de volumetria
DECLARE @TotalRegistros INT = 50000;

-- Dicionários em memória para modular as origens e tipos de eventos
WITH 
Origens AS (
    SELECT Indice, Modulo FROM (VALUES 
        (0, 'CheckoutService'), (1, 'PaymentGateway'), (2, 'InventoryWorker'), 
        (3, 'AuthManager'), (4, 'NotificationService'), (5, 'OrderProcessingEngine')
    ) AS v(Indice, Modulo)
),
TiposEventos AS (
    SELECT Indice, Evento, Severidade FROM (VALUES 
        (0, 'TransacaoIniciada', 'INFO'), 
        (1, 'ValidacaoEstoqueSucesso', 'INFO'), 
        (2, 'TentativaCobrancaCartao', 'DEBUG'), 
        (3, 'TimeoutComunicacaoAPI', 'WARN'), 
        (4, 'FalhaAutenticacaoToken', 'ERROR'), 
        (5, 'TransacaoFinalizada', 'INFO')
    ) AS v(Indice, Evento, Severidade)
),
-- Gerador de sequencial em memória (até 500.000 linhas)
L0 AS (SELECT 1 AS c FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(c)),
L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
Numeros AS (
    SELECT TOP (@TotalRegistros) 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM L3
)
INSERT INTO dbo.SystemLogs (Origem, TipoEvento, DadosJson, DataCriacao)
SELECT 
    ori.Modulo AS Origem,
    evt.Evento AS TipoEvento,

    -- Carga útil JSON contendo metadados variáveis, GUIDs e status operacional
    '{' +
        '"traceId":"' + CONVERT(VARCHAR(36), NEWID()) + '",' +
        '"eventSequence":' + CAST(N.N AS VARCHAR(10)) + ',' +
        '"severity":"' + evt.Severidade + '",' +
        '"environment":"Production",' +
        '"details":{' +
            '"entityId":' + CAST(((N.N * 13) % 1000000) + 1 AS VARCHAR(10)) + ',' +
            '"executionTimeMs":' + CAST((N.N % 450) + 12 AS VARCHAR(10)) + ',' +
            '"isRetry":' + CASE WHEN (N.N % 15) = 0 THEN 'true' ELSE 'false' END + ',' +
            '"clientIp":"192.168.' + CAST((N.N % 254) + 1 AS VARCHAR(3)) + '.' + CAST(((N.N * 7) % 254) + 1 AS VARCHAR(3)) + '"' +
        '}' +
    '}' AS DadosJson,

    -- Timestamp distribuído nos últimos 180 dias com precisão em milissegundos
    DATEADD(MILLISECOND, -(N.N * 31103) % 15552000000, CAST('2026-10-01 12:00:00.000' AS DATETIME2(3))) AS DataCriacao
FROM Numeros N
JOIN Origens ori      ON ori.Indice =