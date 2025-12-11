import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app_inicial/features/medication_reminders/presentation/widgets/medication_reminder_form_bloc.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:meu_app_inicial/features/medication_reminders/domain/repositories/medication_reminder_repository.dart';
import 'package:meu_app_inicial/features/medication_reminders/infrastructure/repositories/medication_reminder_repository_impl.dart';

Future<MedicationReminder?> showMedicationReminderFormDialog(
  BuildContext context, {
  MedicationReminder? initialReminder,
  MedicationReminderRepository? repository,
}) async {
  final repo = repository ?? await CachedMedicationReminderRepository.create();
  if (!context.mounted) return null;
  return showDialog<MedicationReminder>(
    context: context,
    builder: (dialogContext) {
      return BlocProvider(
        create: (_) => MedicationReminderFormBloc(
          repository: repo,
          initialReminder: initialReminder,
        ),
        child: const MedicationReminderFormDialog(),
      );
    },
  );
}

class MedicationReminderFormDialog extends StatefulWidget {
  const MedicationReminderFormDialog({super.key});

  @override
  State<MedicationReminderFormDialog> createState() => _MedicationReminderFormDialogState();
}

class _MedicationReminderFormDialogState extends State<MedicationReminderFormDialog> {
  late final TextEditingController _medicineController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final state = context.read<MedicationReminderFormBloc>().state;
    _medicineController = TextEditingController(text: state.draft.medicationName);
    _dosageController = TextEditingController(text: state.draft.dosage);
    _notesController = TextEditingController(text: state.draft.notes);
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MedicationReminderFormBloc, MedicationReminderFormState>(
      listener: (context, state) {
        if (state.status == MedicationReminderFormStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.status == MedicationReminderFormStatus.success && state.savedReminder != null) {
          Navigator.of(context).pop(state.savedReminder);
        }
      },
      child: BlocBuilder<MedicationReminderFormBloc, MedicationReminderFormState>(
        builder: (context, state) {
          final bloc = context.read<MedicationReminderFormBloc>();
          final timeOfDay = TimeOfDay.fromDateTime(state.draft.scheduledAt);
          final formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay);

          if (_medicineController.text != state.draft.medicationName) {
            _medicineController.value = TextEditingValue(
              text: state.draft.medicationName,
              selection: TextSelection.collapsed(offset: state.draft.medicationName.length),
            );
          }
          if (_dosageController.text != state.draft.dosage) {
            _dosageController.value = TextEditingValue(
              text: state.draft.dosage,
              selection: TextSelection.collapsed(offset: state.draft.dosage.length),
            );
          }
          if (_notesController.text != state.draft.notes) {
            _notesController.value = TextEditingValue(
              text: state.draft.notes,
              selection: TextSelection.collapsed(offset: state.draft.notes.length),
            );
          }

          return AlertDialog(
            title: Text(state.draft.isPersisted ? 'Editar lembrete de medicação' : 'Novo lembrete de medicação'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _medicineController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Medicamento',
                      hintText: 'Ex: Amoxicilina',
                    ),
                    onChanged: (value) => bloc.add(MedicationNameChanged(value)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosagem',
                      hintText: 'Ex: 1 comprimido a cada 8h',
                    ),
                    onChanged: (value) => bloc.add(MedicationDosageChanged(value)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.draft.totalDoses.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Número de doses',
                      hintText: 'Quantas vezes você precisa tomar?',
                      helperText: 'O lembrete será concluído após tomar todas as doses',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final doses = int.tryParse(value);
                      if (doses != null && doses > 0) {
                        bloc.add(MedicationTotalDosesChanged(doses));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Instruções adicionais (opcional)',
                    ),
                    maxLines: 3,
                    onChanged: (value) => bloc.add(MedicationNotesChanged(value)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Horário: $formattedTime'),
                      ),
                      TextButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: timeOfDay,
                                );
                                if (picked != null) {
                                  final current = state.draft.scheduledAt;
                                  final newDateTime = DateTime(
                                    current.year,
                                    current.month,
                                    current.day,
                                    picked.hour,
                                    picked.minute,
                                  );
                                  bloc.add(MedicationTimeChanged(newDateTime));
                                }
                              },
                        icon: const Icon(Icons.schedule_outlined),
                        label: const Text('Alterar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: !state.isValid || state.isSubmitting
                    ? null
                    : () => bloc.add(const MedicationReminderSubmitted()),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }
}


