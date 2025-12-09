import 'page_cursor.dart';

/// Representa uma página de dados retornada por uma fonte remota.
///
/// Esta classe genérica encapsula:
/// - **items:** Lista de itens da página atual
/// - **next:** Cursor para a próxima página (null se não houver mais)
/// - **hasMore:** Indica se existem mais páginas disponíveis
///
/// Exemplo de uso:
/// ```dart
/// // Criar uma página com dados
/// final page = RemotePage<ProductDto>(
///   items: [dto1, dto2, dto3],
///   next: PageCursor.fromOffset(100),
/// );
///
/// // Verificar se há mais páginas
/// if (page.hasMore) {
///   final nextPage = await fetchProducts(cursor: page.next);
/// }
///
/// // Página vazia (sem mais dados)
/// final emptyPage = RemotePage<ProductDto>(items: []);
/// ```
class RemotePage<T> {
  /// Lista de itens nesta página.
  final List<T> items;

  /// Cursor para a próxima página.
  /// Null se esta for a última página.
  final PageCursor? next;

  /// Indica se existem mais páginas disponíveis.
  bool get hasMore => next != null;

  /// Cria uma página de dados remotos.
  ///
  /// [items] é obrigatório e contém os dados desta página.
  /// [next] é opcional e indica o cursor para a próxima página.
  const RemotePage({
    required this.items,
    this.next,
  });

  /// Cria uma página vazia (sem dados e sem próxima página).
  factory RemotePage.empty() => RemotePage<T>(items: const []);

  /// Retorna o número de itens nesta página.
  int get length => items.length;

  /// Retorna true se esta página está vazia.
  bool get isEmpty => items.isEmpty;

  /// Retorna true se esta página contém itens.
  bool get isNotEmpty => items.isNotEmpty;

  @override
  String toString() =>
      'RemotePage(items: ${items.length}, hasMore: $hasMore)';
}
