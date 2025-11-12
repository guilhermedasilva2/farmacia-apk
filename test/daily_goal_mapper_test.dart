import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/dto/daily_goal_dto.dart';
import 'package:meu_app_inicial/mappers/daily_goal_mapper.dart';
import 'package:meu_app_inicial/models/daily_goal.dart';

void main() {
  test('DailyGoal mapper converts between entity and dto', () {
    final dto = DailyGoalDto(
      id: 'g1',
      title: 'Beber água',
      description: '8 copos',
      targetDateIso: '2025-01-01T10:00:00.000Z',
    );

    final entity = DailyGoalMapper.toEntity(dto);
    expect(entity.id, 'g1');
    expect(entity.title, 'Beber água');
    expect(entity.description, '8 copos');

    final back = DailyGoalMapper.toDto(entity);
    expect(back.id, 'g1');
    expect(back.title, 'Beber água');
    expect(back.description, '8 copos');
  });
}


