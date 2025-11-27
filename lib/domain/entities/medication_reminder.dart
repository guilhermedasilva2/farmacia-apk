import 'package:equatable/equatable.dart';

class MedicationReminder extends Equatable {
  const MedicationReminder({
    required this.id,
    required this.medicationName,
    this.dosage = '',
    this.notes = '',
    required this.scheduledAt,
    this.totalDoses = 1,
    this.takenDoses = 0,
  });

  final String id;
  final String medicationName;
  final String dosage;
  final String notes;
  final DateTime scheduledAt;
  final int totalDoses;
  final int takenDoses;

  bool get isTaken => takenDoses >= totalDoses;

  bool get isPersisted => id.isNotEmpty;

  bool get isValid => medicationName.trim().isNotEmpty;

  MedicationReminder copyWith({
    String? id,
    String? medicationName,
    String? dosage,
    String? notes,
    DateTime? scheduledAt,
    int? totalDoses,
    int? takenDoses,
    // Mantendo compatibilidade temporária se alguém passar isTaken (ignorado ou convertido)
    bool? isTaken, 
  }) {
    // Se isTaken for passado como true, assumimos que todas as doses foram tomadas
    final newTaken = isTaken == true ? (totalDoses ?? this.totalDoses) : (takenDoses ?? this.takenDoses);
    
    return MedicationReminder(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      totalDoses: totalDoses ?? this.totalDoses,
      takenDoses: takenDoses ?? newTaken,
    );
  }

  @override
  List<Object?> get props => [id, medicationName, dosage, notes, scheduledAt, totalDoses, takenDoses];
}


