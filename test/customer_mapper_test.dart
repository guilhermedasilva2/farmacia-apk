import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/features/profile/infrastructure/dtos/customer_dto.dart';
import 'package:meu_app_inicial/features/profile/infrastructure/mappers/customer_mapper.dart';

void main() {
  test('Customer mapper toEntity/toDto roundtrip', () {
    final dto = CustomerDto(id: 'u1', name: ' Maria Silva ', email: '  maria@example.com ', phone: '  +55 11 99999-0000 ');
    final entity = CustomerMapper.toEntity(dto);
    expect(entity.id.value, 'u1');
    expect(entity.fullName, 'Maria Silva');
    expect(entity.email.isValid, true);
    expect(entity.phone, '+55 11 99999-0000');

    final back = CustomerMapper.toDto(entity);
    expect(back.id, 'u1');
    expect(back.name, 'Maria Silva');
    expect(back.email, 'maria@example.com');
    expect(back.phone, '+55 11 99999-0000');
  });
}


