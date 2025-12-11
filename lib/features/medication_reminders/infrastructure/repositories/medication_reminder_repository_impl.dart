import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/repositories/medication_reminder_repository.dart';
import 'package:meu_app_inicial/features/medication_reminders/infrastructure/dtos/medication_reminder_dto.dart';
import 'package:meu_app_inicial/features/medication_reminders/infrastructure/mappers/medication_reminder_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// ==========================================
// REMOTE DATA SOURCE (Supabase)
// ==========================================
class MedicationReminderRemoteDataSource {
  final SupabaseClient _client;
  static const String tableName = 'medication_reminders';

  MedicationReminderRemoteDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<MedicationReminderDto>> fetchAll() async {
    final response = await _client.from(tableName).select();
    final list = response as List;
    return list
        .map((e) => MedicationReminderDto.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsert(MedicationReminderDto dto) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final map = dto.toMap();
    map['user_id'] = user.id; // Inject user_id
    map.remove('updated_at'); // Let DB handle this via trigger

    await _client.from(tableName).upsert(map);
  }

  Future<void> delete(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }
}

// ==========================================
// LOCAL DATA SOURCE (SharedPreferences)
// ==========================================
class MedicationReminderLocalDataSource {
  final SharedPreferences _prefs;
  static const String _storageKey = 'medication_reminders_v2';
  static const String _deletedQueueKey = 'medication_reminders_deleted_queue';

  MedicationReminderLocalDataSource(this._prefs);

  Future<List<MedicationReminderDto>> readAll() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded
          .map((e) => MedicationReminderDto.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error reading local reminders: $e');
      return [];
    }
  }

  Future<void> saveAll(List<MedicationReminderDto> dtos) async {
    final raw = jsonEncode(dtos.map((e) => e.toMap()).toList());
    await _prefs.setString(_storageKey, raw);
  }

  Future<void> queueDeletion(String id) async {
    final list = _prefs.getStringList(_deletedQueueKey) ?? [];
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList(_deletedQueueKey, list);
    }
  }

  Future<List<String>> getDeletionQueue() async {
    return _prefs.getStringList(_deletedQueueKey) ?? [];
  }

  Future<void> clearDeletionQueue() async {
    await _prefs.remove(_deletedQueueKey);
  }
}

// ==========================================
// REPOSITORY IMPLEMENTATION
// ==========================================
class CachedMedicationReminderRepository implements MedicationReminderRepository {
  final MedicationReminderRemoteDataSource _remote;
  final MedicationReminderLocalDataSource _local;
  final Uuid _uuid = const Uuid();

  CachedMedicationReminderRepository({
    MedicationReminderRemoteDataSource? remote,
    required MedicationReminderLocalDataSource local,
  })  : _remote = remote ?? MedicationReminderRemoteDataSource(),
        _local = local;

  static Future<CachedMedicationReminderRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CachedMedicationReminderRepository(
      local: MedicationReminderLocalDataSource(prefs),
    );
  }

  @override
  Future<List<MedicationReminder>> listReminders() async {
    // 1. Load from local cache (Offline-first)
    final localDtos = await _local.readAll();
    final entities = localDtos.map(MedicationReminderMapper.toEntity).toList();
    
    // Sort
    entities.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    
    // Trigger background sync (fire and forget)
    _syncInBackground();

    return entities;
  }

  Future<void> _syncInBackground() async {
    try {
      await syncFromServer();
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  Future<void> syncFromServer() async {
    // 1. Process Deletions
    final deletions = await _local.getDeletionQueue();
    for (final id in deletions) {
      try {
        await _remote.delete(id);
      } catch (e) {
        debugPrint('Failed to sync deletion for $id: $e');
      }
    }
    await _local.clearDeletionQueue();

    // 2. Push Local Changes (Upsert all for simplicity, or could track dirty)
    // For now, we push ALL local items to ensure server is strictly consistent
    final localDtos = await _local.readAll();
    for (final dto in localDtos) {
      try {
        await _remote.upsert(dto);
      } catch (e) {
        debugPrint('Failed to sync upsert for ${dto.id}: $e');
      }
    }

    // 3. Pull Remote Changes
    try {
      final remoteDtos = await _remote.fetchAll();
      // Update Local
      await _local.saveAll(remoteDtos);
    } catch (e) {
      debugPrint('Failed to pull remote reminders: $e');
    }
  }

  @override
  Future<MedicationReminder> upsertReminder(MedicationReminder reminder) async {
    // 1. Generate ID if needed
    final id = reminder.id.isEmpty ? _uuid.v4() : reminder.id;
    final normalized = reminder.copyWith(id: id);

    // 2. Save Local
    final currentDtos = await _local.readAll();
    final index = currentDtos.indexWhere((d) => d.id == id);
    final dto = MedicationReminderMapper.toDto(normalized);

    final List<MedicationReminderDto> newDtos = List.from(currentDtos);
    if (index >= 0) {
      newDtos[index] = dto;
    } else {
      newDtos.add(dto);
    }
    await _local.saveAll(newDtos);

    // 3. Try Remote (Best effort)
    try {
      await _remote.upsert(dto);
    } catch (e) {
      debugPrint('Offline: Saved locally, will sync later. Error: $e');
    }

    return normalized;
  }

  @override
  Future<void> deleteReminder(String id) async {
    // 1. Remove Local
    final currentDtos = await _local.readAll();
    final newDtos = currentDtos.where((d) => d.id != id).toList();
    await _local.saveAll(newDtos);

    // 2. Queue Deletion
    await _local.queueDeletion(id);

    // 3. Try Remote
    try {
      await _remote.delete(id);
      // If successful, remove from queue?
      // For simplicity, we just clear queue on next sync
    } catch (e) {
      debugPrint('Offline: Delete queued. Error: $e');
    }
  }
}
