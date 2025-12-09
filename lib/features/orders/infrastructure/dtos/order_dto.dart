class OrderItemDto {
  final String productId;
  final String name;
  final num quantity;
  final num unitPrice;

  const OrderItemDto({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemDto.fromMap(Map<String, dynamic> map) => OrderItemDto(
        productId: (map['product_id'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        quantity: map['quantity'] ?? 0,
        unitPrice: map['unit_price'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class OrderDto {
  final String id;
  final String customerId;
  final String status; // ex: 'pending'
  final List<OrderItemDto> items;

  const OrderDto({
    required this.id,
    required this.customerId,
    required this.status,
    required this.items,
  });

  factory OrderDto.fromMap(Map<String, dynamic> map) => OrderDto(
        id: (map['id'] ?? '').toString(),
        customerId: (map['customer_id'] ?? '').toString(),
        status: (map['status'] ?? 'pending').toString(),
        items: (map['items'] as List<dynamic>? ?? const [])
            .map((e) => OrderItemDto.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'status': status,
        'items': items.map((e) => e.toMap()).toList(),
      };
}


