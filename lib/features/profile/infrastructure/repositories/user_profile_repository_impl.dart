import 'package:meu_app_inicial/features/profile/domain/entities/user_profile.dart';
import 'package:meu_app_inicial/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositório para gerenciar dados de usuários
class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
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

  @override
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
  
  @override
  Future<void> updateAvatar(String userId, String avatarPath) async {
    await _client.from('profiles').update({
      'avatar_url': avatarPath,
    }).eq('id', userId);
  }
  
  @override
  Future<void> updateUserRole(String userId, String role) async {
    await _client.from('profiles').update({
      'role': role,
    }).eq('id', userId);
  }
}
