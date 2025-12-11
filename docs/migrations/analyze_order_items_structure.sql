-- ============================================
-- ANÁLISE: Estrutura atual da tabela order_items
-- ============================================

-- Estrutura atual retornada pelo usuário:
-- column_name  | data_type | is_nullable | column_default
-- order_id     | uuid      | NO          | NULL
-- product_id   | uuid      | NO          | NULL
-- name         | text      | YES         | NULL
-- quantity     | integer   | NO          | NULL
-- unit_price   | numeric   | NO          | NULL  ⚠️ Coluna existente
-- price        | numeric   | NO          | 0     ✅ Coluna adicionada

-- OBSERVAÇÃO:
-- A tabela possui DUAS colunas para preço:
-- 1. unit_price (já existia)
-- 2. price (recém adicionada)

-- RECOMENDAÇÃO:
-- Manter apenas a coluna 'price' e remover 'unit_price' para evitar confusão.
-- OU
-- Usar 'unit_price' em vez de 'price' no código.

-- ============================================
-- OPÇÃO 1: Remover coluna unit_price (Recomendado)
-- ============================================
/*
ALTER TABLE order_items 
DROP COLUMN IF EXISTS unit_price;
*/

-- ============================================
-- OPÇÃO 2: Copiar dados de unit_price para price (se houver dados)
-- ============================================
/*
UPDATE order_items 
SET price = unit_price 
WHERE price = 0 AND unit_price IS NOT NULL;

ALTER TABLE order_items 
DROP COLUMN unit_price;
*/

-- ============================================
-- Verificar se há dados na tabela
-- ============================================
SELECT COUNT(*) as total_order_items FROM order_items;

-- Se houver dados, verificar quais colunas têm valores
SELECT 
    COUNT(*) as total,
    COUNT(unit_price) as has_unit_price,
    COUNT(price) as has_price,
    AVG(unit_price) as avg_unit_price,
    AVG(price) as avg_price
FROM order_items;
