import 'package:meu_app_inicial/features/orders/domain/entities/order.dart';

/// Interface de repositório para gerenciamento de pedidos.
///
/// Define as operações para criar, consultar e gerenciar pedidos
/// sem depender de implementações específicas.
abstract class OrderRepository {
  /// Busca todos os pedidos de um usuário.
  Future<List<Order>> getUserOrders(String userId);
  
  /// Busca todos os pedidos (admin).
  Future<List<Order>> getAllOrders();

  /// Cria um novo pedido.
  /// Retorna o ID do pedido criado.
  Future<String> createOrder(Order order);
  
  /// Atualiza o status de um pedido.
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  
  /// Deleta um pedido.
  Future<void> deleteOrder(String orderId);
  
  /// Busca um pedido específico por ID.
  Future<Order?> getOrderById(String orderId);

  /// Retorna o nome de exibição do status.
  String getStatusDisplayName(OrderStatus status);
}
