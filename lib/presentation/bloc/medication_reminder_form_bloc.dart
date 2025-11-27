import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app_inicial/domain/entities/medication_reminder.dart';
import 'package:meu_app_inicial/domain/repositories/medication_reminder_repository.dart';


part 'medication_reminder_form_event.dart';
part 'medication_reminder_form_state.dart';

class MedicationReminderFormBloc extends Bloc<MedicationReminderFormEvent, MedicationReminderFormState> {
  MedicationReminderFormBloc({
    required MedicationReminderRepository repository,
    MedicationReminder? initialReminder,
  })  : _repository = repository,
        super(
          MedicationReminderFormState(
            draft: initialReminder ??
                MedicationReminder(
                  id: '',
                  medicationName: '',
                  dosage: '',
                  notes: '',
                  scheduledAt: DateTime.now(),
                ),
            status: MedicationReminderFormStatus.editing,
          ),
        ) {
    on<MedicationNameChanged>(_onNameChanged);
    on<MedicationDosageChanged>(_onDosageChanged);
    on<MedicationNotesChanged>(_onNotesChanged);
    on<MedicationTimeChanged>(_onTimeChanged);
    on<MedicationTotalDosesChanged>(_onTotalDosesChanged);
    on<MedicationReminderSubmitted>(_onSubmitted);
  }

  final MedicationReminderRepository _repository;

  void _onNameChanged(MedicationNameChanged event, Emitter<MedicationReminderFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(medicationName: event.name),
        status: MedicationReminderFormStatus.editing,
        errorMessage: null,
        savedReminder: null,
      ),
    );
  }

  void _onDosageChanged(MedicationDosageChanged event, Emitter<MedicationReminderFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(dosage: event.dosage),
        status: MedicationReminderFormStatus.editing,
        errorMessage: null,
        savedReminder: null,
      ),
    );
  }

  void _onNotesChanged(MedicationNotesChanged event, Emitter<MedicationReminderFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(notes: event.notes),
        status: MedicationReminderFormStatus.editing,
        errorMessage: null,
        savedReminder: null,
      ),
    );
  }

  void _onTimeChanged(MedicationTimeChanged event, Emitter<MedicationReminderFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(scheduledAt: event.time),
        status: MedicationReminderFormStatus.editing,
        errorMessage: null,
        savedReminder: null,
      ),
    );
  }

  void _onTotalDosesChanged(MedicationTotalDosesChanged event, Emitter<MedicationReminderFormState> emit) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(totalDoses: event.totalDoses),
        status: MedicationReminderFormStatus.editing,
        errorMessage: null,
        savedReminder: null,
      ),
    );
  }

  Future<void> _onSubmitted(
    MedicationReminderSubmitted event,
    Emitter<MedicationReminderFormState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(status: MedicationReminderFormStatus.failure, errorMessage: 'Informe o nome do medicamento.'));
      emit(state.copyWith(status: MedicationReminderFormStatus.editing, errorMessage: null));
      return;
    }

    emit(state.copyWith(status: MedicationReminderFormStatus.submitting, errorMessage: null));
    try {
      final saved = await _repository.upsertReminder(state.draft);
      emit(
        state.copyWith(
          status: MedicationReminderFormStatus.success,
          savedReminder: saved,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MedicationReminderFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
      emit(state.copyWith(status: MedicationReminderFormStatus.editing));
    }
  }
}


