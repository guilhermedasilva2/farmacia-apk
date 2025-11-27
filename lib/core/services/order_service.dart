import 'package:meu_app_inicial/domain/entities/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para gerenciar pedidos de usuários
class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Cria um novo pedido
  Future<String> createOrder({
    required String userId,
    required List<OrderItem> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('O pedido deve conter pelo menos um item');
    }

    final total = items.fold(0.0, (sum, item) => sum + item.total);

    // Criar o pedido
    final orderResponse = await _client.from('orders').insert({
      'user_id': userId,
      'total': total,
      'status': 'pending',
    }).select().single();

    final orderId = orderResponse['id'] as String;

    // Criar os itens do pedido
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'product_id': item.productId,
      'quantity': item.quantity,
      'price': item.unitPrice,
    }).toList();

    await _client.from('order_items').insert(orderItems);

    return orderId;
  }

  /// Busca todos os pedidos de um usuário
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((orderData) {
        final items = (orderData['order_items'] as List).map((itemData) {
          return OrderItem(
            productId: itemData['product_id'] as String,
            name: '', // Nome será buscado do produto se necessário
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
    } catch (e) {
      return [];
    }
  }

  /// Busca um pedido específico por ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      final items = (response['order_items'] as List).map((itemData) {
        return OrderItem(
          productId: itemData['product_id'] as String,
          name: '',
          quantity: itemData['quantity'] as int,
          unitPrice: (itemData['price'] as num).toDouble(),
        );
      }).toList();

      return Order(
        id: response['id'] as String,
        customerId: response['user_id'] as String,
        items: items,
        status: _parseOrderStatus(response['status'] as String),
      );
    } catch (e) {
      return null;
    }
  }

  /// Busca todos os pedidos (apenas para admin)
  Future<List<Order>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

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
    } catch (e) {
      return [];
    }
  }

  /// Atualiza o status de um pedido
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _client.from('orders').update({
      'status': _orderStatusToString(status),
    }).eq('id', orderId);
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
}
