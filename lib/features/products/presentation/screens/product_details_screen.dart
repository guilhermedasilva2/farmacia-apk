import 'package:flutter/material.dart';
import 'package:meu_app_inicial/features/products/domain/entities/product.dart';
import 'package:meu_app_inicial/features/orders/infrastructure/services/cart_service.dart';
import 'package:meu_app_inicial/features/auth/infrastructure/services/auth_service.dart';
import 'package:meu_app_inicial/utils/app_routes.dart';
import 'package:meu_app_inicial/utils/custom_snackbar.dart';


class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final CartService _cartService = CartService();

  Future<void> _handlePurchase(Product product) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    final isSessionValid = authService.isSessionValid;

    if (currentUser == null || !isSessionValid) {
      if (currentUser != null) {
        await authService.signOut();
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

    CustomSnackbar.showInfo(
      context,
      '${product.name} adicionado ao pedido',
      action: SnackBarAction(
        label: 'Ver Pedidos',
        textColor: Colors.white,
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.orders);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    final hasStock = product.quantity > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.imageUrl.isNotEmpty)
              Hero(
                tag: 'product-${product.id}',
                child: Image.network(
                  product.imageUrl,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Icon(Icons.medication, size: 100, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.medication, size: 100, color: Colors.grey),
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
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Descrição',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (hasStock)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _handlePurchase(product),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Comprar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        'Produto Esgotado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
