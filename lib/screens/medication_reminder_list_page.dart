import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:meu_app_inicial/models/medication_reminder.dart';
import 'package:meu_app_inicial/repositories/medication_reminder_repository.dart';
import 'package:meu_app_inicial/widgets/medication_reminder_form_dialog.dart';

class MedicationReminderListPage extends StatefulWidget {
  const MedicationReminderListPage({super.key});

  @override
  State<MedicationReminderListPage> createState() => _MedicationReminderListPageState();
}

class _MedicationReminderListPageState extends State<MedicationReminderListPage>
    with SingleTickerProviderStateMixin {
  late final InMemoryMedicationReminderRepository _repository;
  List<MedicationReminder> _activeReminders = [];
  List<MedicationReminder> _takenReminders = [];
  bool _showTips = true;
  bool _showOverlay = true;

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  late final Animation<Offset> _tipOffset;

  @override
  void initState() {
    super.initState();
    _repository = InMemoryMedicationReminderRepository();
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
    final reminder = await showMedicationReminderFormDialog(context, repository: _repository);
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
    final list = await _repository.listReminders();
    if (!mounted) return;
    setState(() {
      _activeReminders = list.where((element) => !element.isTaken).toList(growable: false);
      _takenReminders = list.where((element) => element.isTaken).toList(growable: false);
    });
  }

  Future<void> _toggleReminder(MedicationReminder reminder, bool value) async {
    await _repository.upsertReminder(reminder.copyWith(isTaken: value));
    await _refreshReminders();
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    await _repository.deleteReminder(reminder.id);
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

  @override
  Widget build(BuildContext context) {
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
                              onToggle: (value) => _toggleReminder(reminder, value),
                              onDelete: () => _deleteReminder(reminder),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      if (_takenReminders.isNotEmpty)
                        ...[
                          Text(
                            'Já administrados',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._takenReminders.map(
                            (reminder) => _ReminderTile(
                              reminder: reminder,
                              onToggle: (value) => _toggleReminder(reminder, value),
                              onDelete: () => _deleteReminder(reminder),
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
    required this.onToggle,
    required this.onDelete,
  });

  final MedicationReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(reminder.scheduledAt).format(context);
    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Checkbox(
            value: reminder.isTaken,
            onChanged: (value) => onToggle(value ?? false),
          ),
          title: Text(
            reminder.medicationName,
            style: reminder.isTaken
                ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                : null,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horário: $time'),
              if (reminder.dosage.isNotEmpty) Text('Dosagem: ${reminder.dosage}'),
              if (reminder.notes.isNotEmpty)
                Text(
                  reminder.notes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
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


