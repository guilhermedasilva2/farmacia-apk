import 'package:meu_app_inicial/features/products/domain/entities/product.dart';


/// Interface de repositório para a entidade Product.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade Product possui métodos de conversão robustos
///   (ex: aceitar id como int ou string, datas como DateTime ou String).
/// - Ao implementar esta interface, adicione prints/logs (usando kDebugMode) nos
///   métodos principais para facilitar o diagnóstico de problemas de cache, conversão e sync.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted"
///   antes de chamar setState, evitando exceções de widget desmontado.
abstract class ProductRepository {
  /// Busca produtos (comportamento híbrido: tenta remoto, fallback para cache).
  /// Para novo código, prefira usar loadFromCache() + syncFromServer().
  Future<List<Product>> fetchProducts({String? categoryId});
  
  /// Carrega produtos do cache local para render inicial rápido.
  /// Use este método para exibir dados imediatamente na UI.
  Future<List<Product>> loadFromCache();
  
  /// Sincronização incremental com o servidor (>= lastSync).
  /// Retorna quantos registros foram atualizados no cache.
  /// Chame este método em pull-to-refresh ou na inicialização do app.
  Future<int> syncFromServer();
  
  /// Cria um novo produto no servidor.
  Future<void> createProduct(Product product);
  
  /// Atualiza um produto existente no servidor.
  Future<void> updateProduct(Product product);
  
  /// Remove um produto do servidor.
  Future<void> deleteProduct(String id);
}
