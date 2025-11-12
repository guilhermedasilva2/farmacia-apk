import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app_inicial/bloc/daily_goal_form_bloc.dart';
import 'package:meu_app_inicial/models/daily_goal.dart';
import 'package:meu_app_inicial/repositories/daily_goal_repository.dart';

Future<DailyGoal?> showDailyGoalEntityFormDialog(
  BuildContext context, {
  DailyGoal? initialGoal,
}) async {
  final repository = await SharedPreferencesDailyGoalRepository.create();
  return showDialog<DailyGoal>(
    context: context,
    builder: (dialogContext) {
      return BlocProvider(
        create: (_) => DailyGoalFormBloc(
          repository: repository,
          initialGoal: initialGoal,
        ),
        child: const DailyGoalEntityFormDialog(),
      );
    },
  );
}

class DailyGoalEntityFormDialog extends StatefulWidget {
  const DailyGoalEntityFormDialog({super.key});

  @override
  State<DailyGoalEntityFormDialog> createState() => _DailyGoalEntityFormDialogState();
}

class _DailyGoalEntityFormDialogState extends State<DailyGoalEntityFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = context.read<DailyGoalFormBloc>().state;
    _titleController = TextEditingController(text: state.draft.title);
    _descriptionController = TextEditingController(text: state.draft.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DailyGoalFormBloc, DailyGoalFormState>(
      listener: (context, state) {
        if (state.status == DailyGoalFormStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.status == DailyGoalFormStatus.success && state.savedGoal != null) {
          Navigator.of(context).pop(state.savedGoal);
        }
      },
      child: BlocBuilder<DailyGoalFormBloc, DailyGoalFormState>(
        builder: (context, state) {
          final bloc = context.read<DailyGoalFormBloc>();
          final formattedDate =
              MaterialLocalizations.of(context).formatMediumDate(state.draft.targetDate);

          if (_titleController.text != state.draft.title) {
            _titleController.value = TextEditingValue(
              text: state.draft.title,
              selection: TextSelection.collapsed(offset: state.draft.title.length),
            );
          }
          if (_descriptionController.text != state.draft.description) {
            _descriptionController.value = TextEditingValue(
              text: state.draft.description,
              selection: TextSelection.collapsed(offset: state.draft.description.length),
            );
          }

          return AlertDialog(
            title: Text(state.draft.isPersisted ? 'Editar meta diária' : 'Nova meta diária'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex: Caminhar 30 minutos',
                    ),
                    onChanged: (value) => bloc.add(DailyGoalTitleChanged(value)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Detalhes opcionais',
                    ),
                    maxLines: 3,
                    onChanged: (value) => bloc.add(DailyGoalDescriptionChanged(value)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Data alvo: $formattedDate'),
                      ),
                      TextButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: state.draft.targetDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  bloc.add(DailyGoalDateChanged(picked));
                                }
                              },
                        icon: const Icon(Icons.calendar_today_outlined),
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
                    : () => bloc.add(const DailyGoalSubmitted()),
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


