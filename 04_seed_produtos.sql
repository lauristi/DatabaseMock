-- 04_seed_produtos.sql
-- Finalidade: Carga massiva da tabela de Produtos com SKUs e descrições estruturadas

USE DbStressTest;
GO

SET NOCOUNT ON;

-- Parâmetro de volumetria
DECLARE @TotalRegistros INT = 50000;

-- Dicionários em memória para montagem das descrições
WITH 
Categorias AS (
    SELECT Indice, NomeCategoria FROM (VALUES 
        (0, 'Perifericos'), (1, 'Armazenamento'), (2, 'Conectividade'), 
        (3, 'Acessorios'), (4, 'Componentes'), (5, 'Energia')
    ) AS v(Indice, NomeCategoria)
),
Tipos AS (
    SELECT Indice, NomeTipo FROM (VALUES 
        (0, 'Teclado'), (1, 'Mouse'), (2, 'Monitor'), (3, 'SSD'), 
        (4, 'Hub USB'), (5, 'Fonte ATX'), (6, 'Cabo HDMI'), (7, 'Adaptador'),
        (8, 'Gabinete'), (9, 'Cooler'), (10, 'Webcam'), (11, 'Headset')
    ) AS v(Indice, NomeTipo)
),
Linhas AS (
    SELECT Indice, NomeLinha FROM (VALUES 
        (0, 'Standard'), (1, 'Pro'), (2, 'Ultra'), (3, 'Slim'), 
        (4, 'Gamer'), (5, 'Compact'), (6, 'Industrial'), (7, 'Max')
    ) AS v(Indice, NomeLinha)
),
Especificacoes AS (
    SELECT Indice, NomeSpec FROM (VALUES 
        (0, 'Preto 1.8m'), (1, 'USB-C 3.2'), (2, 'Wireless 2.4GHz'), (3, 'RGB Mecanico'), 
        (4, 'Bivolt 650W'), (5, 'Articulado Alumínio'), (6, 'NVMe 1TB'), (7, 'Ergonomico')
    ) AS v(Indice, NomeSpec)
),
-- Gerador de números em memória
L0 AS (SELECT 1 AS c FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(c)),
L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
Numeros AS (
    SELECT TOP (@TotalRegistros) 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM L3
)
INSERT INTO dbo.Products (SKU, Descricao, Categoria, Preco, EstoqueAtual, Ativo)
SELECT 
    -- Código SKU: 3 letras da categoria + traço + número da linha com zeros à esquerda
    UPPER(LEFT(cat.NomeCategoria, 3)) + '-' + RIGHT('000000' + CAST(N.N AS VARCHAR(10)), 6) AS SKU,

    -- Descrição: Tipo + Linha + Especificação
    tip.NomeTipo + ' ' + lin.NomeLinha + ' ' + esp.NomeSpec AS Descricao,

    -- Categoria
    cat.NomeCategoria AS Categoria,

    -- Preço: varia entre R$ 15,00 e R$ 1.014,00 com duas casas decimais
    CAST(((N.N * 37) % 1000) + 15 + ((N.N % 100) * 0.01) AS DECIMAL(18,2)) AS Preco,

    -- Estoque: varia entre 0 e 500 unidades
    (N.N * 13) % 501 AS EstoqueAtual,

    -- 95% dos produtos ativos, 5% inativos
    CASE WHEN (N.N % 20) = 0 THEN 0 ELSE 1 END AS Ativo
FROM Numeros N
JOIN Categorias cat    ON cat.Indice = (N.N % 6)
JOIN Tipos tip         ON tip.Indice = ((N.N / 6) % 12)
JOIN Linhas lin        ON lin.Indice = ((N.N / 72) % 8)
JOIN Especificacoes esp ON esp.Indice = ((N.N / 576) % 8);
GO