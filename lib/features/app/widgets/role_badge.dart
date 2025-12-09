import 'package:flutter/material.dart';
import 'package:meu_app_inicial/features/auth/domain/entities/user_role.dart';

/// Widget para exibir badge do role do usuário
class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool showLabel;

  const RoleBadge({
    super.key,
    required this.role,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(role);

    return Tooltip(
      message: config.tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.1),
          border: Border.all(color: config.color, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              size: 16,
              color: config.color,
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                role.displayName,
                style: TextStyle(
                  color: config.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _RoleConfig _getRoleConfig(UserRole role) {
    switch (role) {
      case UserRole.visitor:
        return _RoleConfig(
          color: Colors.grey,
          icon: Icons.visibility_outlined,
          tooltip: 'Visitante - Pode visualizar produtos',
        );
      case UserRole.user:
        return _RoleConfig(
          color: Colors.blue,
          icon: Icons.person,
          tooltip: 'Usuário - Pode comprar produtos',
        );
      case UserRole.admin:
        return _RoleConfig(
          color: Colors.orange,
          icon: Icons.admin_panel_settings,
          tooltip: 'Administrador - Acesso total',
        );
    }
  }
}

class _RoleConfig {
  final Color color;
  final IconData icon;
  final String tooltip;

  _RoleConfig({
    required this.color,
    required this.icon,
    required this.tooltip,
  });
}
