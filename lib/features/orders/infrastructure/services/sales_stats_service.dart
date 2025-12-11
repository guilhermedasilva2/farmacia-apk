import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo para estatísticas de vendas
class SalesStats {
  final double totalSales;
  final int orderCount;
  final double averageTicket;
  final double dailyGoal;

  SalesStats({
    required this.totalSales,
    required this.orderCount,
    required this.averageTicket,
    required this.dailyGoal,
  });

  double get goalProgress => dailyGoal > 0 ? (totalSales / dailyGoal).clamp(0.0, 1.0) : 0.0;
  int get goalPercentage => (goalProgress * 100).round();
}

/// Serviço para calcular estatísticas de vendas
class SalesStatsService {
  SalesStatsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const double _dailyGoalAmount = 1800.0; // Meta diária em R$

  /// Obtém estatísticas de vendas do dia atual
  Future<SalesStats> getTodayStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Buscar pedidos do dia
      final response = await _client
          .from('orders')
          .select('total, status')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .neq('status', 'cancelled'); // Excluir cancelados

      final orders = response as List;
      
      if (orders.isEmpty) {
        return SalesStats(
          totalSales: 0.0,
          orderCount: 0,
          averageTicket: 0.0,
          dailyGoal: _dailyGoalAmount,
        );
      }

      final totalSales = orders.fold<double>(
        0.0,
        (sum, order) => sum + (order['total'] as num).toDouble(),
      );

      final orderCount = orders.length;
      final averageTicket = orderCount > 0 ? totalSales / orderCount : 0.0;

      return SalesStats(
        totalSales: totalSales,
        orderCount: orderCount,
        averageTicket: averageTicket,
        dailyGoal: _dailyGoalAmount,
      );
    } catch (e) {
      // Em caso de erro, retornar estatísticas vazias
      return SalesStats(
        totalSales: 0.0,
        orderCount: 0,
        averageTicket: 0.0,
        dailyGoal: _dailyGoalAmount,
      );
    }
  }

  /// Obtém estatísticas do mês atual
  Future<SalesStats> getMonthStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      final response = await _client
          .from('orders')
          .select('total, status')
          .gte('created_at', startOfMonth.toIso8601String())
          .lt('created_at', endOfMonth.toIso8601String())
          .neq('status', 'cancelled');

      final orders = response as List;
      
      if (orders.isEmpty) {
        return SalesStats(
          totalSales: 0.0,
          orderCount: 0,
          averageTicket: 0.0,
          dailyGoal: _dailyGoalAmount * 30, // Meta mensal
        );
      }

      final totalSales = orders.fold<double>(
        0.0,
        (sum, order) => sum + (order['total'] as num).toDouble(),
      );

      final orderCount = orders.length;
      final averageTicket = orderCount > 0 ? totalSales / orderCount : 0.0;

      return SalesStats(
        totalSales: totalSales,
        orderCount: orderCount,
        averageTicket: averageTicket,
        dailyGoal: _dailyGoalAmount * 30,
      );
    } catch (e) {
      return SalesStats(
        totalSales: 0.0,
        orderCount: 0,
        averageTicket: 0.0,
        dailyGoal: _dailyGoalAmount * 30,
      );
    }
  }
}
