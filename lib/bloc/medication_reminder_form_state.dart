part of 'medication_reminder_form_bloc.dart';

enum MedicationReminderFormStatus { editing, submitting, success, failure }

class MedicationReminderFormState extends Equatable {
  const MedicationReminderFormState({
    required this.draft,
    required this.status,
    this.errorMessage,
    this.savedReminder,
  });

  final MedicationReminder draft;
  final MedicationReminderFormStatus status;
  final String? errorMessage;
  final MedicationReminder? savedReminder;

  bool get isValid => draft.isValid;
  bool get isSubmitting => status == MedicationReminderFormStatus.submitting;

  MedicationReminderFormState copyWith({
    MedicationReminder? draft,
    MedicationReminderFormStatus? status,
    String? errorMessage,
    MedicationReminder? savedReminder,
  }) {
    return MedicationReminderFormState(
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errorMessage: errorMessage,
      savedReminder: savedReminder,
    );
  }

  @override
  List<Object?> get props => [draft, status, errorMessage, savedReminder];
}


