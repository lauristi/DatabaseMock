-- 09_update_statistics.sql
-- Finalidade: Atualização completa dos histogramas estatísticos para otimização de consultas

USE DbStressTest;
GO

SET NOCOUNT ON;

PRINT 'Atualizando estatísticas com FULLSCAN na tabela Customers...';
UPDATE STATISTICS dbo.Customers WITH FULLSCAN;
GO

PRINT 'Atualizando estatísticas com FULLSCAN na tabela Products...';
UPDATE STATISTICS dbo.Products WITH FULLSCAN;
GO

PRINT 'Atualizando estatísticas com FULLSCAN na tabela Orders...';
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
GO

PRINT 'Atualizando estatísticas com FULLSCAN na tabela OrderItems...';
UPDATE STATISTICS dbo.OrderItems WITH FULLSCAN;
GO

PRINT 'Atualizando estatísticas com FULLSCAN na tabela SystemLogs...';
UPDATE STATISTICS dbo.SystemLogs WITH FULLSCAN;
GO

-- Exibição consolidada da volumetria final registrada nas partições
SELECT 
    t.name AS Tabela,
    s.name AS Esquema,
    p.rows AS TotalLinhas,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS EspacoTotalMB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS EspacoUsadoMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 AND i.index_id <= 1
GROUP BY t.name, s.name, p.rows
ORDER BY TotalLinhas DESC;
GO