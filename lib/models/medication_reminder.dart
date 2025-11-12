import 'package:equatable/equatable.dart';

class MedicationReminder extends Equatable {
  const MedicationReminder({
    required this.id,
    required this.medicationName,
    this.dosage = '',
    this.notes = '',
    required this.scheduledAt,
  });

  final String id;
  final String medicationName;
  final String dosage;
  final String notes;
  final DateTime scheduledAt;

  bool get isPersisted => id.isNotEmpty;

  bool get isValid => medicationName.trim().isNotEmpty;

  MedicationReminder copyWith({
    String? id,
    String? medicationName,
    String? dosage,
    String? notes,
    DateTime? scheduledAt,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }

  @override
  List<Object?> get props => [id, medicationName, dosage, notes, scheduledAt];
}


