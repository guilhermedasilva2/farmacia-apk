import 'package:meu_app_inicial/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositório para gerenciar dados de usuários
class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Busca o perfil de um usuário por ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Atualiza o perfil de um usuário
  Future<void> updateUserProfile(UserProfile profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  /// Lista todos os usuários (apenas para admin)
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Cria um novo perfil de usuário
  Future<void> createUserProfile(UserProfile profile) async {
    await _client.from('profiles').insert(profile.toJson());
  }

  /// Deleta o perfil de um usuário
  Future<void> deleteUserProfile(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }
}
