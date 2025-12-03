import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/data/models/remote_page.dart';
import 'package:meu_app_inicial/data/models/page_cursor.dart';
import 'package:meu_app_inicial/domain/entities/product.dart';
import 'package:meu_app_inicial/data/repositories/product_repository_impl.dart';
import 'package:meu_app_inicial/domain/repositories/product_repository.dart';

class FakeRemote implements ProductRemoteDataSource {
  FakeRemote(this._dtos, {this.shouldThrow = false});

  final List<ProductDto> _dtos;
  final bool shouldThrow;

  @override
  Future<List<ProductDto>> fetchAll({String? categoryId, DateTime? since}) async {
    if (shouldThrow) throw Exception('remote error');
    return _dtos;
  }

  @override
  Future<void> create(ProductDto product) async {}

  @override
  Future<void> update(ProductDto product) async {}

  @override
  Future<void> delete(String id) async {}
  
  @override
  Future<int> upsertProducts(List<ProductDto> dtos) async => dtos.length;
  
  @override
  Future<RemotePage<ProductDto>> fetchPage({
    PageCursor? cursor,
    int limit = 100,
    String? categoryId,
    DateTime? since,
  }) async {
    if (shouldThrow) throw Exception('remote error');
    return RemotePage(items: _dtos);
  }
}

class FakeLocal implements ProductLocalDataSource {
  FakeLocal(this._storage);

  final Map<String, ProductDto> _storage;

  @override
  Future<List<ProductDto>> readAll() async {
    return _storage.values.toList(growable: false);
  }

  @override
  Future<void> upsertAll(List<ProductDto> dtos) async {
    for (final dto in dtos) {
      _storage[dto.id] = dto;
    }
  }

  DateTime? _lastSync;

  @override
  Future<DateTime?> getLastSync() async => _lastSync;

  @override
  Future<void> setLastSync(DateTime time) async {
    _lastSync = time;
  }
}

class FakeFallback implements ProductRepository {
  @override
  Future<List<Product>> loadFromCache() async => [];

  @override
  Future<int> syncFromServer() async => 0;

  @override
  Future<List<Product>> fetchProducts({String? categoryId}) async {
    return const [
      Product(
        id: 'fallback',
        name: 'Fallback',
        description: '',
        imageUrl: '',
        price: 0,
        available: true,
      )
    ];
  }

  @override
  Future<void> createProduct(Product product) async {}

  @override
  Future<void> updateProduct(Product product) async {}

  @override
  Future<void> deleteProduct(String id) async {}
}

void main() {
  test('CachedProductRepository stores remote data into local cache', () async {
    final storage = <String, ProductDto>{};
    final repo = CachedProductRepository(
      remote: FakeRemote([
        const ProductDto(id: '1', name: 'Remote', description: null, imageUrl: null, price: 10, available: true),
      ]),
      local: FakeLocal(storage),
    );

    final products = await repo.fetchProducts();
    expect(products.first.name, 'Remote');
    expect(storage.containsKey('1'), true);
  });

  test('CachedProductRepository falls back to local cache when remote fails', () async {
    final storage = <String, ProductDto>{
      '1': const ProductDto(id: '1', name: 'Cached', description: null, imageUrl: null, price: 5, available: true),
    };
    final repo = CachedProductRepository(
      remote: FakeRemote(const [], shouldThrow: true),
      local: FakeLocal(storage),
      fallback: FakeFallback(),
    );

    final products = await repo.fetchProducts();
    expect(products.first.name, 'Cached');
  });

  test('CachedProductRepository uses fallback when everything fails', () async {
    final repo = CachedProductRepository(
      remote: FakeRemote(const [], shouldThrow: true),
      local: FakeLocal({}),
      fallback: FakeFallback(),
    );

    final products = await repo.fetchProducts();
    expect(products.first.id, 'fallback');
  });
}

