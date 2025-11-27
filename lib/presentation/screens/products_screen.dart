import 'package:flutter/material.dart';
import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/domain/entities/product.dart';
import 'package:meu_app_inicial/domain/entities/user_role.dart';
import 'package:meu_app_inicial/data/repositories/product_repository.dart';
import 'package:meu_app_inicial/core/services/user_role_service.dart';
import 'package:meu_app_inicial/core/services/cart_service.dart';
import 'package:meu_app_inicial/core/utils/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app_inicial/presentation/widgets/admin_product_form_dialog.dart';
import 'package:meu_app_inicial/presentation/widgets/product_actions_dialog.dart';

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
  final CartService _cartService = CartService();
  
  // Filtros e ordenação (Prompt 08)
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _showOnlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _initRepository();
    _loadUserRole();
    _cartService.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
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

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _handleProductTap(Product product) {
    Navigator.of(context).pushNamed(
      AppRoutes.productDetails,
      arguments: product,
    );
  }

  Future<void> _handlePurchase(Product product) async {
    if (!_currentRole.canPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Faça login para adicionar ao pedido'),
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

    // Adicionar ao carrinho/pedidos
    _cartService.addToCart(product);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} adicionado ao pedido'),
        action: SnackBarAction(
          label: 'Ver Pedidos',
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.orders);
          },
        ),
      ),
    );
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

  // Prompt 08: Pull-to-refresh
  Future<void> _handleRefresh() async {
    if (_repository == null) return;
    try {
      setState(() {
        _future = _repository!.fetchProducts();
      });
      await _future;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista atualizada'),
            duration: Duration(seconds: 1),
          ),
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

  // Prompt 08: Aplicar ordenação e filtros
  List<Product> _applySortingAndFilters(List<Product> products) {
    var filtered = products;

    // Filtrar por disponibilidade
    if (_showOnlyAvailable) {
      filtered = filtered.where((p) => p.available && p.quantity > 0).toList();
    }

    // Ordenar
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'name':
        default:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Prompt 09: Mostrar diálogo de ações
  void _showActionsDialog(Product product) {
    ProductActionsDialog.show(
      context,
      product: product,
      onEdit: () => _handleEdit(product),
      onRemove: () => _handleDelete(product),
    );
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
          // Prompt 08: Ordenação
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'name'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.sort_by_alpha,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Nome'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'price'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.attach_money,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Preço'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'quantity'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.inventory,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Estoque'),
                  ],
                ),
              ),
            ],
          ),
          // Prompt 08: Filtro de disponibilidade
          IconButton(
            icon: Icon(
              _showOnlyAvailable ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            tooltip: _showOnlyAvailable ? 'Mostrar todos' : 'Apenas disponíveis',
            onPressed: () {
              setState(() {
                _showOnlyAvailable = !_showOnlyAvailable;
              });
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.orders);
                },
              ),
              if (_cartService.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: FutureBuilder<List<Product>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
                  }
                  
                  // Aplicar filtros e ordenação (Prompt 08)
                  final allProducts = snapshot.data ?? const <Product>[];
                  final products = _applySortingAndFilters(allProducts);
                  
                  if (products.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _showOnlyAvailable
                                    ? 'Nenhum produto disponível no momento'
                                    : 'Nenhum produto cadastrado',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
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

              // Prompt 11: Swipe to dismiss (apenas para admins)
              final cardWidget = Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _handleProductTap(p),
                  onLongPress: () => _showActionsDialog(p), // Prompt 09: Long-press para ações
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
                ),
              );

              // Prompt 11: Retornar com Dismissible se for admin
              if (_currentRole.canManageProducts) {
                return Dismissible(
                  key: Key(p.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      barrierDismissible: false, // ✅ Conforme prompt
                      builder: (context) => AlertDialog(
                        title: const Text('Remover Produto'),
                        content: Text('Deseja remover "${p.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('NÃO'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('SIM'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _repository!.deleteProduct(p.id);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('${p.name} removido com sucesso')),
                        );
                        setState(() {
                          _future = _repository!.fetchProducts();
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erro ao remover: $e')),
                        );
                        setState(() {
                          _future = _repository!.fetchProducts();
                        });
                      }
                    }
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  child: cardWidget,
                );
              }
              
              return cardWidget;
            },
          );
        },
      ),
    ));
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

