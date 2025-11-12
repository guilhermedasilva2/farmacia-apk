import 'dart:convert';

import 'package:meu_app_inicial/dto/daily_goal_dto.dart';
import 'package:meu_app_inicial/mappers/daily_goal_mapper.dart';
import 'package:meu_app_inicial/models/daily_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class DailyGoalRepository {
  Future<List<DailyGoal>> listGoals();
  Future<DailyGoal> upsertGoal(DailyGoal goal);
}

class SharedPreferencesDailyGoalRepository implements DailyGoalRepository {
  SharedPreferencesDailyGoalRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;
  static const String _cacheKey = 'daily_goals_cache_v1';
  static const _uuid = Uuid();

  static Future<SharedPreferencesDailyGoalRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesDailyGoalRepository(prefs: prefs);
  }

  @override
  Future<List<DailyGoal>> listGoals() async {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entities = decoded
          .map((e) => DailyGoalMapper.toEntity(DailyGoalDto.fromMap(Map<String, dynamic>.from(e as Map))))
          .toList(growable: false);
      entities.sort((a, b) => a.targetDate.compareTo(b.targetDate));
      return entities;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DailyGoal> upsertGoal(DailyGoal goal) async {
    final current = await listGoals();
    final Map<String, DailyGoal> indexed = {for (final g in current) g.id: g};
    final String id = goal.id.isEmpty ? _uuid.v4() : goal.id;
    final normalized = goal.copyWith(id: id);
    indexed[id] = normalized;
    final payload = indexed.values.map((e) => DailyGoalMapper.toDto(e).toMap()).toList(growable: false);
    await _prefs.setString(_cacheKey, jsonEncode(payload));
    return normalized;
  }
}


