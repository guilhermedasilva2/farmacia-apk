import 'package:flutter/material.dart';
import 'package:meu_app_inicial/data/models/category_dto.dart';
import 'package:meu_app_inicial/data/repositories/categories_local_dao.dart';
import 'package:meu_app_inicial/domain/repositories/category_repository.dart';
import 'package:meu_app_inicial/data/repositories/category_repository_impl.dart';
import 'package:meu_app_inicial/core/services/user_role_service.dart';
import 'package:meu_app_inicial/domain/entities/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryRepository _repository = CategoryRepositoryImpl();
  CategoriesLocalDao? _localDao;
  Future<List<CategoryDto>>? _future;
  final UserRoleService _roleService = UserRoleService();
  UserRole _currentRole = UserRole.visitor;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _initDaoAndFetch();
  }

  Future<void> _loadUserRole() async {
    final role = await _roleService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _currentRole = role;
      });
    }
  }

  Future<void> _initDaoAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _localDao = CategoriesLocalDao(prefs);
      _refreshList();
    } catch (e) {
      debugPrint('Erro ao inicializar DAO: $e');
      // Fallback se falhar init do DAO
      _refreshList();
    }
  }

  void _refreshList() {
    setState(() {
      _future = _fetchCategories();
    });
  }

  Future<List<CategoryDto>> _fetchCategories() async {
    // Tenta buscar local primeiro
    if (_localDao != null) {
      final local = await _localDao!.listAll();
      if (local.isNotEmpty) {
        // Se tem local, retorna e atualiza em background
        _fetchRemoteAndCache().ignore();
        return local;
      }
    }
    
    // Se não tem local, busca remoto
    return await _fetchRemoteAndCache();
  }

  Future<List<CategoryDto>> _fetchRemoteAndCache() async {
    try {
      final categories = await _repository.getAllCategories();
      final dtos = categories.map((c) => CategoryDto(
        id: c.id,
        name: c.name,
        slug: c.slug,
      )).toList();

      if (_localDao != null) {
        await _localDao!.upsertAll(dtos);
      }
      return dtos;
    } catch (e) {
      debugPrint('Erro ao buscar categorias remotas: $e');
      rethrow;
    }
  }

  Future<void> _handleAdd() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CategoryFormDialog(),
    );

    if (result != null) {
      try {
        final name = result['name']!;
        final slug = result['slug']!;
        
        await _repository.createCategory(name, slug);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoria criada com sucesso!')),
          );
          _refreshList();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleEdit(CategoryDto category) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(
        initialName: category.name,
        initialSlug: category.slug,
      ),
    );

    if (result != null) {
      try {
        final name = result['name']!;
        final slug = result['slug']!;
        
        await _repository.updateCategory(category.id, name, slug);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoria atualizada com sucesso!')),
          );
          _refreshList();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(CategoryDto category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Remover Categoria'),
        content: Text('Deseja remover "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NÃO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SIM'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteCategory(category.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoria removida com sucesso!')),
          );
          _refreshList();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _currentRole.canManageProducts
          ? FloatingActionButton(
              onPressed: _handleAdd,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _refreshList(),
        child: FutureBuilder<List<CategoryDto>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _future != null) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }

            final categories = snapshot.data ?? [];

            if (categories.isEmpty) {
              return const Center(child: Text('Nenhuma categoria encontrada.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  subtitle: category.slug != null ? Text(category.slug!) : null,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.category, color: Colors.white),
                  ),
                  trailing: _currentRole.canManageProducts
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _handleEdit(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _handleDelete(category),
                            ),
                          ],
                        )
                      : null,
                  onLongPress: _currentRole.canManageProducts
                      ? () => _handleEdit(category)
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class CategoryFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialSlug;

  const CategoryFormDialog({super.key, this.initialName, this.initialSlug});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _slugController = TextEditingController(text: widget.initialSlug);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Nova Categoria' : 'Editar Categoria'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(labelText: 'Slug (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'slug': _slugController.text,
              });
            }
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}
