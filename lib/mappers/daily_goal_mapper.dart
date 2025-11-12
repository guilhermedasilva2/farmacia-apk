import 'package:meu_app_inicial/dto/daily_goal_dto.dart';
import 'package:meu_app_inicial/models/daily_goal.dart';

class DailyGoalMapper {
  static DailyGoal toEntity(DailyGoalDto dto) {
    DateTime targetDate;
    try {
      targetDate = DateTime.parse(dto.targetDateIso);
    } catch (_) {
      targetDate = DateTime.now();
    }
    return DailyGoal(
      id: dto.id,
      title: dto.title.trim(),
      description: (dto.description ?? '').trim(),
      targetDate: targetDate,
    );
  }

  static DailyGoalDto toDto(DailyGoal entity) {
    return DailyGoalDto(
      id: entity.id,
      title: entity.title,
      description: entity.description.isEmpty ? null : entity.description,
      targetDateIso: entity.targetDate.toIso8601String(),
    );
  }
}


