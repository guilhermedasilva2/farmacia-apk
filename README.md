# PharmaConnect 💊

Aplicativo móvel para gestão farmacêutica e lembretes de medicação, desenvolvido em Flutter seguindo os princípios da **Clean Architecture**.

## 📋 Sobre o Projeto

O **PharmaConnect** é uma solução completa que atende tanto a clientes quanto a administradores de farmácias. O app permite que usuários comprem produtos, gerenciem seus pedidos e configurem lembretes para seus medicamentos. Para administradores, oferece um painel robusto para gestão de estoque, categorias e pedidos.

## 🚀 Funcionalidades

### 👤 Para Usuários
- **Catálogo de Produtos:** Navegação por categorias e busca de medicamentos/produtos.
- **Carrinho e Compras:** Fluxo completo de compra com baixa automática de estoque.
- **Meus Pedidos:** Acompanhamento do status dos pedidos (Pendente, Pago, Enviado, Entregue).
- **Lembretes de Medicação:**
    - Agendamento de horários.
    - Controle de doses tomadas.
    - Alertas visuais.
- **Perfil:** Gerenciamento de dados pessoais e avatar.

### 🛡️ Para Administradores
- **Gestão de Estoque:**
    - Listagem, Adição, Edição e Remoção de produtos.
    - Controle de quantidade e disponibilidade.
- **Gestão de Categorias:**
    - Organização de produtos em categorias dinâmicas.
- **Gestão de Pedidos:**
    - Visualização de todos os pedidos.
    - Atualização de status (ex: marcar como Enviado).
    - Cancelamento/Exclusão de pedidos.

## 🏗️ Arquitetura

O projeto segue estritamente a **Clean Architecture**, garantindo desacoplamento e testabilidade:

```
lib/
├── core/           # Utilitários, constantes e configurações globais
├── domain/         # Camada mais interna (Regras de Negócio)
│   ├── entities/   # Objetos de negócio puros
│   └── repositories/# Interfaces (contratos) dos repositórios
├── data/           # Camada de Dados
│   ├── models/     # DTOs (Data Transfer Objects) e Mappers
│   ├── datasources/# Fontes de dados (Supabase, SharedPreferences)
│   └── repositories/# Implementação concreta dos repositórios
└── presentation/   # Camada de Interface (UI)
    ├── screens/    # Telas do aplicativo
    └── widgets/    # Componentes reutilizáveis
```

## 🛠️ Tecnologias Utilizadas

- **Flutter:** Framework UI.
- **Supabase:** Backend as a Service (Auth, Database, Realtime).
- **PostgreSQL:** Banco de dados (via Supabase).
- **Clean Architecture:** Padrão arquitetural.
- **Provider/ChangeNotifier:** Gerenciamento de estado simples e eficiente.
- **SharedPreferences:** Persistência local leve.

## 🔄 Sincronização e Offline

O aplicativo implementa um sistema robusto de sincronização de dados:

### Sincronização Bidirecional (Push + Pull)
- **Push Sync:** Envia mudanças locais para o servidor (cache → Supabase)
- **Pull Sync:** Busca atualizações remotas desde a última sincronização
- **Resolução de Conflitos:** Last-Write-Wins baseado em `updated_at`
- **Best-Effort:** Falhas de push não bloqueiam o pull

### Sincronização Incremental
- Baixa apenas dados modificados desde `lastSync`
- Economiza banda e bateria
- Timestamp armazenado em `SharedPreferences`

### Paginação
- Suporte a paginação com `PageCursor` (offset ou token)
- `RemotePage<T>` genérico para respostas paginadas
- Limite configurável (padrão: 100 itens/página)
- Cálculo automático de próxima página

### Cache Local
- Todos os produtos cacheados localmente
- Navegação offline completa
- Sincronização automática em pull-to-refresh

### Logging
- Logs detalhados em modo debug (`kDebugMode`)
- Monitoramento de push/pull/paginação
- Exemplos:
  ```
  CachedProductRepository: Pushing 10 items to remote...
  CachedProductRepository: Pulled 3 items from server.
  ```


## 🎨 Melhorias Visuais Implementadas

### Design Moderno
- ✨ **Gradientes vibrantes** no AppBar (teal → cyan)
- ✍️ **Google Fonts Poppins** para tipografia premium
- 🔲 **Bordas arredondadas** (16px) em todos os cards
- 🎭 **Sombras coloridas** sutis em teal
- 🌈 **Fundo cinza claro** para melhor contraste

### Animações e Interações
- 🎬 **Hero Animations** - transições suaves entre telas
- ✨ **Shimmer Loading** - skeleton screens profissionais
- ♾️ **Scroll bidirecional infinito** nos carrosséis
- 💬 **Snackbars customizadas** com ícones e cores

### UX Melhorada
- 🛒 **Badge "99+"** no carrinho para grandes quantidades
- 📱 **Layout organizado** com hierarquia visual clara
- 🔍 **Campo de busca premium** com bordas animadas
- 👤 **Loading no drawer** (sem flash de "Visitante")


## ⚙️ Configuração e Instalação

### Pré-requisitos
- Flutter SDK instalado.
- Conta no Supabase.

### Configuração do Banco de Dados
O esquema do banco de dados está disponível em `docs/database_schema.sql`.
1. Crie um novo projeto no Supabase.
2. Vá até o **SQL Editor**.
3. Copie e execute o conteúdo de `docs/database_schema.sql`.

### Executando o App
1. Clone o repositório.
2. Crie um arquivo `.env` ou configure as chaves do Supabase em `lib/main.dart` (ou onde estiver a inicialização).
3. Execute:
   ```bash
   flutter pub get
   flutter run
   ```

## 📚 Documentação Adicional
- **Esquema do Banco:** `docs/database_schema.sql`
- **Apresentação:** `docs/apresentacao.md`

---
Desenvolvido como parte do projeto final de Desenvolvimento Mobile.
