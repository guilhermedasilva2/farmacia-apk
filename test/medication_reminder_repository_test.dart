import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/domain/entities/medication_reminder.dart';
import 'package:meu_app_inicial/data/repositories/medication_reminder_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SharedPreferencesMedicationReminderRepository persists reminders', () async {
    final repository = await SharedPreferencesMedicationReminderRepository.create();
    final reminder = await repository.upsertReminder(
      MedicationReminder(
        id: '',
        medicationName: 'Ibuprofeno',
        dosage: '1 comprimido',
        notes: 'Após refeições',
        scheduledAt: DateTime(2025, 1, 1, 8, 0),
        takenDoses: 0,
        totalDoses: 1,
      ),
    );

    expect(reminder.id.isNotEmpty, true);

    await repository.upsertReminder(
      reminder.copyWith(notes: 'Após café da manhã', takenDoses: 1, totalDoses: 1),
    );

    final all = await repository.listReminders();
    expect(all.length, 1);
    expect(all.first.notes, 'Após café da manhã');
    expect(all.first.isTaken, true);
  });

  test('SharedPreferencesMedicationReminderRepository deletes reminders', () async {
    final repository = await SharedPreferencesMedicationReminderRepository.create();
    final reminder = await repository.upsertReminder(
      MedicationReminder(
        id: '',
        medicationName: 'Antibiótico',
        dosage: '',
        notes: '',
        scheduledAt: DateTime(2025, 1, 1, 9, 0),
      ),
    );

    await repository.deleteReminder(reminder.id);
    final all = await repository.listReminders();
    expect(all, isEmpty);
  });
}


