import 'package:flutter/material.dart';
import 'package:meu_app_inicial/dto/product_dto.dart';
import 'package:meu_app_inicial/models/product.dart';
import 'package:meu_app_inicial/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  ProductRepository? _repository;
  Future<List<Product>>? _future;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    final local = await SharedPreferencesProductLocalDataSource.create();
    ProductRemoteDataSource remote;
    try {
      remote = SupabaseProductRemoteDataSource(client: Supabase.instance.client);
    } catch (_) {
      remote = _FallbackRemote();
    }
    final repo = CachedProductRepository(
      remote: remote,
      local: local,
      fallback: const MockProductRepository(),
    );
    setState(() {
      _repository = repo;
      _future = repo.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;

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
                if (future == null) return;
                final snapshot = await future;
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
      body: future == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Product>>(
        future: future,
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


class _FallbackRemote implements ProductRemoteDataSource {
  @override
  Future<List<ProductDto>> fetchAll() async => [];
}

