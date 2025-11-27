import 'package:meu_app_inicial/data/models/address_dto.dart';
import 'package:meu_app_inicial/domain/entities/address.dart';

class AddressMapper {
  static StateUf _parseUf(String uf) {
    return StateUf.values.firstWhere(
      (e) => e.name.toUpperCase() == uf.toUpperCase(),
      orElse: () => StateUf.sp,
    );
  }

  static Address toEntity(AddressDto dto) {
    return Address(
      id: dto.id,
      street: dto.street.trim(),
      number: dto.number.trim(),
      district: dto.district.trim(),
      city: dto.city.trim(),
      state: _parseUf(dto.state),
      cep: Cep(dto.cep.trim()),
      complement: dto.complement?.trim(),
    );
  }

  static AddressDto toDto(Address entity) {
    return AddressDto(
      id: entity.id,
      street: entity.street,
      number: entity.number,
      district: entity.district,
      city: entity.city,
      state: entity.state.name.toUpperCase(),
      cep: entity.cep.digitsOnly,
      complement: entity.complement,
    );
  }
}


