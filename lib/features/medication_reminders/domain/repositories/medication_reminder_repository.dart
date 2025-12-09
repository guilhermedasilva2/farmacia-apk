import 'package:meu_app_inicial/features/medication_reminders/domain/entities/medication_reminder.dart';

abstract class MedicationReminderRepository {
  Future<List<MedicationReminder>> listReminders();
  Future<MedicationReminder> upsertReminder(MedicationReminder reminder);
  Future<void> deleteReminder(String id);
}
