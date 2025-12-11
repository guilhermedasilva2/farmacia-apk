import 'package:flutter/material.dart';
import 'package:meu_app_inicial/features/auth/domain/entities/user_role.dart';
import 'package:meu_app_inicial/features/auth/infrastructure/services/user_role_service.dart';
import 'package:meu_app_inicial/features/profile/domain/entities/user_profile.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserRoleService _roleService = UserRoleService();
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _roleService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRole(UserProfile user, UserRole newRole) async {
    if (user.role == newRole) return;

    try {
      await _roleService.updateUserRole(user.id, newRole);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Função de ${user.displayName} atualizada para ${newRole.name}')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar função: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Funcionários'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        DropdownButton<UserRole>(
                          value: user.role,
                          underline: Container(),
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                _getRoleName(role),
                                style: TextStyle(
                                  color: _getRoleColor(role),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newRole) async {
                            if (newRole != null && newRole != user.role) {
                              // Mostrar confirmação
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmar Alteração'),
                                  content: Text(
                                    'Deseja realmente alterar a função de ${user.displayName} de ${_getRoleName(user.role)} para ${_getRoleName(newRole)}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _getRoleColor(newRole),
                                      ),
                                      child: const Text('Confirmar'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                _updateRole(user, newRole);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Admin';
      case UserRole.employee: return 'Funcionário'; // Assuming employee exists or mapping 'user' to func?
      case UserRole.user: return 'Cliente';
      case UserRole.visitor: return 'Visitante';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return Colors.red;
      case UserRole.employee: return Colors.blue; 
      case UserRole.user: return Colors.green;
      default: return Colors.grey;
    }
  }
}
