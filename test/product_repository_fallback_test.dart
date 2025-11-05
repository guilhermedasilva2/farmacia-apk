import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/repositories/product_repository.dart';

void main() {
  test('Repository falls back to mock when client is null', () async {
    final repo = SupabaseProductRepository(client: null);
    final products = await repo.fetchProducts();
    expect(products, isNotEmpty);
  });
}


