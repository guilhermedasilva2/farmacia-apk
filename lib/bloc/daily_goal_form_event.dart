part of 'daily_goal_form_bloc.dart';

abstract class DailyGoalFormEvent extends Equatable {
  const DailyGoalFormEvent();

  @override
  List<Object?> get props => [];
}

class DailyGoalTitleChanged extends DailyGoalFormEvent {
  const DailyGoalTitleChanged(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

class DailyGoalDescriptionChanged extends DailyGoalFormEvent {
  const DailyGoalDescriptionChanged(this.description);
  final String description;

  @override
  List<Object?> get props => [description];
}

class DailyGoalDateChanged extends DailyGoalFormEvent {
  const DailyGoalDateChanged(this.date);
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class DailyGoalSubmitted extends DailyGoalFormEvent {
  const DailyGoalSubmitted();
}


