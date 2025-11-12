import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app_inicial/models/daily_goal.dart';
import 'package:meu_app_inicial/repositories/daily_goal_repository.dart';

part 'daily_goal_form_event.dart';
part 'daily_goal_form_state.dart';

class DailyGoalFormBloc extends Bloc<DailyGoalFormEvent, DailyGoalFormState> {
  DailyGoalFormBloc({
    required DailyGoalRepository repository,
    DailyGoal? initialGoal,
  })  : _repository = repository,
        super(
          DailyGoalFormState(
            draft: initialGoal ??
                DailyGoal(
                  id: '',
                  title: '',
                  description: '',
                  targetDate: DateTime.now(),
                ),
            status: DailyGoalFormStatus.editing,
          ),
        ) {
    on<DailyGoalTitleChanged>(_onTitleChanged);
    on<DailyGoalDescriptionChanged>(_onDescriptionChanged);
    on<DailyGoalDateChanged>(_onDateChanged);
    on<DailyGoalSubmitted>(_onSubmitted);
  }

  final DailyGoalRepository _repository;

  void _onTitleChanged(DailyGoalTitleChanged event, Emitter<DailyGoalFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(title: event.title),
        status: DailyGoalFormStatus.editing,
        savedGoal: null,
        errorMessage: null,
      ),
    );
  }

  void _onDescriptionChanged(DailyGoalDescriptionChanged event, Emitter<DailyGoalFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(description: event.description),
        status: DailyGoalFormStatus.editing,
        savedGoal: null,
        errorMessage: null,
      ),
    );
  }

  void _onDateChanged(DailyGoalDateChanged event, Emitter<DailyGoalFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(targetDate: event.date),
        status: DailyGoalFormStatus.editing,
        savedGoal: null,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onSubmitted(DailyGoalSubmitted event, Emitter<DailyGoalFormState> emit) async {
    if (!state.isValid) {
      emit(state.copyWith(status: DailyGoalFormStatus.failure, errorMessage: 'Preencha os campos obrigatórios.'));
      emit(state.copyWith(status: DailyGoalFormStatus.editing, errorMessage: null));
      return;
    }

    emit(state.copyWith(status: DailyGoalFormStatus.submitting, errorMessage: null));
    try {
      final saved = await _repository.upsertGoal(state.draft);
      emit(
        state.copyWith(
          status: DailyGoalFormStatus.success,
          savedGoal: saved,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DailyGoalFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
      emit(state.copyWith(status: DailyGoalFormStatus.editing));
    }
  }
}


