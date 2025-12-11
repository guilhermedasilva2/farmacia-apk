import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meu_app_inicial/features/orders/infrastructure/dtos/order_dto.dart';

/// DAO local para cache de pedidos usando SharedPreferences
class OrdersLocalDao {
  static const String _key = 'cached_orders_v1';
  
  final SharedPreferences _prefs;

  OrdersLocalDao(this._prefs);

  /// Factory para criar instância
  static Future<OrdersLocalDao> create() async {
    final prefs = await SharedPreferences.getInstance();
    return OrdersLocalDao(prefs);
  }

  /// Lista todos os pedidos do cache
  Future<List<OrderDto>> listAll() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => OrderDto.fromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Se houver erro ao decodificar, limpa o cache
      await clear();
      return [];
    }
  }

  /// Salva/atualiza múltiplos pedidos no cache
  Future<void> upsertAll(List<OrderDto> orders) async {
    final jsonList = orders.map((order) => order.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await _prefs.setString(_key, jsonString);
  }

  /// Limpa todo o cache de pedidos
  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  /// Salva um único pedido (útil para adicionar novo pedido)
  Future<void> upsertOne(OrderDto order) async {
    final existing = await listAll();
    
    // Remove pedido existente com mesmo ID (se houver)
    existing.removeWhere((o) => o.id == order.id);
    
    // Adiciona o novo/atualizado
    existing.add(order);
    
    await upsertAll(existing);
  }

  /// Remove um pedido específico do cache
  Future<void> deleteOne(String orderId) async {
    final existing = await listAll();
    existing.removeWhere((o) => o.id == orderId);
    await upsertAll(existing);
  }
}
