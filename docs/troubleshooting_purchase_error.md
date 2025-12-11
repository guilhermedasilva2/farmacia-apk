# Solução para Erro de Compra (Supabase)

## ⚠️ ERRO 1: Coluna 'price' Não Encontrada

### Mensagem de Erro
```
PostgrestException(message: Could not find the 'price' column of 'order_items' 
in the schema cache, code: PGRST204, details: Bad Request, hint: null)
```

### Causa
A tabela `order_items` no Supabase **não possui a coluna `price`**, mas o código do aplicativo está tentando inserir dados nessa coluna.

### ✅ Solução

**Execute este script SQL no Supabase SQL Editor:**

```sql
ALTER TABLE order_items 
ADD COLUMN IF NOT EXISTS price DECIMAL(10, 2) NOT NULL DEFAULT 0 
CHECK (price >= 0);
```

---

## ⚠️ ERRO 2: Coluna 'name' NOT NULL Constraint

### Mensagem de Erro
```
PostgrestException(message: null value in column 'name' of relation 'order_items' 
violates not-null constraint, code: 23502, details: Bad Request, hint: null)
```

### Causa
A coluna `name` existe no Supabase com constraint **NOT NULL**, mas o código não estava enviando esse valor.

### ✅ Solução

**Duas partes:**

1. **Código já corrigido** ✅ - O arquivo [`order_repository_impl.dart`](file:///c:/Cflutter_projetos/meu_app_inicial/lib/features/orders/infrastructure/repositories/order_repository_impl.dart) foi atualizado para enviar o campo `name`

2. **Remover constraint (opcional)** - Execute no Supabase:
   ```sql
   ALTER TABLE order_items 
   ALTER COLUMN name DROP NOT NULL;
   ```

---

## 🚀 Solução Completa (Ambos os Erros)

**Execute este script único no Supabase SQL Editor:**

```sql
-- Adicionar coluna 'price'
ALTER TABLE order_items 
ADD COLUMN IF NOT EXISTS price DECIMAL(10, 2) NOT NULL DEFAULT 0 
CHECK (price >= 0);

-- Remover constraint NOT NULL da coluna 'name'
ALTER TABLE order_items 
ALTER COLUMN name DROP NOT NULL;
```

**Ou use o script completo:** [`fix_order_items_complete.sql`](file:///c:/Cflutter_projetos/meu_app_inicial/docs/migrations/fix_order_items_complete.sql)

### Passos Detalhados

1. **Acesse o Supabase Dashboard** → Seu projeto → **SQL Editor**
2. **Cole e execute** o script SQL acima
3. **Verifique** se as colunas foram criadas/modificadas:
   ```sql
   SELECT column_name, data_type, is_nullable
   FROM information_schema.columns 
   WHERE table_name = 'order_items';
   ```
4. **Reinicie o aplicativo** Flutter (hot restart)
5. **Teste a compra** novamente no aplicativo

---

## Problema Identificado (Geral)
Mensagem vermelha ao tentar finalizar compra, relacionada ao Supabase.

## Causa Provável
O erro ocorre porque as **políticas RLS (Row Level Security)** do Supabase estão bloqueando a criação de pedidos. Especificamente, a política `"Users can create own orders"` verifica se `user_id = auth.uid()`, mas pode estar falhando.

## Solução

### Passo 1: Verificar Autenticação
Certifique-se de que o usuário está autenticado antes de tentar comprar:
- O erro aparece se o usuário não estiver logado
- Verifique se `AuthService().currentUser` não é null

### Passo 2: Executar SQL no Supabase
Execute este comando no **SQL Editor** do Supabase para verificar/corrigir as políticas:

```sql
-- Verificar se a política existe
SELECT * FROM pg_policies WHERE tablename = 'orders';

-- Se necessário, recriar a política de INSERT
DROP POLICY IF EXISTS "Users can create own orders" ON orders;

CREATE POLICY "Users can create own orders" ON orders 
FOR INSERT 
WITH CHECK (user_id = auth.uid());

-- Também garantir que order_items permite inserção
DROP POLICY IF EXISTS "Users can create own order items" ON order_items;

CREATE POLICY "Users can create own order items" ON order_items 
FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders 
    WHERE orders.id = order_items.order_id 
    AND orders.user_id = auth.uid()
  )
);
```

### Passo 3: Verificar Tabela Orders
Certifique-se de que a tabela `orders` existe com a estrutura correta:

```sql
-- Verificar estrutura
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders';

-- Deve ter: id, user_id, total, status, created_at, updated_at
```

### Passo 4: Testar Manualmente
Teste a inserção manual no SQL Editor:

```sql
-- Substitua 'seu-user-id' pelo ID real do usuário autenticado
INSERT INTO orders (user_id, total, status)
VALUES ('seu-user-id', 100.00, 'pending')
RETURNING *;
```

Se este INSERT funcionar, o problema está na autenticação do app.
Se falhar, o problema está nas políticas RLS.

## Verificação Rápida no App

1. Adicione um `debugPrint` no `CartScreen._confirmPurchase`:
```dart
debugPrint('User ID: ${currentUser.id}');
debugPrint('Creating order with ${orderItems.length} items');
```

2. Observe o console quando tentar comprar
3. Se aparecer "User ID: null", o problema é autenticação
4. Se aparecer um ID válido mas ainda der erro, o problema é RLS

## Próximos Passos
Após executar os comandos SQL acima, tente fazer uma compra novamente no app.
