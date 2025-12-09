part of 'medication_reminder_form_bloc.dart';

abstract class MedicationReminderFormEvent extends Equatable {
  const MedicationReminderFormEvent();

  @override
  List<Object?> get props => [];
}

class MedicationNameChanged extends MedicationReminderFormEvent {
  const MedicationNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

class MedicationDosageChanged extends MedicationReminderFormEvent {
  const MedicationDosageChanged(this.dosage);
  final String dosage;

  @override
  List<Object?> get props => [dosage];
}

class MedicationNotesChanged extends MedicationReminderFormEvent {
  const MedicationNotesChanged(this.notes);
  final String notes;

  @override
  List<Object?> get props => [notes];
}

class MedicationTimeChanged extends MedicationReminderFormEvent {
  const MedicationTimeChanged(this.time);
  final DateTime time;

  @override
  List<Object?> get props => [time];
}

class MedicationTotalDosesChanged extends MedicationReminderFormEvent {
  const MedicationTotalDosesChanged(this.totalDoses);
  final int totalDoses;

  @override
  List<Object?> get props => [totalDoses];
}

class MedicationReminderSubmitted extends MedicationReminderFormEvent {
  const MedicationReminderSubmitted();
}


