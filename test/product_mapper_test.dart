import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/data/mappers/product_mapper.dart';

void main() {
  test('ProductMapper handles nullables and numeric price', () {
    final dto = ProductDto(
      id: '1',
      name: 'Teste',
      description: null,
      imageUrl: null,
      price: 9,
      available: null,
    );
    final model = ProductMapper.fromDto(dto);
    expect(model.description, '');
    expect(model.imageUrl, '');
    expect(model.price, 9.0);
    expect(model.available, true);
  });
}


