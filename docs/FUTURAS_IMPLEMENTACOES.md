# 💡 Ideias para Futuras Implementações - Sistema de Pedidos

Este documento contém ideias e sugestões de melhorias para o sistema de pedidos do aplicativo PharmaConnect.

---

## 📋 Funcionalidades Essenciais

### 1. Histórico de Pedidos Confirmados ⭐ **PRIORIDADE ALTA**

**Descrição**: Mostrar todos os pedidos que o usuário já confirmou com informações detalhadas.

**Funcionalidades**:
- Lista de todos os pedidos realizados
- Exibir data de criação
- Status do pedido (pendente, pago, enviado, entregue, cancelado)
- Ver detalhes de cada pedido (produtos, quantidades, valores)
- Filtrar por status ou período (último mês, últimos 3 meses, etc.)
- Buscar pedidos por produto ou data

**Implementação Sugerida**:
- Criar `OrderHistoryScreen`
- Buscar pedidos do usuário atual no banco de dados
- Usar `OrderRepository.getOrdersByCustomerId()`
- Card para cada pedido com resumo
- Tela de detalhes ao clicar no pedido

**Estimativa**: 4-6 horas

---

### 2. Persistência do Carrinho 💾 **PRIORIDADE ALTA**

**Descrição**: Salvar os produtos no carrinho para não perder ao fechar o app.

**Opções de Implementação**:

**Opção A - Local (SharedPreferences)**:
- Salvar JSON do carrinho localmente
- Carregar ao iniciar o app
- Mais rápido, funciona offline

**Opção B - Banco de Dados (Supabase)**:
- Criar tabela `cart_items`
- Sincronizar com servidor
- Acessível de qualquer dispositivo

**Implementação Sugerida**:
- Modificar `CartService` para salvar automaticamente
- Adicionar métodos `saveToStorage()` e `loadFromStorage()`
- Chamar ao adicionar/remover itens

**Estimativa**: 2-3 horas (local) ou 4-5 horas (servidor)

---

### 3. Favoritos/Lista de Desejos ❤️ **PRIORIDADE MÉDIA**

**Descrição**: Permitir que usuários marquem produtos favoritos para comprar depois.

**Funcionalidades**:
- Botão de "coração" nos cards de produtos
- Seção "Meus Favoritos" no drawer ou tela separada
- Adicionar favoritos ao pedido rapidamente
- Notificar quando favorito estiver em promoção

**Implementação Sugerida**:
- Criar tabela `favorites` no banco
- Adicionar `FavoriteService` singleton
- Ícone de coração nos produtos (outline/filled)
- Tela `FavoritesScreen` similar ao catálogo

**Estimativa**: 5-7 horas

---

## 💡 Melhorias de UX

### 4. Cupons de Desconto 🎟️

**Descrição**: Sistema de cupons promocionais para desconto nas compras.

**Funcionalidades**:
- Campo para inserir código de cupom na tela de pedidos
- Validar cupom (verificar se existe, está ativo, não expirou)
- Aplicar desconto (percentual ou valor fixo)
- Mostrar economia no resumo
- Remover cupom aplicado

**Implementação Sugerida**:
- Criar tabela `coupons` (code, discount_type, discount_value, expiry_date, active)
- Adicionar campo de cupom em `CartScreen`
- Validar antes de confirmar compra
- Salvar cupom usado no pedido

**Estimativa**: 6-8 horas

---

### 5. Métodos de Pagamento 💳

**Descrição**: Selecionar e gerenciar formas de pagamento.

**Funcionalidades**:
- Selecionar forma de pagamento (cartão, PIX, boleto)
- Salvar cartões para uso futuro (tokenização)
- Integração com gateway de pagamento (Stripe, Mercado Pago, PagSeguro)
- Gerar QR Code PIX
- Gerar boleto bancário

**Implementação Sugerida**:
- Criar tela `PaymentMethodScreen`
- Integrar SDK do gateway escolhido
- Criar tabela `payment_methods` para salvar cartões
- Adicionar step de pagamento antes de confirmar pedido

**Estimativa**: 12-16 horas (complexo)

---

### 6. Endereço de Entrega 📍

**Descrição**: Gerenciar endereços de entrega e calcular frete.

**Funcionalidades**:
- Cadastrar múltiplos endereços
- Selecionar endereço de entrega
- Marcar endereço padrão
- Buscar endereço por CEP (API ViaCEP)
- Calcular frete baseado no CEP (integração Correios ou Melhor Envio)
- Mostrar prazo de entrega

**Implementação Sugerida**:
- Criar tabela `addresses`
- Tela `AddressManagementScreen`
- Integrar API ViaCEP para busca automática
- Integrar API de frete
- Adicionar seleção de endereço no checkout

**Estimativa**: 10-12 horas

---

## 🚀 Funcionalidades Avançadas

### 7. Rastreamento de Pedido 📦

**Descrição**: Acompanhar status e localização do pedido em tempo real.

**Funcionalidades**:
- Timeline visual mostrando status do pedido
- Notificações push quando status mudar
- Código de rastreamento dos Correios
- Integração com API dos Correios para rastreamento
- Estimativa de entrega

**Implementação Sugerida**:
- Adicionar campo `tracking_code` na tabela orders
- Criar `OrderTrackingScreen` com timeline
- Integrar API dos Correios
- Configurar Firebase Cloud Messaging para notificações
- Atualizar status via admin panel

