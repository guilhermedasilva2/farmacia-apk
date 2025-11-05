# Checklist de Entidades (Entity ≠ DTO + Mapper)

Este documento lista as quatro entidades implementadas, com seus respectivos DTOs, Mappers (toEntity/toDto) e testes de conversão.

## Customer
- Entity: `lib/models/customer.dart`
- DTO: `lib/dto/customer_dto.dart`
- Mapper: `lib/mappers/customer_mapper.dart` (toEntity/toDto)
- Teste: `test/customer_mapper_test.dart`

## Address
- Entity: `lib/models/address.dart` (inclui `StateUf` enum e `Cep`)
- DTO: `lib/dto/address_dto.dart`
- Mapper: `lib/mappers/address_mapper.dart` (toEntity/toDto, normaliza UF e CEP)
- Teste: `test/address_mapper_test.dart`

## Category
- Entity: `lib/models/category.dart`
- DTO: `lib/dto/category_dto.dart`
- Mapper: `lib/mappers/category_mapper.dart` (toEntity/toDto, slugify quando ausente)
- Teste: `test/category_mapper_test.dart`

## Order / OrderItem
- Entities: `lib/models/order.dart` (inclui invariantes e `OrderStatus`)
- DTOs: `lib/dto/order_dto.dart` (estrutura aninhada)
- Mapper: `lib/mappers/order_mapper.dart` (toEntity/toDto, clamp de quantity/unitPrice, status enum)
- Teste: `test/order_mapper_test.dart`

## Observações
- DTOs espelham o schema remoto com tipos simples (text/num).
- Entities usam tipos fortes e invariantes de domínio.
- Mappers centralizam apenas conversões/normalizações (sem regra de negócio) e expõem toEntity/toDto.
- Os testes cobrem ciclo ida/volta e casos de borda.


