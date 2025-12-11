enum UserRole {
  visitor,
  user,
  admin,
  employee;

  /// Converte string para UserRole
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'visitor':
        return UserRole.visitor;
      case 'user':
        return UserRole.user;
      case 'admin':
        return UserRole.admin;
      case 'employee':
      case 'funcionario': // Handle Portuguese variants if needed
        return UserRole.employee;
      default:
        return UserRole.visitor;
    }
  }

  /// Converte UserRole para string (para banco)
  String toShortString() {
    switch (this) {
      case UserRole.visitor:
        return 'visitor';
      case UserRole.user:
        return 'user';
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
    }
  }

  @override
  String toString() => toShortString();

  /// Retorna nome amigável do role
  String get displayName {
    switch (this) {
      case UserRole.visitor:
        return 'Visitante';
      case UserRole.user:
        return 'Cliente';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.employee:
        return 'Funcionário';
    }
  }

  /// Verifica se o usuário pode comprar
  bool get canPurchase => this == UserRole.user || this == UserRole.admin || this == UserRole.employee;

  /// Verifica se o usuário pode gerenciar produtos (Admin ou Funcionário)
  bool get canManageProducts => this == UserRole.admin || this == UserRole.employee;

  /// Verifica se o usuário pode gerenciar categorias (Admin ou Funcionário)
  bool get canManageCategories => this == UserRole.admin || this == UserRole.employee;

  /// Verifica se o usuário pode gerenciar estoque (Admin ou Funcionário)
  bool get canManageStock => this == UserRole.admin || this == UserRole.employee;

  /// Verifica se o usuário pode visualizar pedidos (Admin ou Funcionário)
  bool get canViewOrders => this == UserRole.admin || this == UserRole.employee;

  /// Verifica se o usuário pode atualizar status de pedidos (Apenas Admin)
  bool get canUpdateOrderStatus => this == UserRole.admin;

  /// Verifica se o usuário pode gerenciar usuários (Apenas Admin)
  bool get canManageUsers => this == UserRole.admin;

  /// Verifica se o usuário pode ver relatórios (Apenas Admin)
  bool get canViewReports => this == UserRole.admin;

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => this != UserRole.visitor;
}
