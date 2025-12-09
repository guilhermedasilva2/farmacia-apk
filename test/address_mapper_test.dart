import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/features/profile/infrastructure/dtos/address_dto.dart';
import 'package:meu_app_inicial/features/profile/infrastructure/mappers/address_mapper.dart';

void main() {
  test('Address mapper toEntity/toDto roundtrip', () {
    final dto = AddressDto(
      id: 'a1',
      street: ' Rua A ',
      number: ' 123 ',
      district: ' Centro ',
      city: ' São Paulo ',
      state: 'sp',
      cep: ' 01001-000 ',
      complement: ' Apt 10 ',
    );
    final entity = AddressMapper.toEntity(dto);
    expect(entity.state.name, 'sp');
    expect(entity.cep.digitsOnly, '01001000');

    final back = AddressMapper.toDto(entity);
    expect(back.state, 'SP');
    expect(back.cep, '01001000');
  });
}


