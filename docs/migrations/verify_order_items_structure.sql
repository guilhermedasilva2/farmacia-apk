-- ============================================
-- VERIFICAÇÃO: Estrutura da tabela order_items
-- Use este script para verificar se a coluna price existe
-- ============================================

-- 1. Verificar todas as colunas da tabela order_items
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'order_items'
ORDER BY ordinal_position;

-- 2. Verificar se a coluna 'price' existe especificamente
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'order_items' 
    AND column_name = 'price'
) AS price_column_exists;

-- 3. Se a coluna NÃO existir, execute a migração:
-- Veja: docs/migrations/add_price_column_migration.sql
