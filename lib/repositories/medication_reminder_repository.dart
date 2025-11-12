import 'dart:convert';

import 'package:meu_app_inicial/dto/medication_reminder_dto.dart';
import 'package:meu_app_inicial/mappers/medication_reminder_mapper.dart';
import 'package:meu_app_inicial/models/medication_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class MedicationReminderRepository {
  Future<List<MedicationReminder>> listReminders();
  Future<MedicationReminder> upsertReminder(MedicationReminder reminder);
}

class SharedPreferencesMedicationReminderRepository implements MedicationReminderRepository {
  SharedPreferencesMedicationReminderRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;
  static const String _cacheKey = 'medication_reminders_cache_v1';
  static const _uuid = Uuid();

  static Future<SharedPreferencesMedicationReminderRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesMedicationReminderRepository(prefs: prefs);
  }

  @override
  Future<List<MedicationReminder>> listReminders() async {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entities = decoded
          .map((e) => MedicationReminderMapper.toEntity(
                MedicationReminderDto.fromMap(Map<String, dynamic>.from(e as Map)),
              ))
          .toList(growable: false);
      entities.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return entities;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MedicationReminder> upsertReminder(MedicationReminder reminder) async {
    final current = await listReminders();
    final Map<String, MedicationReminder> indexed = {for (final r in current) r.id: r};
    final String id = reminder.id.isEmpty ? _uuid.v4() : reminder.id;
    final normalized = reminder.copyWith(id: id);
    indexed[id] = normalized;
    final payload =
        indexed.values.map((e) => MedicationReminderMapper.toDto(e).toMap()).toList(growable: false);
    await _prefs.setString(_cacheKey, jsonEncode(payload));
    return normalized;
  }
}


