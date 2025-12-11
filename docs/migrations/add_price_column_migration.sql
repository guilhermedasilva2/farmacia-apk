-- ============================================
-- MIGRAÇÃO: Adicionar coluna 'price' à tabela order_items
-- Data: 2025-12-11
-- Descrição: Corrige erro "Could not find the 'price' column"
-- ============================================

-- Verificar se a coluna já existe antes de adicionar
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'order_items' 
        AND column_name = 'price'
    ) THEN
        -- Adicionar coluna price
        ALTER TABLE order_items 
        ADD COLUMN price DECIMAL(10, 2) NOT NULL DEFAULT 0 
        CHECK (price >= 0);
        
        RAISE NOTICE 'Coluna price adicionada com sucesso à tabela order_items!';
    ELSE
        RAISE NOTICE 'Coluna price já existe na tabela order_items.';
    END IF;
END $$;

-- Verificar a estrutura da tabela após a migração
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'order_items'
ORDER BY ordinal_position;
