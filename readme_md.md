# DbStressTest — SQL Server Load Testing Dataset

Ambiente reproduzível e automatizado para geração de massa de dados realista e volumosa (~5,6 milhões de registros / ~1,6 GB) no **SQL Server Express** ou edições superiores.

Este projeto foi projetado especificamente para testes de estresse, benchmarks de desempenho e diagnóstico de gargalos em:
- Renderização e virtualização de componentes de grid com paginação profunda (`Skip`/`Take`).
- Diagnóstico de consultas com **Entity Framework Core** (avaliação de `AsNoTracking`, problemas de $N+1$, impacto de `.Include()` e projeções com `Select`).
- Processamento em lote (*batch processing*), controle de memória do `ChangeTracker` e contenção de I/O de log.

---

## 📊 Volumetria e Arquitetura de Dados

A geração utiliza técnicas puramente relacionais em memória (produtos cartesianos com tabelas de números do sistema) e combinações de vetores de strings para produzir dados críveis e orgânicos sem recorrer a loops imperativos lentos.

| Arquivo de Carga | Tabela | Volumetria Padrão | Tamanho Aprox. | Cenários de Teste Alvo |
| :--- | :--- | :---: | :---: | :--- |
| `03_seed_clientes.sql` | `Customers` | 100.000 | ~35 MB | Autocompletar, filtros de substring (`Contains`), ordenação textual. |
| `04_seed_produtos.sql` | `Products` | 50.000 | ~20 MB | Lookups de produtos, filtros por categorias e faixa de preço. |
| `05_seed_pedidos.sql` | `Orders` | 1.000.000 | ~350 MB | Paginação profunda, ordenações sem cobertura de índice, carga de colunas longas. |
| `06_seed_itens_pedido.sql`| `OrderItems` | 4.000.000 | ~650 MB | Junções pesadas, agregações (`SUM`/`COUNT`), consultas com múltiplos `.Include()`. |
| `07_seed_system_logs.sql` | `SystemLogs` | 500.000 | ~550 MB | Varredura completa (*Table Scan*), serialização e manipulação de cargas úteis em JSON. |
| **Total Consolidado** | — | **~5.650.000** | **~1,6 GB** | **Compatível com o limite de 10 GB do SQL Server Express** |

---

## 📁 Estrutura dos Arquivos

Os scripts SQL são numerados para garantir a ordem estrita de execução:

```text
├── 01_create_database.sql              # Cria o banco com Recovery Simple e pré-alocação de arquivos
├── 02_create_tables.sql                # DDL das tabelas (apenas PK Clustered inicial)
├── 03_seed_clientes.sql                # Popula Customers com nomes orgânicos e CPFs mascarados
├── 04_seed_produtos.sql                # Popula Products com SKUs, categorias e preços dinâmicos
├── 05_seed_pedidos.sql                 # Popula Orders com cabeçalhos e textos longos de observação
├── 06_seed_itens_pedido.sql            # Popula OrderItems distribuindo ~4 itens por pedido
├── 07_seed_system_logs.sql             # Popula SystemLogs com metadados e payloads JSON
├── 08_create_indexes_and_constraints.sql # Aplica Foreign Keys e índices não-clusterizados secundários
└── 09_update_statistics.sql            # Executa FULLSCAN em todas as tabelas para otimização de planos
```

---

## ⚙️ Como Parametrizar o Volume

Cada script de carga (`03` a `07`) possui uma variável de controle no topo do arquivo. Para aumentar ou diminuir a escala dos testes, altere o valor declarado:

```sql
-- Exemplo no arquivo 03_seed_clientes.sql
DECLARE @TotalRegistros INT = 100000; -- Ajuste para 200000, 500000, etc.
```

> **Atenção:** Ao alterar o volume de `Customers` ou `Orders`, certifique-se de alinhar as variáveis correspondentes de chave estrangeira nos scripts dependentes (`05_seed_pedidos.sql` e `06_seed_itens_pedido.sql`).

---

## 🚀 Como Executar

### Opção 1: Via SQL Server Management Studio (SSMS) ou Azure Data Studio
Abra e execute os scripts individualmente, seguindo estritamente a ordem numérica de `01` a `09`.

### Opção 2: Linha de Comando via `sqlcmd` (Automação em Lote)
Você pode executar todos os arquivos sequencialmente em sua instância local (por exemplo, `.\SQLEXPRESS`) rodando o comando abaixo no terminal ou criando um arquivo `.bat`:

```powershell
# Exemplo via PowerShell
$server = ".\SQLEXPRESS"
$files = Get-ChildItem -Filter "*.sql" | Sort-Object Name

foreach ($file in $files) {
    Write-Host "Executando $($file.Name)..." -ForegroundColor Cyan
    sqlcmd -S $server -E -i $file.FullName
}
Write-Host "Carga de estresse concluída com sucesso!" -ForegroundColor Green
```

---

## 🧪 Sugestões de Cenários de Teste

1. **Entity Framework — Efeito do Rastreador de Estado (*Change Tracker*):**
   Compare o consumo de memória RAM da aplicação e o tempo de resposta executando:
   ```csharp
   // Sem rastreamento (Leitura otimizada para grids/APIs)
   var lista = await context.Orders.AsNoTracking().Take(5000).ToListAsync();

   // Com rastreamento (Carregamento de entidades no ChangeTracker)
   var listaPesada = await context.Orders.Take(5000).ToListAsync();
   ```

2. **Paginação em Grids (Deep Paging):**
   Execute filtros ordenando por colunas não indexadas (ex.: `Observacoes` ou `ValorTotal`) buscando páginas distantes (`.Skip(100000).Take(50)`), avaliando o plano de execução gerado pelo SQL Server.

3. **Carregamento Antecipado (*Eager Loading*) vs Projeção:**
   Compare uma consulta buscando a entidade inteira via `.Include(o => o.OrderItems)` com uma consulta projetada via `.Select(o => new OrderDto { ... })`.