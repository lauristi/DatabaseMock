-- 02_create_tables.sql
-- Finalidade: Criação da estrutura DDL base sem índices secundários ou FKs

USE DbStressTest;
GO

-- 1. Clientes
DROP TABLE IF EXISTS dbo.OrderItems;
DROP TABLE IF EXISTS dbo.Orders;
DROP TABLE IF EXISTS dbo.Products;
DROP TABLE IF EXISTS dbo.Customers;
DROP TABLE IF EXISTS dbo.SystemLogs;
GO

CREATE TABLE dbo.Customers
(
    Id INT IDENTITY(1,1) NOT NULL,
    Nome VARCHAR(150) NOT NULL,
    Documento VARCHAR(20) NOT NULL,
    Email VARCHAR(150) NOT NULL,
    DataCadastro DATETIME2(0) NOT NULL,
    Ativo BIT NOT NULL,
    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (Id)
);
GO

-- 2. Produtos
CREATE TABLE dbo.Products
(
    Id INT IDENTITY(1,1) NOT NULL,
    SKU VARCHAR(50) NOT NULL,
    Descricao VARCHAR(250) NOT NULL,
    Categoria VARCHAR(50) NOT NULL,
    Preco DECIMAL(18,2) NOT NULL,
    EstoqueAtual INT NOT NULL,
    Ativo BIT NOT NULL,
    CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (Id)
);
GO

-- 3. Pedidos
CREATE TABLE dbo.Orders
(
    Id BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId INT NOT NULL,
    DataPedido DATETIME2(0) NOT NULL,
    Status INT NOT NULL,
    ValorTotal DECIMAL(18,2) NOT NULL,
    Observacoes VARCHAR(1000) NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (Id)
);
GO

-- 4. Itens do Pedido
CREATE TABLE dbo.OrderItems
(
    Id BIGINT IDENTITY(1,1) NOT NULL,
    OrderId BIGINT NOT NULL,
    ProductId INT NOT NULL,
    Quantidade INT NOT NULL,
    ValorUnitario DECIMAL(18,2) NOT NULL,
    Desconto DECIMAL(18,2) NOT NULL,
    Subtotal DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_OrderItems PRIMARY KEY CLUSTERED (Id)
);
GO

-- 5. Logs do Sistema
CREATE TABLE dbo.SystemLogs
(
    Id BIGINT IDENTITY(1,1) NOT NULL,
    Origem VARCHAR(100) NOT NULL,
    TipoEvento VARCHAR(50) NOT NULL,
    DadosJson NVARCHAR(MAX) NOT NULL,
    DataCriacao DATETIME2(3) NOT NULL,
    CONSTRAINT PK_SystemLogs PRIMARY KEY CLUSTERED (Id)
);
GO