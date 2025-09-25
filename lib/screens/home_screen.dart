import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_routes.dart';

class HomeScreen extends StatelessWidget {
  // Adicionado 'const' ao construtor do widget
  const HomeScreen({super.key});

  void _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // A verificação 'mounted' é uma boa prática, mas neste contexto
    // não é estritamente necessária, pois a navegação já ocorre.
    // Vamos mantê-la simples.
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.SPLASH, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Adicionado 'const' ao texto do título
        title: const Text('PharmaConnect'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          // Adicionado 'const' ao padding
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Adicionado 'const' ao texto
              const Text(
                'Bem-vindo à PharmaConnect!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // Adicionado 'const' ao SizedBox
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  // Adicionado 'const' ao borderRadius
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Image.asset('assets/images/PharmaConnect.png', width: 40),
                  // Adicionado 'const' aos textos
                  title: const Text('Confira nossos produtos'),
                  subtitle: const Text('Clique para explorar a farmácia online'),
                  // Adicionado 'const' ao ícone
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      // Adicionado 'const' ao SnackBar e seu conteúdo
                      const SnackBar(content: Text('Tela de produtos ainda não implementada!')),
                    );
                  },
                ),
              ),
              // Adicionado 'const' ao SizedBox
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => _resetOnboarding(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Adicionado 'const' ao padding
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                // Adicionado 'const' ao texto do botão
                child: const Text('Resetar Onboarding (Teste)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}