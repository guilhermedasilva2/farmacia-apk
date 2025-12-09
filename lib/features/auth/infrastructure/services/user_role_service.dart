import 'package:flutter/foundation.dart';
import 'package:meu_app_inicial/features/auth/domain/entities/user_role.dart';
import 'package:meu_app_inicial/features/profile/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar permissões baseadas em roles de usuário
class UserRoleService {
  UserRoleService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Obtém o perfil do usuário atual
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    debugPrint('DEBUG UserRoleService: Current user ID: ${user?.id}');
    debugPrint('DEBUG UserRoleService: Current user email: ${user?.email}');
    if (user == null) {
      return UserProfile.visitor();
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      debugPrint('DEBUG UserRoleService: Response from Supabase: $response');
      final profile = UserProfile.fromJson(response);
      debugPrint('DEBUG UserRoleService: Parsed profile role: ${profile.role}');
      
      // Cache the role
      await _cacheUserRole(profile.role);
      
      return profile;
    } catch (e) {
      debugPrint('DEBUG UserRoleService: Error fetching profile: $e');
      
      // Tentar recuperar do cache
      final cachedRole = await _getCachedUserRole();
      debugPrint('DEBUG UserRoleService: Using cached role: $cachedRole');

      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] ?? 'Usuário',
        role: cachedRole, // Usa o cache ou UserRole.user se não houver cache
        createdAt: DateTime.parse(user.createdAt),
      );
    }
  }

  Future<void> _cacheUserRole(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role_cache', role.toString());
    } catch (e) {
      debugPrint('DEBUG UserRoleService: Error caching role: $e');
    }
  }

  Future<UserRole> _getCachedUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleStr = prefs.getString('user_role_cache');
      if (roleStr != null) {
        // UserRole.toString() retorna "UserRole.admin", precisamos parsear ou ajustar
        // O método fromString espera "admin", "user", etc.
        // Vamos salvar apenas a string simples no _cacheUserRole
        return UserRole.fromString(roleStr);
      }
    } catch (e) {
      debugPrint('DEBUG UserRoleService: Error reading cached role: $e');
    }
    return UserRole.user; // Default fallback
  }

  /// Obtém o role do usuário atual
  Future<UserRole> getCurrentUserRole() async {
    final profile = await getCurrentUserProfile();
    return profile?.role ?? UserRole.visitor;
  }

  /// Verifica se o usuário atual pode comprar
  Future<bool> canPurchase() async {
    final role = await getCurrentUserRole();
    return role.canPurchase;
  }

  /// Verifica se o usuário atual pode gerenciar produtos
  Future<bool> canManageProducts() async {
    final role = await getCurrentUserRole();
    return role.canManageProducts;
  }

  /// Verifica se o usuário atual pode ver relatórios
  Future<bool> canViewReports() async {
    final role = await getCurrentUserRole();
    return role.canViewReports;
  }

  /// Verifica se o usuário está autenticado
  Future<bool> isAuthenticated() async {
    final role = await getCurrentUserRole();
    return role.isAuthenticated;
  }

  /// Stream que emite o perfil do usuário quando há mudanças na autenticação
  Stream<UserProfile> get userProfileStream {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) {
        return UserProfile.visitor();
      }

      try {
        final response = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        return UserProfile.fromJson(response);
      } catch (e) {
        return UserProfile(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['display_name'] ?? 'Usuário',
          role: UserRole.user,
          createdAt: DateTime.parse(user.createdAt),
        );
      }
    });
  }
}
