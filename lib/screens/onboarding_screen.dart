import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  // ALTERAÇÃO: Variável renomeada para refletir o consentimento de marketing.
  // Começa como 'false' para atender ao requisito de "Opt-ins Desabilitados"[cite: 26].
  bool _marketingConsentGiven = false;

  // ALTERAÇÃO: Conteúdo da página 3 (índice 2) atualizado para Consentimento de Marketing[cite: 74].
  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Bem-vindo à FarmaFox',
      'subtitle': 'Sua farmácia completa na palma da sua mão.',
      'image': 'assets/images/FarmaFox.png',
    },
    {
      'title': 'Como Funciona',
      'subtitle':
          'Navegue pelos produtos, adicione ao carrinho e receba em casa.',
      'image': 'assets/images/FarmaFox.png',
    },
    {
      'title': 'Decisão de Marketing', // Título alterado.
      'subtitle':
          'Receba promoções e novidades exclusivas. Você pode alterar essa preferência a qualquer momento.', // Subtítulo alterado.
      'image': 'assets/images/FarmaFox.png',
    },
    {
      'title': 'Tudo Pronto!',
      'subtitle': 'Clique abaixo para começar a usar o aplicativo.',
      'image': 'assets/images/FarmaFox.png',
    }
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // ALTERAÇÃO: Salva as duas chaves de forma separada, como pedido no documento[cite: 30, 102, 104].
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('marketing_consent', _marketingConsentGiven);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.HOME);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == onboardingData.length - 1;
    // ALTERAÇÃO: A variável foi renomeada para maior clareza.
    bool isConsentPage = _currentPage == 2;

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
                  // Lógica do botão "Voltar" permanece a mesma, está correta[cite: 95].
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
                  // Lógica do botão "Pular" permanece a mesma, está correta[cite: 94].
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
                // ALTERAÇÃO: Bloqueio de gesto removido, pois a página de consentimento é opcional.
                physics: const AlwaysScrollableScrollPhysics(),
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
                        Image.asset(onboardingData[index]['image']!,
                            height: 150),
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
                        // ALTERAÇÃO: Lógica para exibir o Checkbox na página de consentimento.
                        if (isConsentPage)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _marketingConsentGiven,
                                  onChanged: (value) {
                                    setState(() {
                                      _marketingConsentGiven = value ?? false;
                                    });
                                  },
                                  activeColor: Colors.teal,
                                ),
                                const Flexible(
                                  // ALTERAÇÃO: Texto do consentimento.
                                  child: Text(
                                      'Eu aceito receber comunicações de marketing.'),
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
            // Lógica do DotsIndicator permanece a mesma, está correta[cite: 87].
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
                // ALTERAÇÃO: Lógica do onPressed simplificada. O botão não é mais desabilitado na página de consentimento.
                onPressed: () {
                  if (isLastPage) {
                    _finishOnboarding();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  // ALTERAÇÃO: Texto do botão alterado para "Continuar" na página de consentimento.
                  isLastPage ? 'Ir para o Acesso' : 'Continuar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}