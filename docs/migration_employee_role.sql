-- ============================================
-- ATUALIZAÇÃO DO SCHEMA - Suporte para Role 'employee'
-- Data: 10/12/2024
-- ============================================

-- 1. Atualizar a constraint da tabela profiles para incluir 'employee'
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('visitor', 'user', 'employee', 'admin'));

-- 2. Adicionar políticas RLS para employees gerenciarem produtos
-- Employees podem inserir produtos
CREATE POLICY "Employees can insert products" ON products FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

-- Employees podem atualizar produtos
CREATE POLICY "Employees can update products" ON products FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

-- Employees podem deletar produtos
CREATE POLICY "Employees can delete products" ON products FOR DELETE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

-- 3. Adicionar políticas RLS para employees gerenciarem categorias
CREATE POLICY "Employees can insert categories" ON categories FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

CREATE POLICY "Employees can update categories" ON categories FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

CREATE POLICY "Employees can delete categories" ON categories FOR DELETE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

-- 4. Adicionar políticas RLS para employees gerenciarem pedidos
CREATE POLICY "Employees can view all orders" ON orders FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

CREATE POLICY "Employees can update all orders" ON orders FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'employee'))
);

-- NOTA: Execute este script no SQL Editor do Supabase APÓS executar o database_schema.sql principal
-- Isso garantirá que o role 'employee' seja suportado e que funcionários tenham as permissões adequadas
