import 'package:meu_app_inicial/dto/order_dto.dart';
import 'package:meu_app_inicial/models/order.dart';

class OrderMapper {
  static OrderStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
        return OrderStatus.paid;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static String _statusToString(OrderStatus status) {
    return status.name;
  }

  static Order toEntity(OrderDto dto) {
    final items = dto.items
        .map((i) => OrderItem(
              productId: i.productId,
              name: i.name,
              quantity: i.quantity.toInt().clamp(1, 1 << 31),
              unitPrice: i.unitPrice.toDouble().clamp(0, double.infinity),
            ))
        .toList(growable: false);
    return Order(
      id: dto.id,
      customerId: dto.customerId,
      items: items,
      status: _parseStatus(dto.status),
    );
  }

  static OrderDto toDto(Order entity) {
    final items = entity.items
        .map((i) => OrderItemDto(
              productId: i.productId,
              name: i.name,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
            ))
        .toList(growable: false);
    return OrderDto(
      id: entity.id,
      customerId: entity.customerId,
      status: _statusToString(entity.status),
      items: items,
    );
  }
}


