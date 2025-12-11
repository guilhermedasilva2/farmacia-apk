import 'package:meu_app_inicial/features/medication_reminders/infrastructure/dtos/medication_reminder_dto.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/entities/medication_reminder.dart';

class MedicationReminderMapper {
  static MedicationReminder toEntity(MedicationReminderDto dto) {
    DateTime scheduledAt;
    try {
      scheduledAt = DateTime.parse(dto.scheduledAtIso);
    } catch (_) {
      scheduledAt = DateTime.now();
    }
    
    // Lógica de migração para dados antigos
    int total = dto.totalDoses ?? 1;
    int taken = dto.takenDoses ?? (dto.isTaken == true ? total : 0);
    
    return MedicationReminder(
      id: dto.id,
      medicationName: dto.medicationName.trim(),
      dosage: (dto.dosage ?? '').trim(),
      notes: (dto.notes ?? '').trim(),
      scheduledAt: scheduledAt,
      totalDoses: total,
      takenDoses: taken,
    );
  }

  static MedicationReminderDto toDto(MedicationReminder entity) {
    return MedicationReminderDto(
      id: entity.id,
      medicationName: entity.medicationName,
      dosage: entity.dosage.isEmpty ? null : entity.dosage,
      notes: entity.notes.isEmpty ? null : entity.notes,
      scheduledAtIso: entity.scheduledAt.toIso8601String(),
      totalDoses: entity.totalDoses,
      takenDoses: entity.takenDoses,
      updatedAt: null, // Entidade não rastreia isso ainda
    );
  }
}


