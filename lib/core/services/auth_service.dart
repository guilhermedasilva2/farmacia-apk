import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app_inicial/domain/entities/user_profile.dart';
import 'package:meu_app_inicial/domain/entities/user_role.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<User?> get authStateChanges => _client.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentUser => _client.auth.currentUser;

  bool get isSessionValid {
    final session = _client.auth.currentSession;
    return session != null && !session.isExpired;
  }

  /// Obtém o perfil completo do usuário atual
  Future<UserProfile?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // Se não encontrar perfil, retorna perfil básico
      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] ?? 'Usuário',
        role: UserRole.user,
        createdAt: DateTime.parse(user.createdAt),
      );
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName ?? 'Usuário',
        },
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro ao cadastrar: $e');
    }
  }

  /// Atualiza o perfil do usuário
  Future<void> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', user.id);
    }
  }

  /// Atualiza o role do usuário (apenas para admins)
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _client.from('profiles').update({
      'role': role.toString(),
    }).eq('id', userId);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

