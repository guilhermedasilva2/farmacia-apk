class CustomerId {
  final String value;
  const CustomerId(this.value) : assert(value != '');
}

class EmailAddress {
  final String value;
  const EmailAddress(this.value);

  bool get isValid => value.contains('@');
}

class Customer {
  final CustomerId id;
  final String fullName;
  final EmailAddress email;
  final String? phone;

  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
  });
}


