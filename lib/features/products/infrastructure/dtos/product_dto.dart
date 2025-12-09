class ProductDto {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final num? price;
  final bool? available;
  final int? quantity;
  final String? categoryId;
  final DateTime? updatedAt;

  const ProductDto({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.price,
    this.available,
    this.quantity,
    this.categoryId,
    this.updatedAt,
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
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'available': available,
      'quantity': quantity,
      'category_id': categoryId,
    };
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }
    return map;
  }

  factory ProductDto.fromJson(Map<String, dynamic> json) => ProductDto.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}


