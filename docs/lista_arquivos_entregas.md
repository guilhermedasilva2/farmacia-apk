# Lista de Arquivos Implementados por Entrega

---

## 🚀 1. Entrega: PRD “Avatar com Foto no Drawer”
**Requisitos:** Foto com fallback, persistência local, compressão/EXIF, acessibilidade, testes.

### 📂 Arquivos Implementados:
- **Interface UI (Drawer):** `lib/features/app/widgets/user_drawer.dart`
  - Linhas 171-240: Widget Avatar visual
  - Linhas 67-109: Lógica de seleção e upload
- **Serviço (Lógica/Persistência/Compressão):** `lib/features/profile/infrastructure/services/avatar_service.dart`
- **Testes Unitários:** `test/avatar_service_test.dart`
- **Testes de Widget:** `test/user_drawer_widget_test.dart`
- **Relatório Reflexivo:** `docs/relatorio_ia_reflexivo.md` (Você deve complementar)

---

## 💾 2. Entrega: Persistência Local (SharedPreferences + Repository)
**Requisitos:** Cache local imediato + Sync incremental, CRUD funcional.

### 📂 Arquivos Implementados (Entidade Principal: Product):
- **Local DAO (Cache):** `lib/features/products/infrastructure/local/products_local_dao.dart`
- **Repository Implementation (Sync):** `lib/features/products/infrastructure/repositories/product_repository_impl.dart`
- **Remote Datasource:** Integrado no próprio Repository (Supabase queries)
- **Integração na Tela (Cache-first):** `lib/features/products/presentation/screens/products_screen.dart`
  - Carregamento inicial do cache e atualização posterior.

---

## 🏗️ 3. Entrega: 4 Novas Entidades (Entity ≠ DTO + Mapper)
**Requisitos:** 4 entidades novas além da vista em aula, com Entity, DTO, Mapper e Teste.

### 📂 Arquivos Implementados (6 Entidades criadas):

**1. Category:**
- Entity: `lib/features/categories/domain/entities/category.dart`
- DTO: `lib/features/categories/infrastructure/dtos/category_dto.dart`
- Mapper: `lib/features/categories/infrastructure/mappers/category_mapper.dart`
- Teste/Exemplo: `test/category_mapper_test.dart`

**2. Order:**
- Entity: `lib/features/orders/domain/entities/order.dart`
- DTO: `lib/features/orders/infrastructure/dtos/order_dto.dart`
- Mapper: `lib/features/orders/infrastructure/mappers/order_mapper.dart`
- Teste/Exemplo: `test/order_mapper_test.dart`

**3. MedicationReminder:**
- Entity: `lib/features/medication_reminders/domain/entities/medication_reminder.dart`
- DTO: `lib/features/medication_reminders/infrastructure/dtos/medication_reminder_dto.dart`
- Mapper: `lib/features/medication_reminders/infrastructure/mappers/medication_reminder_mapper.dart`
- Teste/Exemplo: `test/medication_reminder_mapper_test.dart`

**4. Address:**
- Entity: `lib/features/profile/domain/entities/address.dart`
- DTO: `lib/features/profile/infrastructure/dtos/address_dto.dart`
- Mapper: `lib/features/profile/infrastructure/mappers/address_mapper.dart`
- Teste/Exemplo: `test/address_mapper_test.dart`

---

## 🎯 4. Entrega: Metas Diárias (Adaptada: Lembretes de Medicamentos)
**Status:** ✅ **Implementado**
**Contexto:** Funcionalidade adaptada para o tema Farmácia. A "meta diária" é o cumprimento da adesão ao tratamento medicamentoso (tomar as doses agendadas).

### 📂 Arquivos Implementados:
- **Feature Principal:** `lib/features/medication_reminders/`
- **Listagem e Gestão (Metas):** `lib/features/medication_reminders/presentation/screens/medication_reminders_screen.dart`
  - Exibe lembretes do dia, status de doses tomadas vs programadas.
- **Lógica de Progresso:** `lib/features/medication_reminders/domain/entities/medication_reminder.dart`
  - Campos `totalDoses` e `takenDoses` rastreiam o progresso diário.
- **Interface de Edição/Criação:** `lib/features/medication_reminders/presentation/widgets/medication_reminder_form_dialog.dart`
- **Persistência:** `lib/features/medication_reminders/infrastructure/repositories/medication_reminder_repository_impl.dart`

---

## 🏛️ 5. Entrega: Clean Architecture CRUD UI
**Requisitos:** Estrutura Clean Arch, telas de Listagem, Detalhes, Edição, Remoção via Drawer.

### 📂 Arquivos Implementados:
**Estrutura Geral:** Pastas organizadas em `lib/features/<nome>/domain`, `infrastructure`, `presentation`.

**Telas CRUD (Via Drawer):**
- **Products:**
  - Listagem: `lib/features/products/presentation/screens/products_screen.dart`
  - Detalhes (Dialog): `lib/features/products/presentation/screens/product_details_screen.dart`
  - Edição: `lib/features/products/presentation/screens/admin_products_screen.dart`
- **Categories:**
  - `lib/features/categories/presentation/screens/categories_screen.dart`
- **Navigation (Drawer):** `lib/features/app/widgets/user_drawer.dart`

---

## 🔄 6. Entrega: Supabase + Cache Local (Arquitetura Completa)
**Requisitos:** 1 entidade completa com Supabase + SharedPreferences + Repository + Sync.

### 📂 Arquivos Implementados (Entidade: Product):
- **Repository (Sync Logic):** `lib/features/products/infrastructure/repositories/product_repository_impl.dart`
- **Local Cache:** `lib/features/products/infrastructure/local/products_local_dao.dart`
- **Entity na UI:** `lib/features/products/presentation/screens/products_screen.dart` (Usa `Product` e não `ProductDto`)
- **Mapper:** `lib/features/products/infrastructure/mappers/product_mapper.dart`

---
