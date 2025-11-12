class MedicationReminderDto {
  const MedicationReminderDto({
    required this.id,
    required this.medicationName,
    this.dosage,
    this.notes,
    required this.scheduledAtIso,
  });

  final String id;
  final String medicationName;
  final String? dosage;
  final String? notes;
  final String scheduledAtIso;

  factory MedicationReminderDto.fromMap(Map<String, dynamic> map) {
    return MedicationReminderDto(
      id: (map['id'] ?? '').toString(),
      medicationName: (map['medication_name'] ?? map['title'] ?? '').toString(),
      dosage: map['dosage'] as String?,
      notes: map['notes'] as String?,
      scheduledAtIso: (map['scheduled_at'] ?? map['target_date'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_name': medicationName,
      'dosage': dosage,
      'notes': notes,
      'scheduled_at': scheduledAtIso,
    };
  }
}


