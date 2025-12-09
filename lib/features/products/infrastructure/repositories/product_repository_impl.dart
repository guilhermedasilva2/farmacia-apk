import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:meu_app_inicial/features/products/infrastructure/dtos/product_dto.dart';
import 'package:meu_app_inicial/services/page_cursor.dart';
import 'package:meu_app_inicial/services/remote_page.dart';
import 'package:meu_app_inicial/features/products/infrastructure/mappers/product_mapper.dart';
import 'package:meu_app_inicial/features/products/domain/entities/product.dart';
import 'package:meu_app_inicial/features/products/domain/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface para acesso remoto aos dados de produtos (ex: Supabase).
///
/// Esta interface abstrai a fonte de dados remota, permitindo trocar
/// a implementação (Supabase, REST API, GraphQL) sem afetar o repositório.
abstract class ProductRemoteDataSource {
  /// Busca todos os produtos, opcionalmente filtrados por categoria e data.
  /// 
  /// [since] permite sincronização incremental: busca apenas produtos
  /// modificados após esta data (campo updated_at no servidor).
  Future<List<ProductDto>> fetchAll({String? categoryId, DateTime? since});
  
  /// Cria um novo produto no servidor.
  Future<void> create(ProductDto product);
  
  /// Atualiza um produto existente no servidor.
  Future<void> update(ProductDto product);
  
  /// Remove um produto do servidor.
  Future<void> delete(String id);
  
  /// Envia produtos em lote para o servidor (upsert).
  /// Usado para sincronização push (local → remoto).
  /// Retorna o número de produtos enviados com sucesso.
  Future<int> upsertProducts(List<ProductDto> dtos);
  
  /// Busca uma página de produtos com suporte a paginação.
  ///
  /// [cursor] indica a posição inicial (null = primeira página).
  /// [limit] define quantos itens buscar por página (padrão: 100).
  /// [categoryId] filtra por categoria (opcional).
  /// [since] filtra por data de atualização (opcional).
  ///
  /// Retorna um `RemotePage` contendo os itens e o cursor para a próxima página.
  Future<RemotePage<ProductDto>> fetchPage({
    PageCursor? cursor,
    int limit = 100,
    String? categoryId,
    DateTime? since,
  });
}

/// Interface para acesso local aos dados de produtos (ex: SharedPreferences).
///
/// Esta interface abstrai o cache local, permitindo trocar a implementação
/// (SharedPreferences, SQLite, Hive) sem afetar o repositório.
abstract class ProductLocalDataSource {
  /// Lê todos os produtos do cache local.
  Future<List<ProductDto>> readAll();
  
  /// Insere ou atualiza produtos no cache local (upsert em lote).
  Future<void> upsertAll(List<ProductDto> dtos);
  
  /// Retorna o timestamp da última sincronização bem-sucedida.
  Future<DateTime?> getLastSync();
  
