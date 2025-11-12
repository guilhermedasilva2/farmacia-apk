import 'package:equatable/equatable.dart';

class DailyGoal extends Equatable {
  const DailyGoal({
    required this.id,
    required this.title,
    this.description = '',
    required this.targetDate,
  });

  final String id;
  final String title;
  final String description;
  final DateTime targetDate;

  bool get isPersisted => id.isNotEmpty;

  bool get isValid => title.trim().isNotEmpty;

  DailyGoal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
  }) {
    return DailyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  @override
  List<Object?> get props => [id, title, description, targetDate];
}


