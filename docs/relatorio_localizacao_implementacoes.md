# Relatório de Localização das Implementações - Atividades do Curso

**Projeto:** PharmaConnect - Sistema de Farmácia  
**Aluno:** Guilherme da Silva  
**Data:** 11/12/2025

---

## 📍 Atividade 1: Avatar com Foto no Drawer

### Implementação Principal

**Arquivo:** `lib/features/app/widgets/user_drawer.dart`

| Funcionalidade | Linhas | Descrição |
|----------------|--------|-----------|
| Avatar com CircleAvatar | 171-240 | Widget do avatar com prioridade: local → remote → iniciais |
| Seleção de foto | 67-109 | Método `_pick()` - câmera/galeria e upload |
| Carregamento inicial | 50-65 | Método `_init()` - carrega avatar salvo |
| Listener de autenticação | 42-48 | Atualiza avatar ao trocar usuário |
| Modal de opções | 179-213 | Bottom sheet: câmera, galeria, remover |
| Acessibilidade | 171-176 | Semantics e Tooltip |
| Área de toque | 218-219 | ConstrainedBox com minWidth/minHeight 48dp |

### Service de Avatar

**Arquivo:** `lib/features/profile/infrastructure/services/avatar_service.dart`

| Funcionalidade | Descrição |
|----------------|-----------|
| Compressão de imagem | Reduz tamanho do arquivo |
| Remoção de EXIF/GPS | Remove metadados sensíveis |
| Persistência local | SharedPreferences para caminho |
| Upload para Supabase | Envia foto para servidor |
| Geração de iniciais | Método `initialsFromName()` |

### Testes

**Arquivo:** `test/avatar_service_test.dart`
- Testes unitários do AvatarService

**Arquivo:** `test/user_drawer_widget_test.dart`
- Testes de widget do drawer
- Testa renderização de iniciais
- Testa exibição de imagem

---

## 📍 Atividade 2: Persistência Local com SharedPreferences + Repository

### DAOs Locais Implementados

#### 1. Products DAO
**Arquivo:** `lib/features/products/infrastructure/local/products_local_dao.dart`

| Método | Linhas | Descrição |
|--------|--------|-----------|
| `listAll()` | 22-39 | Lista produtos do cache com validação de expiração |
| `upsert()` | 42-53 | Insere ou atualiza um produto |
| `upsertAll()` | 56-66 | Insere ou atualiza múltiplos produtos |
| `remove()` | 69-73 | Remove produto por ID |
| `clear()` | 76-79 | Limpa todo o cache |
| `_isCacheExpired()` | 82-90 | Verifica expiração (1 hora) |
| `hasValidCache()` | 93-96 | Valida existência e expiração |

#### 2. Categories DAO
**Arquivo:** `lib/features/categories/infrastructure/local/categories_local_dao.dart`
- Mesma estrutura do ProductsLocalDao
- Cache de categorias com expiração

#### 3. Orders DAO
**Arquivo:** `lib/features/orders/infrastructure/local/orders_local_dao.dart`
- Cache de pedidos do usuário
- Sincronização com histórico remoto

### Repository Pattern

**Arquivo:** `lib/features/products/infrastructure/repositories/product_repository_impl.dart`

| Componente | Descrição |
|------------|-----------|
| Interface | `ProductRepository` no domain layer |
| Implementação | `ProductRepositoryImpl` integra local + remote |
| Local DataSource | `SharedPreferencesProductLocalDataSource` (linha 362+) |
| Remote DataSource | Supabase queries |
| Mapper | `ProductMapper` para conversão DTO ↔ Entity |

### Cache-First Strategy

**Arquivo:** `lib/features/products/presentation/screens/products_screen.dart`

| Linha | Código | Descrição |
|-------|--------|-----------|
| ~59 | `final local = await SharedPreferencesProductLocalDataSource.create()` | Cria datasource local |
| ~60 | `final cached = await local.getAll()` | Carrega cache |
| ~61 | `setState(() => _products = cached)` | Atualiza UI imediatamente |
| ~65+ | `final remote = await _repository.listProducts()` | Sync em background |
| ~66+ | `await local.saveAll(remote)` | Atualiza cache |
| ~67+ | `setState(() => _products = remote)` | Atualiza UI novamente |

### Testes

**Arquivo:** `test/product_local_dao_test.dart`
- Testa cache corrupto (auto-healing)
- Testa merge de DTOs por ID

