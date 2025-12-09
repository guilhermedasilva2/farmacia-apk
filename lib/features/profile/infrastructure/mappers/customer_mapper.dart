import 'package:meu_app_inicial/features/profile/infrastructure/dtos/customer_dto.dart';
import 'package:meu_app_inicial/features/profile/domain/entities/customer.dart';

class CustomerMapper {
  static Customer toEntity(CustomerDto dto) {
    final email = EmailAddress(dto.email.trim());
    return Customer(
      id: CustomerId(dto.id),
      fullName: dto.name.trim(),
      email: email,
      phone: dto.phone?.trim(),
    );
  }

  static CustomerDto toDto(Customer entity) {
    return CustomerDto(
      id: entity.id.value,
      name: entity.fullName,
      email: entity.email.value,
      phone: entity.phone,
    );
  }
}


