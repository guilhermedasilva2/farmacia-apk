import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/features/categories/infrastructure/dtos/category_dto.dart';
import 'package:meu_app_inicial/features/categories/infrastructure/mappers/category_mapper.dart';

void main() {
  test('Category mapper generates slug if missing', () {
    final dto = CategoryDto(id: 'c1', name: 'Cuidados Pessoais', slug: '');
    final entity = CategoryMapper.toEntity(dto);
    expect(entity.slug, 'cuidados-pessoais');

    final back = CategoryMapper.toDto(entity);
    expect(back.slug, 'cuidados-pessoais');
  });
}


