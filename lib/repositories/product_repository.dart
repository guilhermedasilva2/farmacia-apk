import 'dart:convert';

import 'package:meu_app_inicial/dto/product_dto.dart';
import 'package:meu_app_inicial/mappers/product_mapper.dart';
import 'package:meu_app_inicial/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
}

abstract class ProductRemoteDataSource {
  Future<List<ProductDto>> fetchAll();
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
  Future<List<Product>> fetchProducts() async {
    try {
      final remoteDtos = await _remote.fetchAll();
      await _local.upsertAll(remoteDtos);
      return ProductMapper.fromDtoList(remoteDtos);
    } catch (_) {
      try {
        final cachedDtos = await _local.readAll();
        if (cachedDtos.isNotEmpty) {
          return ProductMapper.fromDtoList(cachedDtos);
        }
      } catch (_) {
        // ignore cache failures
      }
      return _fallback.fetchProducts();
    }
  }
}

class SupabaseProductRemoteDataSource implements ProductRemoteDataSource {
  SupabaseProductRemoteDataSource({required SupabaseClient? client, this.tableName = 'products'})
      : _client = client;

  final SupabaseClient? _client;
  final String tableName;

  @override
  Future<List<ProductDto>> fetchAll() async {
    if (_client == null) throw Exception('No Supabase client');
    final List<dynamic> rows = await _client!.from(tableName).select();
    return rows.map((e) => ProductDto.fromMap(e as Map<String, dynamic>)).toList();
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
  Future<List<Product>> fetchProducts() async {
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
}
