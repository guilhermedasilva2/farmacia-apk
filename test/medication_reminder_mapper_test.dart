import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/dto/medication_reminder_dto.dart';
import 'package:meu_app_inicial/mappers/medication_reminder_mapper.dart';

void main() {
  test('MedicationReminder mapper converts between entity and dto', () {
    final dto = MedicationReminderDto(
      id: 'm1',
      medicationName: 'Amoxicilina',
      dosage: '500mg',
      notes: 'Tomar com água',
      scheduledAtIso: '2025-01-01T08:00:00.000Z',
    );

    final entity = MedicationReminderMapper.toEntity(dto);
    expect(entity.medicationName, 'Amoxicilina');
    expect(entity.dosage, '500mg');

    final back = MedicationReminderMapper.toDto(entity);
    expect(back.medicationName, 'Amoxicilina');
    expect(back.dosage, '500mg');
  });
}


