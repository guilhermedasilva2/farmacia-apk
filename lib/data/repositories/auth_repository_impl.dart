import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:meu_app_inicial/domain/entities/user.dart';
import 'package:meu_app_inicial/domain/repositories/auth_repository.dart';

/// Implementação do AuthRepository usando Supabase como backend.
class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client;
  
  SupabaseAuthRepository({supabase.SupabaseClient? client})
      : _client = client ?? supabase.Supabase.instance.client;

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response.user != null ? _mapSupabaseUser(response.user!) : null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User?> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      return response.user != null ? _mapSupabaseUser(response.user!) : null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Stream<User?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final supabaseUser = event.session?.user;
      return supabaseUser != null ? _mapSupabaseUser(supabaseUser) : null;
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    final supabaseUser = _client.auth.currentUser;
    return supabaseUser != null ? _mapSupabaseUser(supabaseUser) : null;
  }

  /// Converte um usuário do Supabase para a entidade de domínio.
  User _mapSupabaseUser(supabase.User supabaseUser) {
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      name: supabaseUser.userMetadata?['name'] as String?,
      avatarUrl: supabaseUser.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.tryParse(supabaseUser.createdAt),
    );
  }
}
