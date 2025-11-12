class DailyGoalDto {
  const DailyGoalDto({
    required this.id,
    required this.title,
    this.description,
    required this.targetDateIso,
  });

  final String id;
  final String title;
  final String? description;
  final String targetDateIso;

  factory DailyGoalDto.fromMap(Map<String, dynamic> map) {
    return DailyGoalDto(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? map['name'] ?? '').toString(),
      description: map['description'] as String?,
      targetDateIso: (map['target_date'] ?? map['date'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_date': targetDateIso,
    };
  }
}


