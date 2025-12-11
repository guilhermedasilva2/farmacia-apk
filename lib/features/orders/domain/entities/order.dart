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
  
  // Campos de endereço de entrega
  final String? deliveryAddress;
  final String? deliveryNumber;
  final String? deliveryComplement;
  final String? deliveryNeighborhood;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryCep;

  const Order({
    required this.id,
    required this.customerId,
    required this.items,
    required this.status,
    this.deliveryAddress,
    this.deliveryNumber,
    this.deliveryComplement,
    this.deliveryNeighborhood,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryCep,
  });

  double get total => items.fold(0.0, (sum, it) => sum + it.total);
  
  /// Retorna endereço completo formatado
  String get fullAddress {
    if (deliveryAddress == null) return 'Endereço não informado';
    
    final parts = <String>[];
    parts.add(deliveryAddress!);
    if (deliveryNumber != null && deliveryNumber!.isNotEmpty) {
      parts.add(deliveryNumber!);
    }
    if (deliveryComplement != null && deliveryComplement!.isNotEmpty) {
      parts.add(deliveryComplement!);
    }
    if (deliveryNeighborhood != null && deliveryNeighborhood!.isNotEmpty) {
      parts.add(deliveryNeighborhood!);
    }
    if (deliveryCity != null && deliveryState != null) {
      parts.add('${deliveryCity!} - ${deliveryState!}');
    }
    if (deliveryCep != null && deliveryCep!.isNotEmpty) {
      parts.add('CEP: ${deliveryCep!}');
    }
    
    return parts.join(', ');
  }
}
