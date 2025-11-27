import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/data/mappers/product_mapper.dart';
import 'package:meu_app_inicial/domain/entities/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts({String? categoryId});
  Future<void> createProduct(ProductDto product);
  Future<void> updateProduct(ProductDto product);
  Future<void> deleteProduct(String id);
}

abstract class ProductRemoteDataSource {
  Future<List<ProductDto>> fetchAll({String? categoryId});
  Future<void> create(ProductDto product);
  Future<void> update(ProductDto product);
  Future<void> delete(String id);
}

abstract class ProductLocalDataSource {
  Future<List<ProductDto>> readAll();
  Future<void> upsertAll(List<ProductDto> dtos);
}

class CachedProductRepository implements ProductRepository {
  CachedProductRepository({
    required ProductRemoteDataSource remote,
    required ProductLocalDataSource local,
    ProductRepository? fallback,
  })  : _remote = remote,
        _local = local,
        _fallback = fallback ?? MockProductRepository();

  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;
  final ProductRepository _fallback;

  @override
  Future<List<Product>> fetchProducts({String? categoryId}) async {
    try {
      final remoteDtos = await _remote.fetchAll(categoryId: categoryId);
      await _local.upsertAll(remoteDtos);
      return ProductMapper.fromDtoList(remoteDtos);
    } catch (_) {
      try {
        final cachedDtos = await _local.readAll();
        // Filter cached items if categoryId is provided
        var filteredDtos = cachedDtos;
        if (categoryId != null) {
          filteredDtos = cachedDtos.where((dto) => dto.categoryId == categoryId).toList();
        }
        if (filteredDtos.isNotEmpty) {
          return ProductMapper.fromDtoList(filteredDtos);
        }
      } catch (e) {
        debugPrint('Error reading from local cache: $e');
        // ignore cache failures
      }
      return _fallback.fetchProducts(categoryId: categoryId);
    }
  }

  @override
  Future<void> createProduct(ProductDto product) async {
    await _remote.create(product);
    // Invalidate or update cache if needed, for now just refetch next time
    // Or we could append to local cache optimistically
  }

  @override
  Future<void> updateProduct(ProductDto product) async {
    await _remote.update(product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _remote.delete(id);
  }
}

class SupabaseProductRemoteDataSource implements ProductRemoteDataSource {
  SupabaseProductRemoteDataSource({required SupabaseClient? client, this.tableName = 'products'})
      : _client = client;

  final SupabaseClient? _client;
  final String tableName;

  @override
  Future<List<ProductDto>> fetchAll({String? categoryId}) async {
    if (_client == null) throw Exception('No Supabase client');
    
    var query = _client.from(tableName).select();
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    
    final List<dynamic> rows = await query;
    return rows.map((e) => ProductDto.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> create(ProductDto product) async {
    if (_client == null) throw Exception('No Supabase client');

    // 1. Verificar se já existe produto com o mesmo nome
    final existingResponse = await _client
        .from(tableName)
        .select()
        .ilike('name', product.name)
        .maybeSingle();

    if (existingResponse != null) {
      // Produto já existe, vamos atualizar a quantidade
      final existingProduct = ProductDto.fromMap(existingResponse);
      final currentQty = existingProduct.quantity ?? 0;
      final addQty = product.quantity ?? 0;
      final newQty = currentQty + addQty;



      await _client.from(tableName).update({
        'quantity': newQty,
        // Opcional: atualizar outros campos se desejar, mas o foco é estoque
        'price': product.price, // Atualiza preço também? Pode ser útil
        'available': newQty > 0, // Se tem estoque, está disponível
      }).eq('id', existingProduct.id);
    } else {
      // Produto novo, inserir

      final map = product.toMap();
      if (product.id.isEmpty) {
        map.remove('id');
      }
      // Garantir que quantity tenha valor
      if (map['quantity'] == null) {
        map['quantity'] = 0;
      }
      await _client.from(tableName).insert(map);
    }
  }

  @override
  Future<void> update(ProductDto product) async {
    if (_client == null) throw Exception('No Supabase client');
    await _client.from(tableName).update(product.toMap()).eq('id', product.id);
  }

  @override
  Future<void> delete(String id) async {
    if (_client == null) throw Exception('No Supabase client');
    await _client.from(tableName).delete().eq('id', id);
  }
}

class SharedPreferencesProductLocalDataSource implements ProductLocalDataSource {
  SharedPreferencesProductLocalDataSource({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _cacheKey = 'products_cache_v1';
  final SharedPreferences _prefs;

  static Future<SharedPreferencesProductLocalDataSource> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesProductLocalDataSource(prefs: prefs);
  }

  @override
  Future<List<ProductDto>> readAll() async {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ProductDto.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> upsertAll(List<ProductDto> dtos) async {
    final Map<String, ProductDto> merged = {};
    try {
      final existing = await readAll();
      for (final dto in existing) {
        merged[dto.id] = dto;
      }
    } catch (_) {
      // ignore corrupted cache (auto-heal)
    }
    for (final dto in dtos) {
      merged[dto.id] = dto;
    }
    final payload = merged.values.map((e) => e.toMap()).toList(growable: false);
    final encoded = jsonEncode(payload);
    await _prefs.setString(_cacheKey, encoded);
  }
}

class MockProductRepository implements ProductRepository {
  const MockProductRepository();

  @override
  @override
  Future<List<Product>> fetchProducts({String? categoryId}) async {
    return const [
      Product(
        id: '1',
        name: 'Paracetamol 750mg',
        description: 'Analgésico e antitérmico',
        imageUrl: '',
        price: 12.90,
        available: true,
      ),
      Product(
        id: '2',
        name: 'Vitamina C 1g',
        description: 'Suplemento vitamínico',
        imageUrl: '',
        price: 19.50,
        available: true,
      ),
      Product(
        id: '3',
        name: 'Spray Nasal',
        description: 'Descongestionante nasal',
        imageUrl: '',
        price: 24.99,
        available: false,
      ),
    ];
  }

  @override
  Future<void> createProduct(ProductDto product) async {}

  @override
  Future<void> updateProduct(ProductDto product) async {}

  @override
  Future<void> deleteProduct(String id) async {}
}
