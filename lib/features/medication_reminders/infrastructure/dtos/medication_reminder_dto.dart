class MedicationReminderDto {
  const MedicationReminderDto({
    required this.id,
    required this.medicationName,
    this.dosage,
    this.notes,
    required this.scheduledAtIso,
    this.totalDoses,
    this.takenDoses,
    this.updatedAt,
  });

  final String id;
  final String medicationName;
  final String? dosage;
  final String? notes;
  final String scheduledAtIso;
  final int? totalDoses;
  final int? takenDoses;
  final DateTime? updatedAt;

  // Propriedade derivada, útil para mapeamento reverso se necessário
  bool get isTaken => (takenDoses ?? 0) >= (totalDoses ?? 1);

  factory MedicationReminderDto.fromMap(Map<String, dynamic> map) {
    return MedicationReminderDto(
      id: (map['id'] ?? '').toString(),
      medicationName: (map['medication_name'] ?? map['title'] ?? '').toString(),
      dosage: map['dosage'] as String?,
      notes: map['notes'] as String?,
      scheduledAtIso: (map['scheduled_at'] ?? map['target_date'] ?? '').toString(),
      totalDoses: map['total_doses'] as int?,
      takenDoses: map['taken_doses'] as int?,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'medication_name': medicationName,
      'dosage': dosage,
      'notes': notes,
      'scheduled_at': scheduledAtIso,
      'total_doses': totalDoses,
      'taken_doses': takenDoses,
    };
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }
    return map;
  }
}


