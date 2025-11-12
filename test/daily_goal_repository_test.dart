import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/models/daily_goal.dart';
import 'package:meu_app_inicial/repositories/daily_goal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SharedPreferencesDailyGoalRepository upserts and lists goals', () async {
    final repository = await SharedPreferencesDailyGoalRepository.create();
    final saved = await repository.upsertGoal(
      DailyGoal(id: '', title: 'Meta 1', description: 'descrição', targetDate: DateTime(2025, 1, 1)),
    );

    expect(saved.id.isNotEmpty, true);

    final again = await repository.upsertGoal(
      saved.copyWith(description: 'atualizada'),
    );
    expect(again.description, 'atualizada');

    final all = await repository.listGoals();
    expect(all.length, 1);
    expect(all.first.description, 'atualizada');
  });
}


