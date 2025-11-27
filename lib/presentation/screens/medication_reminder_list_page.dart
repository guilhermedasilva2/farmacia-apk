import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:meu_app_inicial/domain/entities/medication_reminder.dart';
import 'package:meu_app_inicial/domain/repositories/medication_reminder_repository.dart';
import 'package:meu_app_inicial/data/repositories/medication_reminder_repository.dart';
import 'package:meu_app_inicial/presentation/widgets/medication_reminder_form_dialog.dart';



class MedicationReminderListPage extends StatefulWidget {
  const MedicationReminderListPage({super.key});

  @override
  State<MedicationReminderListPage> createState() => _MedicationReminderListPageState();
}

class _MedicationReminderListPageState extends State<MedicationReminderListPage>
    with SingleTickerProviderStateMixin {
  MedicationReminderRepository? _repository;
  List<MedicationReminder> _activeReminders = [];
  List<MedicationReminder> _takenReminders = [];
  bool _showTips = true;
  bool _showOverlay = true;
  bool _isLoading = true;

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  late final Animation<Offset> _tipOffset;

  @override
  void initState() {
    super.initState();
    _initRepository();
    
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _tipOffset = Tween<Offset>(begin: const Offset(0, 0.2), end: const Offset(0, 0))
        .animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));

    _fabController.addStatusListener((status) {
      if (!_showTips) return;
      if (status == AnimationStatus.completed) {
        _fabController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _fabController.forward();
      }
    });
  }

  Future<void> _initRepository() async {
    final repo = await SharedPreferencesMedicationReminderRepository.create();
    if (!mounted) return;
    setState(() {
      _repository = repo;
    });
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_showTips) {
        _fabController.forward();
      }
      _refreshReminders();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _createReminder() async {
    if (_repository == null) return;
    final reminder = await showMedicationReminderFormDialog(context, repository: _repository!);
    if (reminder == null) return;

    await _refreshReminders();
    _dismissTips();
    setState(() => _showOverlay = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lembrete de "${reminder.medicationName}" adicionado!')),
      );
    }
  }

  Future<void> _refreshReminders() async {
    if (_repository == null) return;
    final list = await _repository!.listReminders();
    if (!mounted) return;
    setState(() {
      _activeReminders = list.where((element) => !element.isTaken).toList(growable: false);
      _takenReminders = list.where((element) => element.isTaken).toList(growable: false);
      _isLoading = false;
    });
  }

  Future<void> _onTakeDose(MedicationReminder reminder) async {
    if (_repository == null) return;
    
    final newTaken = reminder.takenDoses + 1;
    // Se já tomou tudo, não faz nada ou poderia resetar? 
    // Vamos permitir "desmarcar" se estiver na lista de concluídos
    
    await _repository!.upsertReminder(reminder.copyWith(takenDoses: newTaken));
    await _refreshReminders();
  }

  Future<void> _onUndoDose(MedicationReminder reminder) async {
    if (_repository == null) return;
    final newTaken = (reminder.takenDoses - 1).clamp(0, reminder.totalDoses);
    await _repository!.upsertReminder(reminder.copyWith(takenDoses: newTaken));
    await _refreshReminders();
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    if (_repository == null) return;
    await _repository!.deleteReminder(reminder.id);
    await _refreshReminders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lembrete de "${reminder.medicationName}" removido.')),
    );
  }

  void _dismissTips() {
    if (!_showTips) return;
    setState(() {
      _showTips = false;
      _fabController.stop();
    });
  }

  Future<void> _showReminderDetails(MedicationReminder reminder) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.medicationName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Horário: ${TimeOfDay.fromDateTime(reminder.scheduledAt).format(context)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reminder.dosage.isNotEmpty) ...[
                      const Text('Dosagem:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(reminder.dosage),
                      const SizedBox(height: 12),
                    ],
                    const Text('Progresso:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: reminder.totalDoses > 0 
                          ? reminder.takenDoses / reminder.totalDoses 
                          : 0,
                      backgroundColor: Colors.grey[200],
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 4),
                    Text('${reminder.takenDoses} de ${reminder.totalDoses} doses tomadas'),
                    const SizedBox(height: 12),
                    if (reminder.notes.isNotEmpty) ...[
                      const Text('Notas:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(reminder.notes),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'close'),
                      child: const Text('FECHAR'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'edit'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      child: const Text('EDITAR'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'remove'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('REMOVER'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'edit') {
      await _editReminder(reminder);
    } else if (action == 'remove') {
      await _deleteReminder(reminder);
    }
  }

  Future<void> _editReminder(MedicationReminder reminder) async {
    if (_repository == null) return;
    final updated = await showMedicationReminderFormDialog(
      context, 
      repository: _repository!,
      initialReminder: reminder,
    );
    if (updated != null) {
      await _refreshReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lembrete atualizado!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _repository == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lembretes de Medicação'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final emptyState = _activeReminders.isEmpty && _takenReminders.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembretes de Medicação'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: emptyState
                ? _EmptyState(
                    onAdd: _createReminder,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_activeReminders.isNotEmpty)
                        ...[
                          Text(
                            'Próximos lembretes',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._activeReminders.map(
                            (reminder) => _ReminderTile(
                              reminder: reminder,
                              onTake: () => _onTakeDose(reminder),
                              onUndo: () => _onUndoDose(reminder),
                              onTap: () => _showReminderDetails(reminder),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      if (_takenReminders.isNotEmpty)
                        ...[
                          Text(
                            'Concluídos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._takenReminders.map(
                            (reminder) => _ReminderTile(
                              reminder: reminder,
                              onTake: () => _onTakeDose(reminder),
                              onUndo: () => _onUndoDose(reminder),
                              onTap: () => _showReminderDetails(reminder),
                            ),
                          ),
                        ],
                    ],
                  ),
          ),
          if (_showOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() => _showOverlay = false);
                },
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Organize sua rotina de medicamentos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Use esta tela para cadastrar lembretes rápidos e não esquecer as suas doses.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              setState(() => _showOverlay = false);
                            },
                            child: const Text('Entendi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_showTips)
            Positioned(
              right: 24,
              bottom: 96,
              child: SlideTransition(
                position: _tipOffset,
                child: _TipBubble(
                  onDismissed: () {
                    _dismissTips();
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _showTips ? _fabScale : const AlwaysStoppedAnimation(1.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await _createReminder();
          },
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onTake,
    required this.onUndo,
    required this.onTap,
  });

  final MedicationReminder reminder;
  final VoidCallback onTake;
  final VoidCallback onUndo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(reminder.scheduledAt).format(context);
    final isCompleted = reminder.isTaken;
    final progress = '${reminder.takenDoses}/${reminder.totalDoses}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ListTile(
            leading: isCompleted
                ? IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: onUndo,
                    tooltip: 'Desfazer conclusão',
                  )
                : IconButton(
                    icon: const Icon(Icons.circle_outlined),
                    onPressed: onTake,
                    tooltip: 'Tomar dose',
                  ),
            title: Text(
              reminder.medicationName,
              style: isCompleted
                  ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                  : const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Horário: $time'),
                if (reminder.dosage.isNotEmpty) Text('Dosagem: ${reminder.dosage}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Doses: $progress',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (reminder.notes.isNotEmpty)
                  Text(
                    reminder.notes,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: !isCompleted
                ? FilledButton.tonal(
                    onPressed: onTake,
                    child: const Text('Tomar'),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Toque em “Adicionar” para registrar seu próximo remédio.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDismissed,
              child: const Text('Não mostrar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_liquid_outlined, size: 72, color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'Nenhum lembrete por aqui ainda.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre os horários dos seus medicamentos para não esquecer nenhuma dose.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAdd,
              child: const Text('Cadastrar primeiro lembrete'),
            ),
          ],
        ),
      ),
    );
  }
}


