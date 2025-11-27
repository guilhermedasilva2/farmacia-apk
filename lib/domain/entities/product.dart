class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool available;
  final int quantity;
  final String? categoryId;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.available,
    this.quantity = 0,
    this.categoryId,
  });
}
