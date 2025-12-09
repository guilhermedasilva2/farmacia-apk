import 'package:meu_app_inicial/features/categories/domain/entities/category.dart';

/// Interface de repositório para gerenciamento de categorias.
///
/// Define as operações de CRUD para categorias sem depender de
/// implementações específicas (Supabase, REST API, etc.).
abstract class CategoryRepository {
  /// Busca todas as categorias ordenadas por nome.
  Future<List<Category>> getAllCategories();
  
  /// Cria uma nova categoria.
  /// Retorna o ID da categoria criada.
  Future<String> createCategory(String name, String slug);
  
  /// Atualiza uma categoria existente.
  Future<void> updateCategory(String id, String name, String slug);
  
  /// Deleta uma categoria e move seus produtos para "Outros Produtos".
  Future<void> deleteCategory(String id);
}
