import 'package:meu_app_inicial/dto/category_dto.dart';
import 'package:meu_app_inicial/models/category.dart';

class CategoryMapper {
  static String _slugify(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-+'), '-');
  }

  static Category toEntity(CategoryDto dto) {
    final slug = (dto.slug == null || dto.slug!.isEmpty) ? _slugify(dto.name) : dto.slug!;
    return Category(id: dto.id, name: dto.name.trim(), slug: slug);
  }

  static CategoryDto toDto(Category entity) {
    return CategoryDto(id: entity.id, name: entity.name, slug: entity.slug);
  }
}


