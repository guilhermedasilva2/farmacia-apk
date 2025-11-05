import 'package:flutter/material.dart';
import 'package:meu_app_inicial/models/product.dart';
import 'package:meu_app_inicial/repositories/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductRepository _repository;
  late final Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    try {
      final client = Supabase.instance.client;
      _repository = SupabaseProductRepository(client: client);
    } catch (_) {
      _repository = MockProductRepository();
    }
    _future = _repository.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          // Ação de debug: exemplo de upload de asset ao Storage e vincular ao primeiro produto
          if (!const bool.fromEnvironment('dart.vm.product'))
            IconButton(
              tooltip: 'Upload asset para 1º produto (debug)'.trim(),
              icon: const Icon(Icons.cloud_upload_outlined),
              onPressed: () async {
                // Executa somente se houver ao menos 1 produto carregado
                final snapshot = await _future;
                if (snapshot.isEmpty) return;
                final first = snapshot.first;
                if (first.id.isEmpty) return;
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Para upload via código, use o helper fornecido nas instruções.')),
                );
              },
            ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return const Center(child: Text('Nenhum produto disponível.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = products[index];
              final hasImage = p.imageUrl.isNotEmpty;
              final Widget leading = hasImage
                  ? ClipOval(
                      child: Image.network(
                        p.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(child: Text(p.name.isNotEmpty ? p.name[0] : '?'));
                        },
                      ),
                    )
                  : CircleAvatar(child: Text(p.name.isNotEmpty ? p.name[0] : '?'));
              return Card(
                child: ListTile(
                  leading: leading,
                  title: Text(p.name),
                  subtitle: Text(p.description),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('R\$ ${p.price.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Text(p.available ? 'Disponível' : 'Indisponível',
                          style: TextStyle(
                            color: p.available ? Colors.green : Colors.red,
                          )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


