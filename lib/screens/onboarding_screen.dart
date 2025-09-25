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
  // Variável para o consentimento de marketing, começa como 'false'.
  bool _marketingConsentGiven = false;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Bem-vindo à PharmaConnect',
      'subtitle': 'Sua farmácia completa na palma da sua mão.',
      'image': 'assets/images/PharmaConnect.png',
    },
    {
      'title': 'Como Funciona',
      'subtitle':
          'Navegue pelos produtos, adicione ao carrinho e receba em casa.',
      'image': 'assets/images/PharmaConnect.png',
    },
    {
      'title': 'Decisão de Marketing',
      'subtitle':
          'Receba promoções e novidades exclusivas. Você precisa aceitar para continuar.', // Subtítulo ajustado para clareza
      'image': 'assets/images/PharmaConnect.png',
    },
    {
      'title': 'Tudo Pronto!',
      'subtitle': 'Clique abaixo para começar a usar o aplicativo.',
      'image': 'assets/images/PharmaConnect.png',
    }
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
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
    // Variável que identifica a página de consentimento (página de índice 2).
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
                  // Botão "Voltar"
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
                  // Botão "Pular" (não aparece na tela de consentimento)
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
                // CÓDIGO CORRIGIDO 1: Bloqueia o deslize na página de consentimento.
                // O usuário não pode mais arrastar para a próxima tela sem interagir.
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
                        // Mostra o Checkbox apenas na página de consentimento
                        if (index == 2) // Usar 'index' aqui é mais seguro dentro do builder
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
            // Indicador de pontos
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
                // CÓDIGO CORRIGIDO 2: Lógica do botão.
                // Se for a página de consentimento E o consentimento não foi dado,
                // o valor de onPressed será 'null', desabilitando o botão.
                onPressed: (isConsentPage && !_marketingConsentGiven)
                    ? null
                    : () {
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