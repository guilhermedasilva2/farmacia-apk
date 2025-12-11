-- ============================================
-- MIGRAÇÃO: Adicionar Campos de Endereço de Entrega
-- Data: 2025-12-11
-- Descrição: Adiciona campos de endereço de entrega à tabela orders
-- ============================================

-- Adicionar campos de endereço de entrega
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS delivery_number TEXT,
ADD COLUMN IF NOT EXISTS delivery_complement TEXT,
ADD COLUMN IF NOT EXISTS delivery_neighborhood TEXT,
ADD COLUMN IF NOT EXISTS delivery_city TEXT,
ADD COLUMN IF NOT EXISTS delivery_state TEXT,
ADD COLUMN IF NOT EXISTS delivery_cep TEXT;

-- Verificar estrutura atualizada
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders'
ORDER BY ordinal_position;
