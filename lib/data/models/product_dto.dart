class ProductDto {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final num? price;
  final bool? available;
  final int? quantity;
  final String? categoryId;

  const ProductDto({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.price,
    this.available,
    this.quantity,
    this.categoryId,
  });

  factory ProductDto.fromMap(Map<String, dynamic> map) {
    return ProductDto(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? map['nome'] ?? '').toString(),
      description: (map['description'] ?? map['descricao']) as String?,
      imageUrl: (map['image_url'] ?? map['imagem_url']) as String?,
      price: map['price'] ?? map['preco'],
      available: map['available'] ?? map['disponivel'],
      quantity: map['quantity'] ?? map['quantidade'],
      categoryId: (map['category_id'] ?? map['categoria_id']) as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'available': available,
      'quantity': quantity,
      'category_id': categoryId,
    };
  }
}


