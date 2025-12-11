import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/features/medication_reminders/infrastructure/dtos/medication_reminder_dto.dart';
import 'package:meu_app_inicial/features/medication_reminders/infrastructure/mappers/medication_reminder_mapper.dart';

void main() {
  test('MedicationReminder mapper converts between entity and dto', () {
    final dto = MedicationReminderDto(
      id: 'm1',
      medicationName: 'Amoxicilina',
      dosage: '500mg',
      notes: 'Tomar com água',
      scheduledAtIso: '2025-01-01T08:00:00.000Z',
      totalDoses: 1,
      takenDoses: 1, // isTaken derived from this
    );

    final entity = MedicationReminderMapper.toEntity(dto);
    expect(entity.medicationName, 'Amoxicilina');
    expect(entity.dosage, '500mg');
    expect(entity.isTaken, true);

    final back = MedicationReminderMapper.toDto(entity);
    expect(back.medicationName, 'Amoxicilina');
    expect(back.dosage, '500mg');
    expect(back.takenDoses, 1);
    expect(back.isTaken, true);
  });
}


