import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/features/medication_reminders/presentation/widgets/medication_reminder_form_bloc.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/repositories/medication_reminder_repository.dart';

class FakeMedicationRepository implements MedicationReminderRepository {
  MedicationReminder? saved;

  @override
  Future<List<MedicationReminder>> listReminders() async => [if (saved != null) saved!];

  @override
  Future<MedicationReminder> upsertReminder(MedicationReminder reminder) async {
    saved = reminder.id.isEmpty ? reminder.copyWith(id: 'generated') : reminder;
    return saved!;
  }

  @override
  Future<void> deleteReminder(String id) async {
    if (saved?.id == id) saved = null;
  }
}

void main() {
  group('MedicationReminderFormBloc', () {
    late FakeMedicationRepository repository;

    setUp(() {
      repository = FakeMedicationRepository();
    });

    blocTest<MedicationReminderFormBloc, MedicationReminderFormState>(
      'emits success when submitting valid reminder',
      build: () => MedicationReminderFormBloc(repository: repository),
      act: (bloc) {
        bloc
          ..add(const MedicationNameChanged('Dipirona'))
          ..add(const MedicationDosageChanged('20 gotas'))
          ..add(const MedicationReminderSubmitted());
      },
      expect: () => [
        isA<MedicationReminderFormState>().having((s) => s.draft.medicationName, 'name', 'Dipirona'),
        isA<MedicationReminderFormState>().having((s) => s.draft.dosage, 'dosage', '20 gotas'),
        isA<MedicationReminderFormState>()
            .having((s) => s.status, 'status', MedicationReminderFormStatus.submitting),
        isA<MedicationReminderFormState>()
            .having((s) => s.status, 'status', MedicationReminderFormStatus.success)
            .having((s) => s.savedReminder?.medicationName, 'saved', 'Dipirona')
            .having((s) => s.savedReminder?.isTaken, 'isTaken', false),
      ],
    );
  });
}


