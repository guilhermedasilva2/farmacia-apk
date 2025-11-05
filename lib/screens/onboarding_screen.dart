import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
// removed unused shared_preferences import
import 'package:flutter/services.dart';
import 'package:meu_app_inicial/services/policy_service.dart';
import 'package:meu_app_inicial/services/prefs_service.dart';
import 'package:meu_app_inicial/services/consent_service.dart';
import '../utils/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _finalAcknowledge = false;
  bool _initialized = false;
  late PrefsService _prefsService;
  late PolicyService _policyService;
  late ConsentService _consentService;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Bem-vindo à PharmaConnect',
      'subtitle': 'Sua farmácia completa na palma da sua mão.',
      'image': 'assets/images/onboarding_illustration.png',
    },
    {
      'title': 'Como Funciona',
      'subtitle':
          'Navegue pelos produtos, adicione ao carrinho e receba em casa.',
      'image': 'assets/images/onboarding_illustration.png',
    },
    {
      'title': 'Políticas e Termos',
      'subtitle': 'Leia até o final e confirme para continuar.',
      'image': 'assets/images/onboarding_illustration.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    PrefsService.create().then((prefs) {
      _prefsService = prefs;
      _policyService = PolicyService(prefsService: _prefsService, privacyVersion: 1, termsVersion: 1);
      _consentService = ConsentService(prefsService: _prefsService, currentConsentVersion: 1);
      setState(() => _initialized = true);
    });
  }

  Future<void> _openPolicy(PolicyDocument doc) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.policy,
      arguments: {'doc': doc == PolicyDocument.privacy ? 'privacy' : 'terms'},
    );
    if (result == true) setState(() {});
  }

  Future<void> _finishOnboarding() async {
    final privacyRead = _initialized && _policyService.isRead(PolicyDocument.privacy);
    final termsRead = _initialized && _policyService.isRead(PolicyDocument.terms);
    if (!(privacyRead && termsRead && _finalAcknowledge)) return;

    await _consentService.acceptConsent();
    await _prefsService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == onboardingData.length - 1;
    bool isConsentPage = _currentPage == 2;
    final bool privacyRead = _initialized && _policyService.isRead(PolicyDocument.privacy);
    final bool termsRead = _initialized && _policyService.isRead(PolicyDocument.terms);
    final bool canAccept = isConsentPage ? (privacyRead && termsRead && _finalAcknowledge) : true;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                    visible: _currentPage > 0 && !isLastPage,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('Voltar',
                          style: TextStyle(color: Colors.teal)),
                    ),
                  ),
                  Visibility(
                    visible: !isLastPage && !isConsentPage,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: () => _controller.animateToPage(2,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn),
                      child: const Text('Pular',
                          style: TextStyle(color: Colors.teal)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                physics: isConsentPage
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            onboardingData[index]['image']!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          onboardingData[index]['title']!,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[index]['subtitle']!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        if (index == 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                const SizedBox(height: 12),
                                CheckboxListTile(
                                  value: _finalAcknowledge,
                                  onChanged: (v) => setState(() => _finalAcknowledge = v ?? false),
                                  title: const Text('Confirmo que li os documentos acima e concordo com os termos.'),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => SystemNavigator.pop(),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Recusar e sair do app'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
            Visibility(
              visible: !isLastPage,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: DotsIndicator(
                  dotsCount: onboardingData.length,
                  position: _currentPage,
                  decorator: DotsDecorator(
                    color: Colors.teal.shade100,
                    activeColor: Colors.teal,
                    size: const Size.square(9.0),
                    activeSize: const Size(18.0, 9.0),
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                onPressed: (!isConsentPage || canAccept)
                    ? () {
                        if (isLastPage) {
                          _finishOnboarding();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    : null,
                child: Text(isConsentPage && isLastPage ? 'Aceitar e continuar' : 'Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}