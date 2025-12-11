import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:meu_app_inicial/features/medication_reminders/infrastructure/mappers/medication_reminder_mapper.dart';
import 'package:meu_app_inicial/features/medication_reminders/infrastructure/repositories/medication_reminder_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('MedicationReminderLocalDataSource persists reminders', () async {
    final prefs = await SharedPreferences.getInstance();
    final dataSource = MedicationReminderLocalDataSource(prefs);
    
    final reminder = MedicationReminder(
      id: '123',
      medicationName: 'Ibuprofeno',
      dosage: '1 comprimido',
      notes: 'Após refeições',
      scheduledAt: DateTime(2025, 1, 1, 8, 0),
      takenDoses: 0,
      totalDoses: 1,
    );
    final dto = MedicationReminderMapper.toDto(reminder);

    await dataSource.saveAll([dto]);

    final all = await dataSource.readAll();
    expect(all.length, 1);
    expect(all.first.notes, 'Após refeições');
    expect(all.first.id, '123');
  });

  test('MedicationReminderLocalDataSource deletes reminders (saves empty list)', () async {
    final prefs = await SharedPreferences.getInstance();
    final dataSource = MedicationReminderLocalDataSource(prefs);
    
    final reminder = MedicationReminder(
      id: '123',
      medicationName: 'Antibiótico',
      dosage: '',
      notes: '',
      scheduledAt: DateTime(2025, 1, 1, 9, 0),
      totalDoses: 1,
      takenDoses: 0
    );
    
    // Save 1
    await dataSource.saveAll([MedicationReminderMapper.toDto(reminder)]);
    var all = await dataSource.readAll();
    expect(all, isNotEmpty);

    // Save empty (Simulate delete)
    await dataSource.saveAll([]);
    all = await dataSource.readAll();
    expect(all, isEmpty);
  });
}