  /// Atualiza o timestamp da última sincronização.
  Future<void> setLastSync(DateTime time);
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
    // Mantendo comportamento híbrido para compatibilidade, mas idealmente usaria loadFromCache + sync
    try {
      final remoteDtos = await _remote.fetchAll(categoryId: categoryId);
      await _local.upsertAll(remoteDtos);
      return ProductMapper.fromDtoList(remoteDtos);
    } catch (_) {
      try {
        final cachedDtos = await _local.readAll();
        var filteredDtos = cachedDtos;
        if (categoryId != null) {
          filteredDtos = cachedDtos.where((dto) => dto.categoryId == categoryId).toList();
        }
        if (filteredDtos.isNotEmpty) {
          return ProductMapper.fromDtoList(filteredDtos);
        }
      } catch (e) {
        debugPrint('Error reading from local cache: $e');
      }
      return _fallback.fetchProducts(categoryId: categoryId);
    }
  }

  @override
  Future<List<Product>> loadFromCache() async {
    try {
      final cachedDtos = await _local.readAll();
      return ProductMapper.fromDtoList(cachedDtos);
    } catch (e) {
      debugPrint('Error reading from local cache: $e');
      return [];
    }
  }

  @override
  Future<int> syncFromServer() async {
    int totalSynced = 0;
    
    try {
      // FASE 1: PUSH - Enviar cache local para remoto (best-effort)
      int pushed = 0;
      try {
        final localDtos = await _local.readAll();
        if (localDtos.isNotEmpty) {
          if (kDebugMode) {
            print('CachedProductRepository: Pushing ${localDtos.length} items to remote...');
          }
          pushed = await _remote.upsertProducts(localDtos);
          if (kDebugMode) {
            print('CachedProductRepository: Pushed $pushed items to remote');
          }
          totalSynced += pushed;
        }
      } catch (e) {
        if (kDebugMode) {
          print('CachedProductRepository: Push failed (continuing with pull): $e');
        }
        // Não bloqueia o pull se push falhar
      }
      
      // FASE 2: PULL - Buscar mudanças remotas
      final lastSync = await _local.getLastSync();
      if (kDebugMode) {
        print('CachedProductRepository: Pulling from server since $lastSync');
      }
      
      final remoteDtos = await _remote.fetchAll(since: lastSync);
      if (remoteDtos.isEmpty) {
         if (kDebugMode) print('CachedProductRepository: No new data from server.');
         return totalSynced; // Retorna apenas o que foi pushed
      }

      await _local.upsertAll(remoteDtos);
      
      // Update last sync to now
      await _local.setLastSync(DateTime.now());
      
      if (kDebugMode) {
        print('CachedProductRepository: Pulled ${remoteDtos.length} items from server.');
      }
      
      totalSynced += remoteDtos.length;
      return totalSynced;
    } catch (e) {
      if (kDebugMode) {
        print('CachedProductRepository: Sync failed: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> createProduct(Product product) async {
    await _remote.create(ProductMapper.toDto(product));
    // Invalidate or update cache if needed, for now just refetch next time
    // Or we could append to local cache optimistically
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _remote.update(ProductMapper.toDto(product));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _remote.delete(id);
  }
}

class SupabaseProductRemoteDataSource implements ProductRemoteDataSource {
  SupabaseProductRemoteDataSource({SupabaseClient? client, this.tableName = 'products'})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient? _client;
  final String tableName;

  @override
  Future<List<ProductDto>> fetchAll({String? categoryId, DateTime? since}) async {
    if (_client == null) throw Exception('No Supabase client');
    
    var query = _client.from(tableName).select();
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
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
  
  @override
  Future<int> upsertProducts(List<ProductDto> dtos) async {
    if (_client == null) throw Exception('No Supabase client');
    if (dtos.isEmpty) return 0;
    
    try {
      final maps = dtos.map((dto) {
        final map = dto.toMap();
        // Remove id vazio para permitir que o servidor gere
        if (map['id'] == null || map['id'].toString().isEmpty) {
          map.remove('id');
        }
        // Garantir quantity
        if (map['quantity'] == null) {
          map['quantity'] = 0;
        }
        return map;
      }).toList();
      
      if (kDebugMode) {
        print('SupabaseProductRemoteDataSource.upsertProducts: sending ${dtos.length} items');
      }
      
      await _client.from(tableName).upsert(maps);
      
      if (kDebugMode) {
        print('SupabaseProductRemoteDataSource.upsertProducts: success');
      }
      
      return dtos.length;
    } catch (e) {
      if (kDebugMode) {
        print('SupabaseProductRemoteDataSource.upsertProducts: error: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<RemotePage<ProductDto>> fetchPage({
    PageCursor? cursor,
    int limit = 100,
    String? categoryId,
    DateTime? since,
  }) async {
    if (_client == null) throw Exception('No Supabase client');
    
    try {
      final offset = cursor?.toOffset() ?? 0;
      
      dynamic query = _client.from(tableName).select();
      
      // Filtros
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }
      
      // Ordenação e paginação
      query = query.order('updated_at', ascending: false);
      query = query.range(offset, offset + limit - 1);
      
      final List<dynamic> rows = await query;
      final dtos = rows.map((e) => ProductDto.fromMap(e as Map<String, dynamic>)).toList();
      
      // Calcular próximo cursor
      PageCursor? nextCursor;
      if (dtos.length == limit) {
        // Se retornou exatamente o limite, pode haver mais páginas
        nextCursor = PageCursor.fromOffset(offset + limit);
      }
      
      if (kDebugMode) {
        print('SupabaseProductRemoteDataSource.fetchPage: fetched ${dtos.length} items (offset: $offset, hasMore: ${nextCursor != null})');
      }
      
      return RemotePage(
        items: dtos,
        next: nextCursor,
      );
    } catch (e) {
      if (kDebugMode) {
        print('SupabaseProductRemoteDataSource.fetchPage: error: $e');
      }
      return RemotePage.empty();
    }
  }
}

class SharedPreferencesProductLocalDataSource implements ProductLocalDataSource {
  SharedPreferencesProductLocalDataSource({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _cacheKey = 'products_cache_v1';
  static const String _lastSyncKey = 'products_last_sync_v1';
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

  @override
  Future<DateTime?> getLastSync() async {
    final val = _prefs.getString(_lastSyncKey);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  @override
  Future<void> setLastSync(DateTime time) async {
    await _prefs.setString(_lastSyncKey, time.toIso8601String());
  }
}

class MockProductRepository implements ProductRepository {
  const MockProductRepository();

  @override
  Future<List<Product>> loadFromCache() => fetchProducts();

  @override
  Future<int> syncFromServer() async => 0;

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
  Future<void> createProduct(Product product) async {}

  @override
  Future<void> updateProduct(Product product) async {}

  @override
  Future<void> deleteProduct(String id) async {}
}

/*
═══════════════════════════════════════════════════════════════════════════════
EXEMPLO DE USO E CHECKLIST DE ERROS COMUNS
═══════════════════════════════════════════════════════════════════════════════

## Exemplo de uso básico:

```dart
// 1. Criar instâncias dos datasources
final remoteDataSource = SupabaseProductRemoteDataSource(
  client: Supabase.instance.client,
);
final localDataSource = await SharedPreferencesProductLocalDataSource.create();

// 2. Criar repositório
final repository = CachedProductRepository(
  remote: remoteDataSource,
  local: localDataSource,
);

// 3. Carregar dados do cache (render inicial rápido)
final cachedProducts = await repository.loadFromCache();
setState(() => _products = cachedProducts);

// 4. Sincronizar com servidor (pull-to-refresh ou inicialização)
final updatedCount = await repository.syncFromServer();
if (updatedCount > 0) {
  final freshProducts = await repository.loadFromCache();
  setState(() => _products = freshProducts);
}
```

## Checklist de erros comuns e como evitar:

### ❌ Erro: "Dados não aparecem após sync"
**Causa:** DTO/Mapper não converte corretamente os dados do Supabase
**Solução:**
- Adicione prints no `syncFromServer()` para ver quantos itens foram baixados
- Verifique se `ProductDto.fromMap()` aceita múltiplos formatos (id como int/string)
- Confirme que o campo `updated_at` existe na tabela Supabase

### ❌ Erro: "setState() called after dispose()"
**Causa:** Widget desmontado antes do async completar
**Solução:**
```dart
final products = await repository.syncFromServer();
if (!mounted) return; // ← Sempre verifique antes de setState
setState(() => _products = products);
```

### ❌ Erro: "Supabase RLS policy violation"
**Causa:** Políticas de Row Level Security bloqueando acesso
**Solução:**
- Verifique se a tabela `products` tem política `SELECT` para `anon` role
- No Supabase Dashboard: Authentication > Policies
- Política exemplo: `CREATE POLICY "Allow public read" ON products FOR SELECT USING (true);`

### ❌ Erro: "Conversão de tipos falha (id, datas)"
**Causa:** Backend retorna tipos diferentes do esperado
**Solução:**
- Use `DateTime.tryParse()` ao invés de `DateTime.parse()`
- Aceite `id` como `int` ou `String`: `(map['id'] ?? '').toString()`
- Exemplo robusto:
```dart
factory ProductDto.fromMap(Map<String, dynamic> map) {
  return ProductDto(
    id: (map['id'] ?? '').toString(),
    updatedAt: map['updated_at'] != null 
      ? DateTime.tryParse(map['updated_at'].toString()) 
      : null,
  );
}
```

### ❌ Erro: "Cache não atualiza na UI"
**Causa:** Não recarrega do cache após sync
**Solução:**
```dart
await repository.syncFromServer(); // ← Atualiza cache
final fresh = await repository.loadFromCache(); // ← Recarrega
setState(() => _products = fresh);
```

## Logs de debug esperados (kDebugMode):

Ao rodar o app em modo debug, você deve ver logs como:
```
CachedProductRepository: Syncing from server since 2025-12-03T12:00:00.000Z
CachedProductRepository: Synced 5 items.
```

Se não aparecer, verifique:
1. `kDebugMode` está importado de `package:flutter/foundation.dart`
2. App está rodando em modo debug (não release)

## Referências úteis:

Para problemas específicos, consulte:
- Documentação Supabase: https://supabase.com/docs
- Flutter Clean Architecture: https://resocoder.com/flutter-clean-architecture/
- Repository Pattern: https://martinfowler.com/eaaCatalog/repository.html

═══════════════════════════════════════════════════════════════════════════════
*/
