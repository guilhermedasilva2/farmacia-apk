import 'package:meu_app_inicial/features/products/infrastructure/dtos/product_dto.dart';
import 'package:meu_app_inicial/features/products/domain/entities/product.dart';

class ProductMapper {
  static Product fromDto(ProductDto dto) {
    final double parsedPrice;
    final num? priceNum = dto.price;
    if (priceNum == null) {
      parsedPrice = 0.0;
    } else {
      parsedPrice = priceNum.toDouble();
    }

    return Product(
      id: dto.id,
      name: dto.name,
      description: dto.description ?? '',
      imageUrl: dto.imageUrl ?? '',
      price: parsedPrice,
      available: dto.available ?? true,
      quantity: dto.quantity ?? 0,
      categoryId: dto.categoryId,
    );
  }

  static List<Product> fromDtoList(List<ProductDto> list) {
    return list.map(fromDto).toList(growable: false);
  }

  static ProductDto toDto(Product entity) {
    return ProductDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      price: entity.price,
      available: entity.available,
      quantity: entity.quantity,
      categoryId: entity.categoryId,
    );
  }
}


