import 'package:meu_app_inicial/features/auth/domain/entities/user_role.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
  });

  /// Cria um UserProfile a partir de um Map (JSON do Supabase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? 'Usuário',
      role: UserRole.fromString(json['role'] as String? ?? 'visitor'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Converte UserProfile para Map (JSON para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role.toString(),
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  /// Cria uma cópia do UserProfile com campos atualizados
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Cria um perfil de visitante (não autenticado)
  factory UserProfile.visitor() {
    return UserProfile(
      id: '',
      email: '',
      displayName: 'Visitante',
      role: UserRole.visitor,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName, role: ${role.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, displayName, role, createdAt, avatarUrl);
  }
}
