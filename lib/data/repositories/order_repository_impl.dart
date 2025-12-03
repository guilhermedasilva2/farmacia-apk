import 'package:meu_app_inicial/domain/entities/order.dart';
import 'package:meu_app_inicial/domain/repositories/order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositório para gerenciar pedidos
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<String> createOrder(Order order) async {
    // ... (existing implementation)
    final total = order.total;

    // Criar o pedido
    final orderResponse = await _client.from('orders').insert({
      'user_id': order.customerId,
      'total': total,
      'status': _orderStatusToString(order.status),
    }).select().single();

    final orderId = orderResponse['id'] as String;

    // Criar os itens do pedido
    final orderItems = order.items.map((item) => {
      'order_id': orderId,
      'product_id': item.productId,
      'quantity': item.quantity,
      'price': item.unitPrice,
    }).toList();

    await _client.from('order_items').insert(orderItems);

    return orderId;
  }

  @override
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return _parseOrders(response);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      return _parseOrders(response);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _client.from('orders').update({
      'status': _orderStatusToString(status),
    }).eq('id', orderId);
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    // Primeiro deletar os itens
    await _client.from('order_items').delete().eq('order_id', orderId);
    // Depois deletar o pedido
    await _client.from('orders').delete().eq('id', orderId);
  }
  
  @override
  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();
          
      final orders = _parseOrders([response]);
      return orders.isNotEmpty ? orders.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Parse de lista de pedidos
  List<Order> _parseOrders(dynamic response) {
    return (response as List).map((orderData) {
      final items = (orderData['order_items'] as List).map((itemData) {
        return OrderItem(
          productId: itemData['product_id'] as String,
          name: '',
          quantity: itemData['quantity'] as int,
          unitPrice: (itemData['price'] as num).toDouble(),
        );
      }).toList();

      return Order(
        id: orderData['id'] as String,
        customerId: orderData['user_id'] as String,
        items: items,
        status: _parseOrderStatus(orderData['status'] as String),
      );
    }).toList();
  }

  /// Converte string para OrderStatus
  OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
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

  /// Converte OrderStatus para string
  String _orderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.paid:
        return 'paid';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Helper para obter nome amigável do status
  @override
  String getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.paid:
        return 'Pago';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}