**Estimativa**: 8-10 horas

---

### 8. Pedidos Recorrentes 🔄

**Descrição**: Facilitar recompra de produtos frequentes.

**Funcionalidades**:
- Botão "Comprar Novamente" em pedidos anteriores
- Assinatura de produtos (entrega mensal automática)
- Sugestões baseadas em compras anteriores
- Gerenciar assinaturas ativas

**Implementação Sugerida**:
- Adicionar botão no histórico de pedidos
- Criar tabela `subscriptions` para assinaturas
- Cron job para processar assinaturas mensais
- Tela de gerenciamento de assinaturas

**Estimativa**: 10-14 horas

---

### 9. Avaliações e Reviews ⭐

**Descrição**: Sistema de avaliação de produtos.

**Funcionalidades**:
- Avaliar produtos comprados (1-5 estrelas)
- Escrever comentário
- Upload de fotos dos produtos
- Ver avaliações de outros usuários
- Média de avaliações no card do produto
- Filtrar produtos por avaliação

**Implementação Sugerida**:
- Criar tabela `product_reviews`
- Adicionar tela de avaliação após entrega
- Mostrar reviews na tela de detalhes do produto
- Calcular média de avaliações
- Moderar reviews (admin)

**Estimativa**: 8-10 horas

---

## 📊 Analytics e Gamificação

### 10. Programa de Pontos/Cashback 🎁

**Descrição**: Sistema de fidelidade com pontos e recompensas.

**Funcionalidades**:
- Ganhar pontos a cada compra (ex: 1 ponto = R$ 1)
- Trocar pontos por descontos
- Níveis de fidelidade (bronze, prata, ouro, platina)
- Benefícios por nível (frete grátis, desconto extra)
- Histórico de pontos

**Implementação Sugerida**:
- Criar tabela `loyalty_points` e `loyalty_levels`
- Adicionar pontos ao confirmar pedido
- Tela de pontos e recompensas
- Permitir usar pontos como desconto
- Calcular nível baseado em pontos acumulados

**Estimativa**: 12-15 horas

---

### 11. Estatísticas Pessoais 📈

**Descrição**: Dashboard com estatísticas de compras do usuário.

**Funcionalidades**:
- Total gasto no mês/ano
- Produtos mais comprados
- Economia com cupons
- Gráficos de gastos por categoria
- Comparativo mensal
- Metas de economia

**Implementação Sugerida**:
- Criar `StatisticsScreen`
- Queries agregadas no banco
- Usar biblioteca de gráficos (fl_chart)
- Calcular métricas (total, média, economia)
- Cards visuais com informações

**Estimativa**: 6-8 horas

---

## 🔔 Notificações e Lembretes

### 12. Lembretes de Recompra 🔔

**Descrição**: Notificações inteligentes para recompra de produtos.

**Funcionalidades**:
- Lembrar de recomprar medicamentos periódicos
- Notificar quando produto favorito estiver em promoção
- Alertar quando estoque de produto favorito estiver baixo
- Sugestões personalizadas baseadas em histórico
- Configurar frequência de lembretes

**Implementação Sugerida**:
- Firebase Cloud Messaging para notificações
- Criar tabela `reminders`
- Cron job para verificar e enviar lembretes
- Tela de configuração de lembretes
- Calcular periodicidade baseada em compras anteriores

**Estimativa**: 10-12 horas

---

## 🎯 Roadmap Sugerido

### Fase 1 - Essencial (2-3 semanas)
1. ✅ Sistema de Pedidos Básico (Implementado)
2. Persistência do Carrinho
3. Histórico de Pedidos

### Fase 2 - Melhorias (3-4 semanas)
4. Favoritos/Lista de Desejos
5. Cupons de Desconto
6. Endereço de Entrega

### Fase 3 - Avançado (4-6 semanas)
7. Métodos de Pagamento
8. Rastreamento de Pedido
9. Avaliações e Reviews

### Fase 4 - Engajamento (3-4 semanas)
10. Programa de Pontos
11. Estatísticas Pessoais
12. Lembretes de Recompra
13. Pedidos Recorrentes

---

## 📝 Notas de Implementação

### Considerações Técnicas

- **Performance**: Implementar paginação em listas longas (histórico, favoritos)
- **Cache**: Usar cache local para dados frequentes
- **Offline**: Considerar modo offline para funcionalidades críticas
- **Segurança**: Validar dados no backend, nunca confiar apenas no frontend
- **Testes**: Adicionar testes unitários e de integração

### Dependências Úteis

```yaml
# Gráficos e visualização
fl_chart: ^0.66.0

# Notificações
firebase_messaging: ^14.7.9
flutter_local_notifications: ^16.3.0

# Pagamentos
stripe_flutter: ^10.1.0
# ou
mercado_pago: ^1.0.0

# QR Code
qr_flutter: ^4.1.0

# Busca de CEP
dio: ^5.4.0 # para chamadas HTTP

# Imagens
image_picker: ^1.0.7
cached_network_image: ^3.3.1
```

---

## 🤝 Contribuições

Este documento é um guia vivo e pode ser atualizado conforme novas ideias surgirem ou prioridades mudarem.

**Última atualização**: 2025-11-27
