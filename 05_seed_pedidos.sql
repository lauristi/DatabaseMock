-- 05_seed_pedidos.sql
-- Finalidade: Carga massiva da tabela de Pedidos com observações pesadas e datas distribuídas

USE DbStressTest;
GO

SET NOCOUNT ON;

-- Parâmetros de volumetria
DECLARE @TotalRegistros INT = 1000000;
DECLARE @TotalClientes INT = 100000;

-- Dicionário em memória para compor o texto de observação
WITH 
TextosObs AS (
    SELECT Indice, Texto FROM (VALUES 
        (0, 'Entrega expressa autorizada pela expedicao central. Mercadoria despachada via transportadora credenciada.'),
        (1, 'Cliente solicitou entrega preferencialmente no periodo da tarde. Conferir volume na portaria principal.'),
        (2, 'Pedido faturado e liberado com antecedencia operacional. Nota fiscal anexada no envelope superior.'),
        (3, 'Endereco sujeito a restricao de horario comercial para descarga de veiculos pesados. Ligar antes.')
    ) AS v(Indice, Texto)
),
-- Gerador de sequencial em memória (até 1.000.000 de linhas)
L0 AS (SELECT 1 AS c FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(c)),
L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
Numeros AS (
    SELECT TOP (@TotalRegistros) 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM L3
)
INSERT INTO dbo.Orders (CustomerId, DataPedido, Status, ValorTotal, Observacoes)
SELECT 
    -- Vincula a um cliente existente de forma distribuída (1 até @TotalClientes)
    ((N.N * 31) % @TotalClientes) + 1 AS CustomerId,

    -- Data distribuída ao longo dos últimos 730 dias (2 anos)
    DATEADD(MINUTE, -(N.N % 1051200), CAST('2026-10-01 12:00:00' AS DATETIME2(0))) AS DataPedido,

    -- Status do Pedido: 1 (Pendente), 2 (Aprovado), 3 (Enviado), 4 (Entregue), 5 (Cancelado)
    (N.N % 5) + 1 AS Status,

    -- Valor total inicial (será consolidado ou usado para testes de agregação)
    CAST(((N.N * 47) % 5000) + 50 + ((N.N % 100) * 0.01) AS DECIMAL(18,2)) AS ValorTotal,

    -- Observação estruturada longa com GUID único para introduzir peso real de I/O
    obs.Texto + ' HashIdentificador: ' + CONVERT(VARCHAR(36), NEWID()) + 
    ' | CodigoRastreio: BR' + RIGHT('00000000' + CAST(N.N AS VARCHAR(10)), 8) + 'XP' AS Observacoes
FROM Numeros N
JOIN TextosObs obs ON obs.Indice = (N.N % 4);
GO