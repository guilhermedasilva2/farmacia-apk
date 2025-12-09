import 'package:meu_app_inicial/features/profile/domain/entities/user_profile.dart';

/// Interface de repositório para gerenciamento de perfis de usuário.
///
/// Define as operações para consultar e atualizar perfis de usuário
/// sem depender de implementações específicas.
abstract class UserProfileRepository {
  /// Busca o perfil de um usuário por ID.
  Future<UserProfile?> getUserProfile(String userId);
  
  /// Atualiza o perfil de um usuário.
  Future<void> updateUserProfile(UserProfile profile);
  
  /// Atualiza o avatar de um usuário.
  Future<void> updateAvatar(String userId, String avatarPath);
  
  /// Atualiza o role de um usuário (apenas para admins).
  Future<void> updateUserRole(String userId, String role);
}