**Arquivo:** `test/cached_product_repository_test.dart`
- Testa integração repository + cache

---

## 📍 Atividade 3: Entity ≠ DTO + Mapper (6 Entidades)

### 1. Product (Produto)

**Entity:** `lib/features/products/domain/entities/product.dart`
- Tipos fortes: `double price`, `bool available`, `int quantity`
- Invariantes de domínio
- Método `copyWith()`

**DTO:** `lib/features/products/infrastructure/dtos/product_dto.dart`
- Fiel ao schema Supabase
- Tipos nullable: `num? price`, `bool? available`
- Métodos `fromJson()` e `toJson()`

**Mapper:** `lib/features/products/infrastructure/mappers/product_mapper.dart`

| Método | Linhas | Descrição |
|--------|--------|-----------|
| `fromDto()` | 5-24 | DTO → Entity com conversões seguras |
| `toDto()` | 30-41 | Entity → DTO |
| `fromDtoList()` | 26-28 | Conversão de listas |

**Teste:** `test/product_mapper_test.dart`
- Testa conversão de tipos (num → double)
- Testa valores nullable

---

### 2. Category (Categoria)

**Entity:** `lib/features/categories/domain/entities/category.dart`
- Geração automática de slug

**DTO:** `lib/features/categories/infrastructure/dtos/category_dto.dart`
- Campo `slug` opcional

**Mapper:** `lib/features/categories/infrastructure/mappers/category_mapper.dart`
- Normalização de slug: `name.toLowerCase().replaceAll(' ', '-')`

**Teste:** `test/category_mapper_test.dart`
- Testa geração automática de slug

---

### 3. Order (Pedido)

**Entity:** `lib/features/orders/domain/entities/order.dart`
- Enum `OrderStatus` para estados
- Lista de `OrderItem` (composição)

**DTO:** `lib/features/orders/infrastructure/dtos/order_dto.dart`
- Relacionamentos: `customerId`, `items`
- Timestamps: `createdAt`, `updatedAt`

**Mapper:** `lib/features/orders/infrastructure/mappers/order_mapper.dart`
- Conversão de enum: String ↔ OrderStatus
- Conversão de timestamps: String ↔ DateTime

**Teste:** `test/order_mapper_test.dart`
- Testa roundtrip com clamping

---

### 4. MedicationReminder (Lembrete)

**Entity:** `lib/features/medication_reminders/domain/entities/medication_reminder.dart`
- Invariantes: `takenDoses <= totalDoses`
- Propriedades calculadas: `isCompleted`, `progress`

**DTO:** `lib/features/medication_reminders/infrastructure/dtos/medication_reminder_dto.dart`
- Timestamps ISO 8601

**Mapper:** `lib/features/medication_reminders/infrastructure/mappers/medication_reminder_mapper.dart`
- Conversão complexa de timestamps

**Teste:** `test/medication_reminder_mapper_test.dart`
- Testa validação de doses

---

### 5. Address (Endereço)

**Entity:** `lib/features/profile/domain/entities/address.dart`
- Validação de CEP
- Formatação de endereço completo

**DTO:** `lib/features/profile/infrastructure/dtos/address_dto.dart`
- Campos de endereço brasileiro completo

**Mapper:** `lib/features/profile/infrastructure/mappers/address_mapper.dart`
- Normalização de CEP

**Teste:** `test/address_mapper_test.dart`
- Testa normalização e campos opcionais

---

### 6. Customer (Cliente)

**Entity:** `lib/features/profile/domain/entities/customer.dart`
- Validação de CPF
- Relacionamento com Address

**DTO:** `lib/features/profile/infrastructure/dtos/customer_dto.dart`
- Perfil completo do cliente

**Mapper:** `lib/features/profile/infrastructure/mappers/customer_mapper.dart`
- Conversão de CPF e datas

**Teste:** `test/customer_mapper_test.dart`
- Testa validação de CPF

---

## 📍 Atividade 4: Clean Architecture CRUD UI

### Estrutura de Pastas (Clean Architecture)

```
lib/features/<feature>/
├── domain/
│   ├── entities/          ← Entities puras
│   └── repositories/      ← Interfaces
├── infrastructure/
│   ├── dtos/             ← Data Transfer Objects
│   ├── mappers/          ← Conversores DTO ↔ Entity
│   ├── repositories/     ← Implementações
│   ├── services/         ← APIs externas
│   └── local/            ← DAOs locais
└── presentation/
    ├── screens/          ← Telas
    └── widgets/          ← Componentes
```

