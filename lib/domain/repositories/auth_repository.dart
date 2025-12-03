import 'package:meu_app_inicial/domain/entities/user.dart';

/// Interface de repositório para autenticação de usuários.
///
/// Define as operações de autenticação sem depender de implementações específicas.
/// Segue o princípio de Dependency Inversion da Clean Architecture.
abstract class AuthRepository {
  /// Autentica um usuário com email e senha.
  ///
  /// Retorna o usuário autenticado ou null se as credenciais forem inválidas.
  /// Lança exceção em caso de erro de rede ou servidor.
  Future<User?> signIn(String email, String password);

  /// Registra um novo usuário com email e senha.
  ///
  /// Retorna o usuário criado ou null se o registro falhar.
  /// Lança exceção se o email já estiver em uso.
  Future<User?> signUp(String email, String password);

  /// Desloga o usuário atual.
  Future<void> signOut();

  /// Stream que emite o usuário atual sempre que o estado de autenticação muda.
  ///
  /// Emite null quando o usuário não está autenticado.
  Stream<User?> get authStateChanges;

  /// Retorna o usuário atualmente autenticado, se houver.
  Future<User?> getCurrentUser();
}
