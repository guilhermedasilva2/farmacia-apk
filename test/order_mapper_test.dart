import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/data/models/order_dto.dart';
import 'package:meu_app_inicial/data/mappers/order_mapper.dart';
import 'package:meu_app_inicial/domain/entities/order.dart';

void main() {
  test('Order mapper toEntity/toDto roundtrip with clamping', () {
    final dto = OrderDto(
      id: 'o1',
      customerId: 'u1',
      status: 'paid',
      items: [
        OrderItemDto(productId: 'p1', name: 'Paracetamol', quantity: 0, unitPrice: -5),
        OrderItemDto(productId: 'p2', name: 'Vitamina C', quantity: 2, unitPrice: 10.5),
      ],
    );

    final entity = OrderMapper.toEntity(dto);
    expect(entity.status, OrderStatus.paid);
    expect(entity.items.first.quantity, 1);
    expect(entity.items.first.unitPrice, 0);
    expect(entity.total, greaterThan(0));

    final back = OrderMapper.toDto(entity);
    expect(back.status, 'paid');
    expect(back.items.length, 2);
  });
}


