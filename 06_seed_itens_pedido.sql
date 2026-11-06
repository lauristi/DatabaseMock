-- 06_seed_itens_pedido.sql
-- Finalidade: Carga massiva da tabela de Itens de Pedido vinculados a Pedidos e Produtos

USE DbStressTest;
GO

SET NOCOUNT ON;

-- Parâmetros de volumetria
DECLARE @TotalRegistros INT = 4000000;
DECLARE @TotalPedidos INT = 1000000;
DECLARE @TotalProdutos INT = 50000;

-- Gerador de sequencial em memória (até 4.000.000 de linhas)
WITH 
L0 AS (SELECT 1 AS c FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(c)),
L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
Numeros AS (
    SELECT TOP (@TotalRegistros) 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM L3
)
INSERT INTO dbo.OrderItems (OrderId, ProductId, Quantidade, ValorUnitario, Desconto, Subtotal)
SELECT 
    -- Associa em média 4 itens para cada Pedido existente (1 até @TotalPedidos)
    ((N.N - 1) % @TotalPedidos) + 1 AS OrderId,

    -- Associa a um Produto existente de forma distribuída (1 até @TotalProdutos)
    ((N.N * 17) % @TotalProdutos) + 1 AS ProductId,

    -- Quantidade comprada: entre 1 e 5 unidades
    (N.N % 5) + 1 AS Quantidade,

    -- Valor Unitário: varia entre R$ 15,00 e R$ 850,00
    CAST(((N.N * 29) % 835) + 15 + ((N.N % 99) * 0.01) AS DECIMAL(18,2)) AS ValorUnitario,

    -- Desconto aplicado: 0 em 70% dos casos; valor fracionado nos demais
    CASE 
        WHEN (N.N % 10) < 7 THEN 0.00 
        ELSE CAST(((N.N % 15) + 1) * 0.50 AS DECIMAL(18,2)) 
    END AS Desconto,

    -- Subtotal pré-calculado: (Quantidade * ValorUnitario) - Desconto
    CAST(
        (((N.N % 5) + 1) * (((N.N * 29) % 835) + 15 + ((N.N % 99) * 0.01))) - 
        (CASE WHEN (N.N % 10) < 7 THEN 0.00 ELSE (((N.N % 15) + 1) * 0.50) END) 
        AS DECIMAL(18,2)
    ) AS Subtotal
FROM Numeros N;
GO