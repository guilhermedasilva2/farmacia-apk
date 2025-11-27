import 'package:flutter/material.dart';
import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/domain/entities/product.dart';
import 'package:meu_app_inicial/domain/entities/user_role.dart';
import 'package:meu_app_inicial/data/repositories/product_repository.dart';
import 'package:meu_app_inicial/core/services/user_role_service.dart';
import 'package:meu_app_inicial/core/utils/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app_inicial/domain/entities/order.dart';
import 'package:meu_app_inicial/data/repositories/order_repository.dart';
import 'package:meu_app_inicial/presentation/widgets/admin_product_form_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  ProductRepository? _repository;
  Future<List<Product>>? _future;
  final _roleService = UserRoleService();
  UserRole _currentRole = UserRole.visitor;

  @override
  void initState() {
    super.initState();
    _initRepository();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _roleService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _currentRole = role;
      });
    }
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

    Future<void> _handlePurchase(Product product) async {
    if (!_currentRole.canPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Faça login para comprar produtos'),
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.auth);
            },
          ),
        ),
      );
      Navigator.of(context).pushNamed(AppRoutes.auth);
      return;
    }

    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto esgotado!')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Text('Deseja comprar 1x ${product.name} por R\$ ${product.price.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) return;

        final order = Order(
          id: '',
          customerId: currentUser.id,
          items: [
            OrderItem(
              productId: product.id,
              name: product.name,
              quantity: 1,
              unitPrice: product.price,
            ),
          ],
          status: OrderStatus.pending,
        );

        final orderRepo = OrderRepository();
        await orderRepo.createOrder(order);

        // Atualizar estoque
        if (_repository != null) {
          final newQuantity = product.quantity - 1;
          final dto = ProductDto(
            id: product.id,
            name: product.name,
            description: product.description,
            imageUrl: product.imageUrl,
            price: product.price,
            available: newQuantity > 0,
            quantity: newQuantity,
            categoryId: product.categoryId,
          );
          await _repository!.updateProduct(dto);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compra realizada com sucesso!')),
            );
            setState(() {
              _future = _repository!.fetchProducts();
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao processar compra: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleEdit(Product product) async {
    final result = await showDialog<ProductDto>(
      context: context,
      builder: (ctx) => AdminProductFormDialog(product: product),
    );

    if (result != null && _repository != null) {
      try {
        await _repository!.updateProduct(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto atualizado com sucesso!')),
          );
          setState(() {
            _future = _repository!.fetchProducts();
          });
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

  Future<void> _handleDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Deseja realmente excluir ${product.name}?'),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso!')),
          );
          setState(() {
            _future = _repository!.fetchProducts();
          });
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

  @override
  Widget build(BuildContext context) {
    final future = _future;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
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
      floatingActionButton: _currentRole.canManageProducts
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await showDialog<ProductDto>(
                  context: context,
                  builder: (ctx) => const AdminProductFormDialog(),
                );

                if (result != null && _repository != null) {
                  try {
                    await _repository!.createProduct(result);
                    if (!context.mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Produto adicionado com sucesso!')),
                    );
                    setState(() {
                      _future = _repository!.fetchProducts();
                    });
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao adicionar: $e')),
                    );
                  }
                }
              },
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
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
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.medication, color: Colors.grey[600]),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medication, color: Colors.grey[600]),
                    );

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'R\$ ${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.available ? Colors.green[50] : Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: p.available ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  child: Text(
                                    p.available ? 'Disponível' : 'Indisponível',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p.available ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Botões de ação baseados no role
                            if (_currentRole.canPurchase && p.available) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _handlePurchase(p),
                                  icon: const Icon(Icons.shopping_cart, size: 18),
                                  label: const Text('Comprar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (_currentRole.canManageProducts) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _handleEdit(p),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Editar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _handleDelete(p),
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('Excluir'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
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
  Future<List<ProductDto>> fetchAll({String? categoryId}) async => [];

  @override
  Future<void> create(ProductDto product) async {}

  @override
  Future<void> update(ProductDto product) async {}

  @override
  Future<void> delete(String id) async {}
}

