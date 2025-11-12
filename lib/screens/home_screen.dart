import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meu_app_inicial/services/prefs_service.dart';
import 'package:meu_app_inicial/services/consent_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app_inicial/widgets/medication_reminder_form_dialog.dart';
import 'package:meu_app_inicial/models/medication_reminder.dart';
import 'package:meu_app_inicial/repositories/medication_reminder_repository.dart';
import '../utils/app_routes.dart';
import 'package:meu_app_inicial/widgets/user_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SharedPreferencesMedicationReminderRepository? _reminderRepository;
  List<MedicationReminder> _reminders = const [];
  bool _isLoadingReminders = true;

  @override
  void initState() {
    super.initState();
    _initReminderRepository();
  }

  Future<void> _initReminderRepository() async {
    final repo = await SharedPreferencesMedicationReminderRepository.create();
    if (!mounted) return;
    setState(() {
      _reminderRepository = repo;
    });
    await _loadReminders();
  }

  Future<void> _loadReminders() async {
    final repo = _reminderRepository;
    if (repo == null) return;
    final data = await repo.listReminders();
    if (!mounted) return;
    setState(() {
      _reminders = data;
      _isLoadingReminders = false;
    });
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    navigator.pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
  }

  Future<void> _revokeConsent(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revogar consentimento?'),
        content: const Text('Você tem certeza que deseja revogar o consentimento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revogar')),
        ],
      ),
    );
    if (confirmed != true) return;

    final prefs = await PrefsService.create();
    final service = ConsentService(prefsService: prefs, currentConsentVersion: 1);
    await service.revokeConsent();

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Consentimento revogado'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            await service.acceptConsent();
            messenger.showSnackBar(const SnackBar(content: Text('Consentimento restaurado')));
          },
        ),
      ),
    );
  }

  Future<void> _openMedicationReminderDialog(BuildContext context) async {
    final result = await showMedicationReminderFormDialog(context);
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lembrete de "${result.medicationName}" salvo!')),
      );
      await _loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PharmaConnect'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: const UserDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bem-vindo à PharmaConnect!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Image.asset('assets/images/PharmaConnect.png', width: 40),
                  title: const Text('Confira nossos produtos'),
                  subtitle: const Text('Clique para explorar a farmácia online'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.products);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.medication_outlined, color: Colors.teal),
                  title: const Text('Adicionar lembrete de medicação'),
                  subtitle: const Text('Configure horários e doses para seus remédios'),
                  trailing: const Icon(Icons.add),
                  onTap: () => _openMedicationReminderDialog(context),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingReminders)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                )
              else if (_reminders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: const [
                      Icon(Icons.notifications_none, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Nenhum lembrete de medicação cadastrado.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seus lembretes de medicação',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._reminders.map(
                      (reminder) => Card(
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.alarm, color: Colors.teal),
                          title: Text(reminder.medicationName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (reminder.dosage.isNotEmpty) Text('Dosagem: ${reminder.dosage}'),
                              Text(
                                'Horário: ${TimeOfDay.fromDateTime(reminder.scheduledAt).format(context)}',
                              ),
                              if (reminder.notes.isNotEmpty)
                                Text(
                                  reminder.notes,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.cloud_done_outlined, color: Colors.teal),
                  title: const Text('Testar conexão com Supabase'),
                  subtitle: const Text('Executa uma chamada simples e mostra o resultado'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final client = Supabase.instance.client;
                      await client.from('_health_check_table').select().limit(1);
                      messenger.showSnackBar(const SnackBar(content: Text('Conexão OK')));
                    } catch (e) {
                      final msg = e.toString();
                      if (msg.contains('relation') || msg.contains('exists') || msg.contains('404') || msg.contains('Not Found') || msg.contains('Postgrest')) {
                        messenger.showSnackBar(const SnackBar(content: Text('Conexão OK (API respondeu)')));
                      } else {
                        messenger.showSnackBar(SnackBar(content: Text('Falha ao conectar: $msg')));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gerenciar consentimento de dados'),
                subtitle: const Text('Revogar/Restaurar (LGPD)'),
                onTap: () => _revokeConsent(context),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _resetOnboarding(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Resetar Onboarding (Teste)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}