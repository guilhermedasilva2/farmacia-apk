enum OrderStatus { pending, paid, shipped, delivered, cancelled }

class OrderItem {
  final String productId;
  final String name;
  final int quantity; // >= 1
  final double unitPrice; // >= 0

  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  }) : assert(quantity >= 1), assert(unitPrice >= 0);

  double get total => quantity * unitPrice;
}

class Order {
  final String id;
  final String customerId;
  final List<OrderItem> items;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.customerId,
    required this.items,
    required this.status,
  });

  double get total => items.fold(0.0, (sum, it) => sum + it.total);
}


