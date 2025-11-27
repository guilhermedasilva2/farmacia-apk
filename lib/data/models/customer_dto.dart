class CustomerDto {
  final String id;
  final String name;
  final String email;
  final String? phone;

  const CustomerDto({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory CustomerDto.fromMap(Map<String, dynamic> map) {
    return CustomerDto(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };
}


