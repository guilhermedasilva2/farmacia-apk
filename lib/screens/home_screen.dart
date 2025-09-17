import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FarmaFox'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Bem-vindo à FarmaFox!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Image.asset('assets/images/FarmaFox.png', width: 40),
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
          ],
        ),
      ),
    );
  }
}
