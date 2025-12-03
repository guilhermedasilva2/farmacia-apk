import 'package:flutter/material.dart';
import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/data/models/remote_page.dart';
import 'package:meu_app_inicial/data/models/page_cursor.dart';
import 'package:meu_app_inicial/domain/entities/product.dart';
import 'package:meu_app_inicial/data/repositories/product_repository.dart';
import 'package:meu_app_inicial/presentation/widgets/admin_product_form_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  ProductRepository? _repository;
  List<Product> _products = [];
  bool _isLoading = true;

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
    
    if (mounted) {
      setState(() {
        _repository = repo;
      });
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (_repository == null) return;
    setState(() => _isLoading = true);
    try {
      final products = await _repository!.fetchProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  Future<void> _addProduct() async {

    final result = await showDialog<ProductDto>(
      context: context,
      builder: (ctx) => const AdminProductFormDialog(),
    );


    if (result != null && _repository != null) {
      try {

        await _repository!.createProduct(result);

        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto adicionado com sucesso!')),
          );
        }
      } catch (e) {
        // print('DEBUG: Error creating product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao adicionar: $e')),
          );
        }
      }
    } else {

    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await showDialog<ProductDto>(
      context: context,
      builder: (ctx) => AdminProductFormDialog(product: product),
    );

    if (result != null && _repository != null) {
      try {
        await _repository!.updateProduct(result);
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto atualizado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Tem certeza que deseja excluir "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && _repository != null) {
      try {
        await _repository!.deleteProduct(product.id);
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  Future<void> _showProductDetails(Product product) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem do produto
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.medication, size: 64, color: Colors.grey),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'R\$ ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estoque: ${product.quantity} unidades',
                      style: TextStyle(
                        fontSize: 14,
                        color: product.quantity > 0 ? Colors.grey[700] : Colors.red,
                        fontWeight: product.quantity > 0 ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (product.description.isNotEmpty) ...[
                      const Text(
                        'Descrição:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'close'),
                      child: const Text('FECHAR'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'edit'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      child: const Text('EDITAR'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'remove'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('REMOVER'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Processar ação escolhida
    if (action == 'edit') {
      await _editProduct(product);
    } else if (action == 'remove') {
      await _deleteProduct(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Estoque'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Nenhum produto cadastrado.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return _ProductGridItem(
                      product: product,
                      onTap: () => _showProductDetails(product),
                    );
                  },
                ),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  const _ProductGridItem({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.medication, size: 48, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'R\$ ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estoque: ${product.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.quantity > 0 ? Colors.grey[700] : Colors.red,
                      fontWeight: product.quantity > 0 ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackRemote implements ProductRemoteDataSource {
  @override
  Future<List<ProductDto>> fetchAll({String? categoryId, DateTime? since}) async => [];
  @override
  Future<void> create(ProductDto product) async {}
  @override
  Future<void> update(ProductDto product) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<int> upsertProducts(List<ProductDto> dtos) async => 0;
  @override
  Future<RemotePage<ProductDto>> fetchPage({PageCursor? cursor, int limit = 100, String? categoryId, DateTime? since}) async => RemotePage.empty();
}
