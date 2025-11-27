import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meu_app_inicial/core/services/consent_service.dart';
import 'package:meu_app_inicial/core/services/policy_service.dart';
import 'package:meu_app_inicial/core/services/prefs_service.dart';
import 'package:meu_app_inicial/core/utils/app_routes.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _finalAcknowledge = false;
  late final PrefsService _prefsService;
  late final ConsentService _consentService;
  late final PolicyService _policyService;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    PrefsService.create().then((prefs) {
      _prefsService = prefs;
      _consentService = ConsentService(prefsService: _prefsService, currentConsentVersion: 1);
      _policyService = PolicyService(prefsService: _prefsService, privacyVersion: 1, termsVersion: 1);
      setState(() => _initialized = true);
    });
  }

  Future<void> _finish() async {
    final bothRead = _policyService.isRead(PolicyDocument.privacy) && _policyService.isRead(PolicyDocument.terms);
    if (!_finalAcknowledge || !bothRead) return;
    setState(() => _saving = true);
    await _consentService.acceptConsent();
    await _prefsService.setOnboardingCompleted(true);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
  }

  Future<void> _openPolicy(PolicyDocument doc) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.policy,
      arguments: {'doc': doc == PolicyDocument.privacy ? 'privacy' : 'terms'},
    );
    if (result == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool privacyRead = _initialized && _policyService.isRead(PolicyDocument.privacy);
    final bool termsRead = _initialized && _policyService.isRead(PolicyDocument.terms);
    final bool canAccept = privacyRead && termsRead && _finalAcknowledge && !_saving;

    return Scaffold(
      appBar: AppBar(title: const Text('Consentimento (Opt-in)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controle de Consentimento',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Para cumprir a LGPD, é necessário ler e aceitar os documentos:'),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(privacyRead ? Icons.check_circle : Icons.privacy_tip_outlined,
                    color: privacyRead ? Colors.green : null),
                title: const Text('Política de Privacidade (LGPD)'),
                subtitle: Text(privacyRead ? 'Lido' : 'Toque para ler (role até o final)'),
                onTap: () => _openPolicy(PolicyDocument.privacy),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(termsRead ? Icons.check_circle : Icons.article_outlined,
                    color: termsRead ? Colors.green : null),
                title: const Text('Termos de Uso'),
                subtitle: Text(termsRead ? 'Lido' : 'Toque para ler (role até o final)'),
                onTap: () => _openPolicy(PolicyDocument.terms),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _finalAcknowledge,
              onChanged: (v) => setState(() => _finalAcknowledge = v ?? false),
              title: const Text('Confirmo que li os documentos acima e concordo com os termos.'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Concluir e ir para a tela inicial',
              child: ElevatedButton(
                onPressed: canAccept ? _finish : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(_saving ? 'Salvando...' : 'Aceitar e continuar'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving ? null : () => SystemNavigator.pop(),
              icon: const Icon(Icons.close),
              label: const Text('Recusar e sair do app'),
              style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}


