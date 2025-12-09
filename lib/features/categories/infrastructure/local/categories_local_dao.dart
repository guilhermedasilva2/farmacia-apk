import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meu_app_inicial/features/categories/infrastructure/dtos/category_dto.dart';

/// DAO local para categorias usando SharedPreferences como cache
class CategoriesLocalDao {
  static const String _key = 'categories_cache';
  static const String _timestampKey = 'categories_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 2);

  final SharedPreferences _prefs;

  CategoriesLocalDao(this._prefs);

  /// Factory para criar instância
  static Future<CategoriesLocalDao> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CategoriesLocalDao(prefs);
  }

  /// Lista todas as categorias do cache
  Future<List<CategoryDto>> listAll() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null) return [];

      // Verificar se o cache expirou
      if (_isCacheExpired()) {
        await clear();
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => CategoryDto.fromJson(json)).toList();
    } catch (e) {
      // Em caso de erro, retornar lista vazia
      return [];
    }
  }

  /// Salva ou atualiza uma categoria
  Future<void> upsert(CategoryDto dto) async {
    final categories = await listAll();
    final index = categories.indexWhere((c) => c.id == dto.id);
    
    if (index >= 0) {
      categories[index] = dto;
    } else {
      categories.add(dto);
    }
    
    await upsertAll(categories);
  }

  /// Salva ou atualiza múltiplas categorias
  Future<void> upsertAll(List<CategoryDto> dtos) async {
    try {
      final jsonList = dtos.map((dto) => dto.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await _prefs.setString(_key, jsonString);
      await _prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silenciar erro de persistência
    }
  }

  /// Remove uma categoria pelo ID
  Future<void> remove(String id) async {
    final categories = await listAll();
    categories.removeWhere((c) => c.id == id);
    await upsertAll(categories);
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
