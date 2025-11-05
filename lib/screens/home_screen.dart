import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meu_app_inicial/services/prefs_service.dart';
import 'package:meu_app_inicial/services/consent_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_routes.dart';
import 'package:meu_app_inicial/widgets/user_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _resetOnboarding(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PharmaConnect'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: const UserDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tela de produtos ainda não implementada!')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
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