### 1. Products CRUD

**Listagem:** `lib/features/products/presentation/screens/products_screen.dart`

| Funcionalidade | Descrição |
|----------------|-----------|
| Grid/List view | Exibição de produtos |
| Busca em tempo real | Filtro por nome |
| Filtros | Categoria, disponibilidade |
| Ordenação | Nome, preço, quantidade |
| Pull-to-refresh | Atualização manual |
| Shimmer loading | Loading state |

**Detalhes:** `lib/features/products/presentation/screens/product_details_screen.dart`
- Visualização completa
- Botões: FECHAR, EDITAR, REMOVER

**Edição:** `lib/features/products/presentation/screens/admin_products_screen.dart`
- Formulário completo
- Upload de imagem
- Validações

**Acesso via Drawer:** `lib/features/app/widgets/user_drawer.dart` (linhas 400-410)

---

### 2. Categories CRUD

**Listagem:** `lib/features/categories/presentation/screens/categories_screen.dart`
- Lista com ícones
- Contador de produtos
- Pull-to-refresh

**Acesso via Drawer:** `lib/features/app/widgets/user_drawer.dart` (linhas 420-428)

---

### 3. Orders CRUD

**Listagem:** `lib/features/orders/presentation/screens/orders_screen.dart`
- Histórico de pedidos
- Status visual
- Filtro por status

**Detalhes:** `lib/features/orders/presentation/screens/order_details_screen.dart`
- Informações completas
- Lista de items
- Endereço de entrega

**Criação:** `lib/features/orders/presentation/screens/cart_screen.dart`
- Carrinho de compras
- Checkout

**Acesso via Drawer:** `lib/features/app/widgets/user_drawer.dart` (linhas 377-385)

---

### 4. Medication Reminders CRUD

**Listagem:** `lib/features/medication_reminders/presentation/screens/medication_reminders_screen.dart`
- Lista de lembretes
- Progresso de doses
- Filtros

**Edição:** `lib/features/medication_reminders/presentation/widgets/medication_reminder_form_dialog.dart`
- Formulário completo
- Configuração de notificações

**Acesso via Drawer:** `lib/features/app/widgets/user_drawer.dart` (linhas 387-395)

---

## 📍 Atividade 5: Supabase + Cache Local

### 1. Products (Entidade Principal)

**Repository:** `lib/features/products/infrastructure/repositories/product_repository_impl.dart`

| Componente | Descrição |
|------------|-----------|
| Remote (Supabase) | Queries: select, insert, update, delete |
| Local (SharedPreferences) | `ProductsLocalDao` |
| Sincronização | Cache-first strategy |
| Mapper | `ProductMapper` (DTO ↔ Entity) |

**Fluxo de Sincronização:**
```dart
// 1. Cache primeiro (imediato)
final cached = await _localDao.listAll();
setState(() => _products = ProductMapper.fromDtoList(cached));

// 2. Sync em background
final remote = await _supabase.from('products').select();
final dtos = remote.map((json) => ProductDto.fromJson(json)).toList();

// 3. Atualiza cache
await _localDao.upsertAll(dtos);

// 4. Atualiza UI
final entities = ProductMapper.fromDtoList(dtos);
setState(() => _products = entities);
```

**Logs de Debug:**
- `debugPrint('Loading from cache...')`
- `debugPrint('Syncing with server...')`
- `debugPrint('Cache updated')`

**Tratamento de Erros:**
- Try-catch em todas operações
- Fallback para cache em caso de erro
- SnackBars com mensagens amigáveis

---

### 2. Categories

**Repository:** `lib/features/categories/infrastructure/repositories/category_repository_impl.dart`
- Mesma arquitetura completa
- `CategoriesLocalDao` + Supabase
- Sincronização bidirecional

---

### 3. Orders

**Repository:** `lib/features/orders/infrastructure/repositories/order_repository_impl.dart`
- `OrdersLocalDao` + Supabase
- Push de novos pedidos
- Pull de histórico

---

## 📊 Resumo de Arquivos por Atividade

### Atividade 1: Avatar (3 arquivos principais)
1. `lib/features/app/widgets/user_drawer.dart`
2. `lib/features/profile/infrastructure/services/avatar_service.dart`
3. `test/avatar_service_test.dart`
4. `test/user_drawer_widget_test.dart`

