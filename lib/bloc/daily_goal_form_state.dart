part of 'daily_goal_form_bloc.dart';

enum DailyGoalFormStatus { editing, submitting, success, failure }

class DailyGoalFormState extends Equatable {
  const DailyGoalFormState({
    required this.draft,
    required this.status,
    this.errorMessage,
    this.savedGoal,
  });

  final DailyGoal draft;
  final DailyGoalFormStatus status;
  final String? errorMessage;
  final DailyGoal? savedGoal;

  bool get isValid => draft.isValid;
  bool get isSubmitting => status == DailyGoalFormStatus.submitting;

  DailyGoalFormState copyWith({
    DailyGoal? draft,
    DailyGoalFormStatus? status,
    String? errorMessage,
    DailyGoal? savedGoal,
  }) {
    return DailyGoalFormState(
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errorMessage: errorMessage,
      savedGoal: savedGoal,
    );
  }

  @override
  List<Object?> get props => [draft, status, errorMessage, savedGoal];
}


