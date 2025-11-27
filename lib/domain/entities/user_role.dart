enum UserRole {
  visitor,
  user,
  admin;

  /// Converte string para UserRole
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'visitor':
        return UserRole.visitor;
      case 'user':
        return UserRole.user;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.visitor;
    }
  }

  /// Converte UserRole para string
  @override
  String toString() {
    switch (this) {
      case UserRole.visitor:
        return 'visitor';
      case UserRole.user:
        return 'user';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// Retorna nome amigável do role
  String get displayName {
    switch (this) {
      case UserRole.visitor:
        return 'Visitante';
      case UserRole.user:
        return 'Usuário';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  /// Verifica se o usuário pode comprar
  bool get canPurchase => this == UserRole.user || this == UserRole.admin;

  /// Verifica se o usuário pode gerenciar produtos
  bool get canManageProducts => this == UserRole.admin;

  /// Verifica se o usuário pode ver relatórios
  bool get canViewReports => this == UserRole.admin;

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => this != UserRole.visitor;
}
