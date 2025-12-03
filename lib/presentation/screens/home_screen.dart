import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meu_app_inicial/core/services/prefs_service.dart';
import 'package:meu_app_inicial/core/services/consent_service.dart';
import 'package:meu_app_inicial/core/services/cart_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app_inicial/core/utils/app_routes.dart';
import 'package:meu_app_inicial/presentation/widgets/user_drawer.dart';
import 'package:meu_app_inicial/domain/entities/product.dart';
import 'package:meu_app_inicial/data/repositories/product_repository.dart';
import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/data/models/remote_page.dart';
import 'package:meu_app_inicial/data/models/page_cursor.dart';
import 'package:meu_app_inicial/domain/entities/category.dart';
import 'package:meu_app_inicial/data/repositories/category_repository.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _consentVersion = 1;
  ProductRepository? _repository;
  Future<List<Product>>? _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final CategoryRepository _categoryRepository = CategoryRepository();
  List<Category> _categories = [];
  final CartService _cartService = CartService();


  @override
  void initState() {
    super.initState();
    _initRepository();
    _loadCategories();
    _cartService.addListener(_onCartChanged);
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          // Rebuild UI on auth change
        });
      }
    });
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories in HomeScreen: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartService.removeListener(_onCartChanged);
    super.dispose();
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
        _productsFuture = repo.fetchProducts(); // Load all products
      });
    }
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
  }

  Future<void> _handleConsentManagement() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revogar consentimento?'),
        content: const Text('Você tem certeza que deseja revogar o consentimento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revogar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final prefs = await PrefsService.create();
    final service = ConsentService(prefsService: prefs, currentConsentVersion: _consentVersion);
    await service.revokeConsent();

    if (!mounted) return;
    final result = await showDialog<_RevocationDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: _RevocationCountdownDialog(
          duration: const Duration(seconds: 5),
        ),
      ),
    );

    if (!mounted) return;

    if (result == _RevocationDialogResult.undo) {
      await service.acceptConsent();
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(const SnackBar(content: Text('Consentimento restaurado')));
      return;
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(const SnackBar(content: Text('Redefinindo app...')));
    await _resetOnboarding();
  }

  void _handleProductTap(Product product) {
    Navigator.of(context).pushNamed(
      AppRoutes.productDetails,
      arguments: product,
    );
  }

  Future<void> _handlePurchase(Product product) async {
    final session = Supabase.instance.client.auth.currentSession;
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    if (currentUser == null || session == null || session.isExpired) {
      if (currentUser != null) {
         await Supabase.instance.client.auth.signOut();
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para adicionar ao pedido.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_repository != null) {
                setState(() {
                  _productsFuture = _repository!.fetchProducts(); // Load all products
                });
                _loadCategories(); // Reload categories as well
              }
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
        ],
      ),
      drawer: const UserDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleConsentManagement,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.privacy_tip_outlined),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bem-vindo à PharmaConnect!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar produtos...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _productsFuture == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<List<Product>>(
                      future: _productsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Erro ao carregar produtos:\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _productsFuture = _repository!.fetchProducts(); // Load all products
                                      });
                                    },
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        var products = snapshot.data ?? [];
                        
                        // Filtrar produtos pela busca
                        if (_searchQuery.isNotEmpty) {
                          products = products.where((p) => 
                            p.name.toLowerCase().contains(_searchQuery) || 
                            p.description.toLowerCase().contains(_searchQuery)
                          ).toList();
                        }

                        if (products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty 
                                    ? 'Nenhum produto encontrado para "$_searchQuery".'
                                    : 'Nenhum produto disponível no momento.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        // Agrupar produtos por categoria
                        Map<String, List<Product>> productsByCategory = {};
                        List<Product> uncategorized = [];
                        

                        for (var product in products) {

                          if (product.categoryId != null) {
                            productsByCategory.putIfAbsent(product.categoryId!, () => []).add(product);
                          } else {
                            uncategorized.add(product);
                          }
                        }
                        


                        return ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            // Carrosséis por categoria
                            ..._categories.where((cat) => productsByCategory.containsKey(cat.id)).map((category) {
                              final categoryProducts = productsByCategory[category.id]!;

                              return _CategoryCarousel(
                                categoryName: category.name,
                                products: categoryProducts,
                                onProductTap: _handleProductTap,
                                onPurchase: _handlePurchase,
                              );
                            }),
                            // Produtos sem categoria (lista vertical)
                            if (uncategorized.isNotEmpty)
                              _UncategorizedProductList(
                                products: uncategorized,
                                onProductTap: _handleProductTap,
                                onPurchase: _handlePurchase,
                              ),
                          ],
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

class _UncategorizedProductList extends StatelessWidget {
  const _UncategorizedProductList({
    required this.products,
    required this.onProductTap,
    required this.onPurchase,
  });

  final List<Product> products;
  final void Function(Product) onProductTap;
  final void Function(Product) onPurchase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Outros Produtos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...products.map((p) {
          final hasStock = p.quantity > 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onProductTap(p),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: p.imageUrl.isNotEmpty
                            ? Image.network(
                                p.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.medication, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.medication, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 16),
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
                            const SizedBox(height: 4),
                            Text(
                              'Estoque: ${p.quantity} unidades',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasStock ? Colors.grey[700] : Colors.red,
                                fontWeight: hasStock ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'R\$ ${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                if (hasStock)
                                  ElevatedButton(
                                    onPressed: () => onPurchase(p),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: const Text('Comprar'),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red[200]!),
                                    ),
                                    child: Text(
                                      'Esgotado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CategoryCarousel extends StatelessWidget {
  const _CategoryCarousel({
    required this.categoryName,
    required this.products,
    required this.onProductTap,
    required this.onPurchase,
  });

  final String categoryName;
  final List<Product> products;
  final void Function(Product) onProductTap;
  final void Function(Product) onPurchase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            categoryName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final hasStock = product.quantity > 0;
              
              return SizedBox(
                width: 160,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onProductTap(product),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.medication, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.medication, color: Colors.grey),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'R\$ ${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (hasStock)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => onPurchase(product),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 32),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: const Text('Comprar'),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Text(
                                    'Esgotado',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

enum _RevocationDialogResult { undo, timeout }

class _RevocationCountdownDialog extends StatefulWidget {
  const _RevocationCountdownDialog({required this.duration});

  final Duration duration;

  @override
  State<_RevocationCountdownDialog> createState() => _RevocationCountdownDialogState();
}

class _RevocationCountdownDialogState extends State<_RevocationCountdownDialog> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final secondsLeft = _remaining.inSeconds - 1;
    if (secondsLeft <= 0) {
      _timer?.cancel();
      Navigator.of(context).pop(_RevocationDialogResult.timeout);
      return;
    }
    setState(() {
      _remaining = Duration(seconds: secondsLeft);
    });
  }

  void _handleUndo() {
    _timer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(_RevocationDialogResult.undo);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (widget.duration.inSeconds == 0) return 0;
    return (_remaining.inSeconds / widget.duration.inSeconds).clamp(0, 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Redefinição agendada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('O app será resetado automaticamente em:'),
          const SizedBox(height: 12),
          Text(
            _formatDuration(_remaining),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 12),
          const Text('Toque em "Desfazer" para restaurar o consentimento antes do tempo expirar.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _handleUndo,
          child: const Text('Desfazer'),
        ),
      ],
    );
  }
}
