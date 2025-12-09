import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meu_app_inicial/features/products/infrastructure/dtos/product_dto.dart';

/// DAO local para produtos usando SharedPreferences como cache
class ProductsLocalDao {
  static const String _key = 'products_cache';
  static const String _timestampKey = 'products_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  final SharedPreferences _prefs;

  ProductsLocalDao(this._prefs);

  /// Factory para criar instância
  static Future<ProductsLocalDao> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProductsLocalDao(prefs);
  }

  /// Lista todos os produtos do cache
  Future<List<ProductDto>> listAll() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null) return [];

      // Verificar se o cache expirou
      if (_isCacheExpired()) {
        await clear();
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductDto.fromJson(json)).toList();
    } catch (e) {
      // Em caso de erro, retornar lista vazia
      return [];
    }
  }

  /// Salva ou atualiza um produto
  Future<void> upsert(ProductDto dto) async {
    final products = await listAll();
    final index = products.indexWhere((p) => p.id == dto.id);
    
    if (index >= 0) {
      products[index] = dto;
    } else {
      products.add(dto);
    }
    
    await upsertAll(products);
  }

  /// Salva ou atualiza múltiplos produtos
  Future<void> upsertAll(List<ProductDto> dtos) async {
    try {
      final jsonList = dtos.map((dto) => dto.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await _prefs.setString(_key, jsonString);
      await _prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silenciar erro de persistência
    }
  }

  /// Remove um produto pelo ID
  Future<void> remove(String id) async {
    final products = await listAll();
    products.removeWhere((p) => p.id == id);
    await upsertAll(products);
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    await _prefs.remove(_key);
    await _prefs.remove(_timestampKey);
  }

  /// Verifica se o cache expirou
  bool _isCacheExpired() {
    final timestamp = _prefs.getInt(_timestampKey);
    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    return now.difference(cacheTime) > _cacheDuration;
  }

  /// Verifica se há cache válido
  Future<bool> hasValidCache() async {
    final jsonString = _prefs.getString(_key);
    return jsonString != null && !_isCacheExpired();
  }
}
