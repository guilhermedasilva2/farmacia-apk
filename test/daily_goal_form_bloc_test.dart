import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/bloc/daily_goal_form_bloc.dart';
import 'package:meu_app_inicial/models/daily_goal.dart';
import 'package:meu_app_inicial/repositories/daily_goal_repository.dart';

class FakeRepository implements DailyGoalRepository {
  DailyGoal? saved;

  @override
  Future<List<DailyGoal>> listGoals() async => [if (saved != null) saved!];

  @override
  Future<DailyGoal> upsertGoal(DailyGoal goal) async {
    saved = goal.id.isEmpty ? goal.copyWith(id: 'generated') : goal;
    return saved!;
  }
}

void main() {
  group('DailyGoalFormBloc', () {
    late FakeRepository repository;

    setUp(() {
      repository = FakeRepository();
    });

    blocTest<DailyGoalFormBloc, DailyGoalFormState>(
      'emits success when submitting valid goal',
      build: () => DailyGoalFormBloc(repository: repository),
      act: (bloc) {
        bloc
          ..add(const DailyGoalTitleChanged('Meta de estudo'))
          ..add(const DailyGoalDescriptionChanged('Estudar 2 horas'))
          ..add(const DailyGoalSubmitted());
      },
      expect: () => [
        isA<DailyGoalFormState>().having((s) => s.draft.title, 'title', 'Meta de estudo'),
        isA<DailyGoalFormState>().having((s) => s.draft.description, 'description', 'Estudar 2 horas'),
        isA<DailyGoalFormState>().having((s) => s.status, 'status', DailyGoalFormStatus.submitting),
        isA<DailyGoalFormState>()
            .having((s) => s.status, 'status', DailyGoalFormStatus.success)
            .having((s) => s.savedGoal?.title, 'saved', 'Meta de estudo'),
      ],
    );
  });
}


