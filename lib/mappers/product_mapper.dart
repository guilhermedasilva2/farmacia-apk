import 'package:meu_app_inicial/dto/product_dto.dart';
import 'package:meu_app_inicial/models/product.dart';

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
    );
  }

  static List<Product> fromDtoList(List<ProductDto> list) {
    return list.map(fromDto).toList(growable: false);
  }
}


