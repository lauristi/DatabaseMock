-- 08_create_indexes_and_constraints.sql
-- Finalidade: Criação de restrições de chave estrangeira e índices secundários para testes de consulta

USE DbStressTest;
GO

SET NOCOUNT ON;

-- 1. Restrições de Chave Estrangeira (Foreign Keys)
ALTER TABLE dbo.Orders WITH CHECK
ADD CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerId)
REFERENCES dbo.Customers (Id);
GO

ALTER TABLE dbo.OrderItems WITH CHECK
ADD CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId)
REFERENCES dbo.Orders (Id);
GO

ALTER TABLE dbo.OrderItems WITH CHECK
ADD CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductId)
REFERENCES dbo.Products (Id);
GO

-- 2. Índices Secundários para Otimização de Consultas de Teste

-- Índice para acelerar junções e filtros por cliente na tabela de Pedidos
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId_DataPedido
ON dbo.Orders (CustomerId, DataPedido DESC)
INCLUDE (Status, ValorTotal);
GO

-- Índice para ordenação e filtros por data (muito utilizado em grids por período)
CREATE NONCLUSTERED INDEX IX_Orders_DataPedido
ON dbo.Orders (DataPedido DESC);
GO

-- Índice para acelerar agregações e carregamentos antecipados (Include) de itens por pedido
CREATE NONCLUSTERED INDEX IX_OrderItems_OrderId
ON dbo.OrderItems (OrderId)
INCLUDE (ProductId, Quantidade, ValorUnitario, Subtotal);
GO

-- Índice para relatórios de vendas e cálculos por produto
CREATE NONCLUSTERED INDEX IX_OrderItems_ProductId
ON dbo.OrderItems (ProductId)
INCLUDE (Quantidade, Subtotal);
GO

-- Índice de apoio para buscas textuais por SKU e categoria de produtos
CREATE NONCLUSTERED INDEX IX_Products_Categoria_Preco
ON dbo.Products (Categoria, Preco)
INCLUDE (Descricao, EstoqueAtual);
GO

-- Índice temporal para filtros de log em intervalos de datas
CREATE NONCLUSTERED INDEX IX_SystemLogs_DataCriacao
ON dbo.SystemLogs (DataCriacao DESC)
INCLUDE (Origem, TipoEvento);
GO