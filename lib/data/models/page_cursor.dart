/// Cursor de paginação para controlar a posição em listas paginadas.
///
/// Suporta dois tipos de cursor:
/// - **Offset numérico:** Para paginação baseada em índice (ex: 0, 100, 200...)
/// - **Token string:** Para paginação baseada em cursor opaco do servidor
///
/// Exemplo de uso:
/// ```dart
/// // Paginação por offset
/// final cursor = PageCursor.fromOffset(100);
/// final offset = cursor.toOffset(); // 100
///
/// // Paginação por token
/// final cursor2 = PageCursor.fromToken('abc123');
/// final token = cursor2.toToken(); // 'abc123'
/// ```
class PageCursor {
  final dynamic _value;

  const PageCursor._(this._value);

  /// Cria um cursor a partir de um offset numérico.
  factory PageCursor.fromOffset(int offset) => PageCursor._(offset);

  /// Cria um cursor a partir de um token string.
  factory PageCursor.fromToken(String token) => PageCursor._(token);

  /// Retorna o valor do cursor (pode ser int ou String).
  dynamic get value => _value;

  /// Converte para offset numérico.
  /// Retorna 0 se o cursor não for numérico.
  int toOffset() {
    if (_value is int) return _value;
    if (_value is String) return int.tryParse(_value) ?? 0;
    return 0;
  }

  /// Converte para token string.
  String toToken() => _value.toString();

  @override
  String toString() => 'PageCursor($_value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageCursor &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}
