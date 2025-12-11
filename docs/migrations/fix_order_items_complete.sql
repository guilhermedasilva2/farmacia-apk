-- ============================================
-- MIGRAÇÃO COMPLETA: Corrigir tabela order_items
-- Data: 2025-12-11
-- Descrição: Adiciona coluna 'price' e remove NOT NULL de 'name'
-- ============================================

-- PASSO 1: Adicionar coluna 'price' se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'order_items' 
        AND column_name = 'price'
    ) THEN
        ALTER TABLE order_items 
        ADD COLUMN price DECIMAL(10, 2) NOT NULL DEFAULT 0 
        CHECK (price >= 0);
        
        RAISE NOTICE 'Coluna price adicionada com sucesso!';
    ELSE
        RAISE NOTICE 'Coluna price já existe.';
    END IF;
END $$;

-- PASSO 2: Verificar se coluna 'name' existe e tem constraint NOT NULL
DO $$ 
BEGIN
    -- Se a coluna 'name' existir, remover a constraint NOT NULL
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'order_items' 
        AND column_name = 'name'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE order_items 
        ALTER COLUMN name DROP NOT NULL;
        
        RAISE NOTICE 'Constraint NOT NULL removida da coluna name!';
    ELSE
        RAISE NOTICE 'Coluna name já permite NULL ou não existe.';
    END IF;
END $$;

-- PASSO 3: Verificar estrutura final
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'order_items'
ORDER BY ordinal_position;
