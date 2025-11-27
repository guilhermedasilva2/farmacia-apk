class AddressDto {
  final String id;
  final String street;
  final String number;
  final String district;
  final String city;
  final String state; // UF como string no backend
  final String cep;
  final String? complement;

  const AddressDto({
    required this.id,
    required this.street,
    required this.number,
    required this.district,
    required this.city,
    required this.state,
    required this.cep,
    this.complement,
  });

  factory AddressDto.fromMap(Map<String, dynamic> map) => AddressDto(
        id: (map['id'] ?? '').toString(),
        street: (map['street'] ?? map['logradouro'] ?? '').toString(),
        number: (map['number'] ?? map['numero'] ?? '').toString(),
        district: (map['district'] ?? map['bairro'] ?? '').toString(),
        city: (map['city'] ?? map['cidade'] ?? '').toString(),
        state: (map['state'] ?? map['uf'] ?? '').toString(),
        cep: (map['cep'] ?? '').toString(),
        complement: map['complement'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'street': street,
        'number': number,
        'district': district,
        'city': city,
        'state': state,
        'cep': cep,
        'complement': complement,
      };
}