### Atividade 2: Persistência (9 arquivos)
1. `lib/features/products/infrastructure/local/products_local_dao.dart`
2. `lib/features/categories/infrastructure/local/categories_local_dao.dart`
3. `lib/features/orders/infrastructure/local/orders_local_dao.dart`
4. `lib/features/products/infrastructure/repositories/product_repository_impl.dart`
5. `test/product_local_dao_test.dart`
6. `test/cached_product_repository_test.dart`

### Atividade 3: Entity/DTO/Mapper (18 arquivos - 6 entidades × 3)
**Products:**
1. `lib/features/products/domain/entities/product.dart`
2. `lib/features/products/infrastructure/dtos/product_dto.dart`
3. `lib/features/products/infrastructure/mappers/product_mapper.dart`
4. `test/product_mapper_test.dart`

**Categories:**
5. `lib/features/categories/domain/entities/category.dart`
6. `lib/features/categories/infrastructure/dtos/category_dto.dart`
7. `lib/features/categories/infrastructure/mappers/category_mapper.dart`
8. `test/category_mapper_test.dart`

**Orders:**
9. `lib/features/orders/domain/entities/order.dart`
10. `lib/features/orders/infrastructure/dtos/order_dto.dart`
11. `lib/features/orders/infrastructure/mappers/order_mapper.dart`
12. `test/order_mapper_test.dart`

**MedicationReminders:**
13. `lib/features/medication_reminders/domain/entities/medication_reminder.dart`
14. `lib/features/medication_reminders/infrastructure/dtos/medication_reminder_dto.dart`
15. `lib/features/medication_reminders/infrastructure/mappers/medication_reminder_mapper.dart`
16. `test/medication_reminder_mapper_test.dart`

**Address:**
17. `lib/features/profile/domain/entities/address.dart`
18. `lib/features/profile/infrastructure/dtos/address_dto.dart`
19. `lib/features/profile/infrastructure/mappers/address_mapper.dart`
20. `test/address_mapper_test.dart`

**Customer:**
21. `lib/features/profile/domain/entities/customer.dart`
22. `lib/features/profile/infrastructure/dtos/customer_dto.dart`
23. `lib/features/profile/infrastructure/mappers/customer_mapper.dart`
24. `test/customer_mapper_test.dart`

### Atividade 4: Clean Arch CRUD (12+ arquivos)
**Products:**
1. `lib/features/products/presentation/screens/products_screen.dart`
2. `lib/features/products/presentation/screens/product_details_screen.dart`
3. `lib/features/products/presentation/screens/admin_products_screen.dart`

**Categories:**
4. `lib/features/categories/presentation/screens/categories_screen.dart`

**Orders:**
5. `lib/features/orders/presentation/screens/orders_screen.dart`
6. `lib/features/orders/presentation/screens/order_details_screen.dart`
7. `lib/features/orders/presentation/screens/cart_screen.dart`

**Medication Reminders:**
8. `lib/features/medication_reminders/presentation/screens/medication_reminders_screen.dart`
9. `lib/features/medication_reminders/presentation/widgets/medication_reminder_form_dialog.dart`

**Navegação:**
10. `lib/features/app/widgets/user_drawer.dart`
11. `lib/utils/app_routes.dart`

### Atividade 5: Supabase + Cache (6 arquivos principais)
1. `lib/features/products/infrastructure/repositories/product_repository_impl.dart`
2. `lib/features/products/infrastructure/local/products_local_dao.dart`
3. `lib/features/categories/infrastructure/repositories/category_repository_impl.dart`
4. `lib/features/categories/infrastructure/local/categories_local_dao.dart`
5. `lib/features/orders/infrastructure/repositories/order_repository_impl.dart`
6. `lib/features/orders/infrastructure/local/orders_local_dao.dart`

---

## 📝 Total de Arquivos Implementados

| Categoria | Quantidade |
|-----------|------------|
| Entities | 6 |
| DTOs | 6 |
| Mappers | 6 |
| DAOs Locais | 3 |
| Repositories | 6 |
| Screens | 12+ |
| Services | 5+ |
| Testes | 13 |
| **TOTAL** | **57+ arquivos** |

---

**Assinatura:** Guilherme da Silva  
**Data:** 11/12/2025
