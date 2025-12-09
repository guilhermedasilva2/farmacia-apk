enum StateUf { ac, al, ap, am, ba, ce, df, es, go, ma, mt, ms, mg, pa, pb, pr, pe, pi, rj, rn, rs, ro, rr, sc, sp, se, to }

class Cep {
  final String value;
  const Cep(this.value);
  String get digitsOnly => value.replaceAll(RegExp(r'\D'), '');
}

class Address {
  final String id;
  final String street;
  final String number;
  final String district;
  final String city;
  final StateUf state;
  final Cep cep;
  final String? complement;

  const Address({
    required this.id,
    required this.street,
    required this.number,
    required this.district,
    required this.city,
    required this.state,
    required this.cep,
    this.complement,
  });
}


