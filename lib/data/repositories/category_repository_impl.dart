import 'package:flutter/foundation.dart' hide Category;
import 'package:meu_app_inicial/domain/entities/category.dart';
import 'package:meu_app_inicial/domain/repositories/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositório para gerenciar categorias
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Busca todas as categorias
  @override
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('name', ascending: true);

      return (response as List).map((data) {
        return Category(
          id: data['id'] as String,
          name: data['name'] as String,
          slug: data['slug'] as String,
        );
      }).toList().cast<Category>();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (e.toString().contains('AuthRetryableFetchException') || e.toString().contains('refresh_token_hmac_key')) {
         debugPrint('Critical Auth Error: Token might be invalid. Consider signing out.');
      }
      return [];
    }
  }

  @override
  Future<String> createCategory(String name, String slug) async {
    final response = await _client.from('categories').insert({
      'name': name,
      'slug': slug,
    }).select().single();

    return response['id'] as String;
  }

  /// Atualiza uma categoria
  @override
  Future<void> updateCategory(String id, String name, String slug) async {
    await _client.from('categories').update({
      'name': name,
      'slug': slug,
    }).eq('id', id);
  }

  /// Deleta uma categoria e move seus produtos para "Outros Produtos"
  @override
  Future<void> deleteCategory(String id) async {
    try {
      // Primeiro, atualiza todos os produtos desta categoria para null (Outros Produtos)
      await _client
          .from('products')
          .update({'category_id': null})
          .eq('category_id', id);
      
      // Depois, deleta a categoria
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      debugPrint('DEBUG: Error deleting category: $e');
      rethrow;
    }
  }
}
