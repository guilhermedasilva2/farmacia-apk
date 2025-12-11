import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meu_app_inicial/features/profile/infrastructure/services/avatar_service.dart';
import 'package:meu_app_inicial/features/auth/infrastructure/services/auth_service.dart';
import 'package:meu_app_inicial/features/auth/infrastructure/services/user_role_service.dart';
import 'package:meu_app_inicial/features/profile/domain/entities/user_profile.dart';
import 'package:meu_app_inicial/features/auth/domain/entities/user_role.dart';
import 'package:meu_app_inicial/features/app/widgets/role_badge.dart';
import 'package:meu_app_inicial/utils/app_routes.dart';
import 'package:meu_app_inicial/main.dart'; // Acesso ao themeController global


class UserDrawer extends StatefulWidget {
  final AuthService? authService;
  final UserRoleService? roleService;

  const UserDrawer({super.key, this.authService, this.roleService});

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  String? _avatarPath;
  AvatarService? _avatarService;
  late final AuthService _authService;
  late final UserRoleService _roleService;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _roleService = widget.roleService ?? UserRoleService();
    _init();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        _init(); // Reload profile on auth change
      }
    });
  }

  Future<void> _init() async {
    final service = await AvatarService.create();
    final saved = await service.getSavedAvatarPath();
    final profile = await _roleService.getCurrentUserProfile();
    debugPrint('DEBUG UserDrawer: Loaded profile: $profile');
    debugPrint('DEBUG UserDrawer: Profile role: ${profile?.role}');
    debugPrint('DEBUG UserDrawer: Is admin? ${profile?.role == UserRole.admin}');
    if (mounted) {
      setState(() {
        _avatarService = service;
        _avatarPath = saved;
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _pick(ImageSource source) async {
    final service = _avatarService ?? await AvatarService.create();
    _avatarService = service;
    
    // 1. Pick and process locally
    final path = await service.pickAndProcessAvatar(source: source);
    if (path == null) return;

    // 2. Optimistic UI update
    if (mounted) {
      setState(() => _avatarPath = path);
    }

    // 3. Upload to server if authenticated
    try {
      final profile = _userProfile;
      if (profile != null && profile.role.isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enviando foto para o servidor...')),
          );
        }
        
        await service.uploadAvatar(path);
        
        // 4. Refresh profile to confirm URL (optional)
        final updated = await _roleService.getCurrentUserProfile();
        if (mounted) {
           setState(() => _userProfile = updated);
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto atualizada com sucesso!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao enviar foto para o servidor.')),
          );
        }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você saiu da sua conta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading durante carregamento inicial
    if (_isLoading) {
      return Drawer(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _userProfile ?? UserProfile.visitor();
    final String displayName = profile.displayName;
    final String initials = (_avatarService?.initialsFromName(displayName)) ?? 'U';
    final bool isAuthenticated = profile.role.isAuthenticated;

    final Widget avatar = Semantics(
      label: 'Foto de perfil do usuário',
      hint: _avatarPath == null ? 'Toque para adicionar foto' : 'Toque para alterar foto',
      button: true,
      child: Tooltip(
        message: _avatarPath == null ? 'Adicionar foto' : 'Alterar foto',
        child: InkWell(
          onTap: isAuthenticated ? () async {
            final source = await showModalBottomSheet<ImageSource>(
              context: context,
              showDragHandle: true,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_camera_outlined),
                      title: const Text('Câmera'),
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Galeria'),
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    ),
                    if (_avatarPath != null)
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Remover foto'),
                        onTap: () async {
                          Navigator.pop(ctx);
                  final service = _avatarService ?? await AvatarService.create();
                  _avatarService = service;
                  await service.clearAvatar();
                          if (mounted) {
                            setState(() => _avatarPath = null);
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
            if (source != null) {
              await _pick(source);
            }
          } : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              // Prioridade: 1. Caminho Local (Edição recente), 2. URL Remota (Banco), 3. Null (Iniciais)
              backgroundImage: _avatarPath != null 
                  ? FileImage(File(_avatarPath!)) 
                  : (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? NetworkImage(profile.avatarUrl!) as ImageProvider
                      : null),
              child: (_avatarPath == null && (profile.avatarUrl == null || profile.avatarUrl!.isEmpty))
                  ? Text(
                      initials,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      avatar,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isAuthenticated)
                              Text(
                                profile.email,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RoleBadge(role: profile.role),
                ],
              ),
            ),
            const Divider(height: 1),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Opções para visitantes
                    if (!isAuthenticated) ...[
                      ListTile(
                        leading: const Icon(Icons.login),
                        title: const Text('Fazer Login'),
                        subtitle: const Text('Entre para comprar produtos'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.auth);
                        },
                      ),
                    ],
                    
                    // Opções para usuários autenticados
                    if (isAuthenticated) ...[
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Alterar nome'),
                        onTap: () async {
                          final controller = TextEditingController(text: displayName);
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Seu nome'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(hintText: 'Digite seu nome'),
                                textInputAction: TextInputAction.done,
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Salvar')),
                              ],
                            ),
                          );
                          if (newName != null && newName.isNotEmpty) {
                            final service = _avatarService ?? await AvatarService.create();
                            _avatarService = service;
                            await service.saveUserDisplayName(newName);
                            await _authService.updateUserProfile(displayName: newName);
                            if (mounted) setState(() {});
                          }
                        },
                      ),
                    ],
                    
                    // Opções para admin
                    if (profile.role == UserRole.admin) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                        title: const Text('Painel Administrativo'),
                        subtitle: const Text('Gerenciar produtos e usuários'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
                        },
                      ),
                    ],
                    
                    // Theme Toggle (Positioned below Admin Panel as requested)
                    ListTile(
                      leading: Icon(
                        themeController.isDark ? Icons.dark_mode : Icons.light_mode,
                        color: themeController.isDark ? Colors.blueAccent : Colors.orange,
                      ),
                      title: const Text('Tema Escuro'),
                      trailing: Switch(
                        value: themeController.isDark,
                        onChanged: (val) {
                          themeController.toggleTheme();
                          setState(() {}); 
                        },
                      ),
                    ),
                    
                    // Opções comuns
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.policy_outlined),
                      title: const Text('Políticas e Termos'),
                      subtitle: const Text('Leia novamente'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/policy', arguments: {'doc': 'privacy'});
                      },
                    ),
                    if (isAuthenticated) ...[
                      ListTile(
                        leading: const Icon(Icons.shopping_bag_outlined),
                        title: const Text('Meus Pedidos (Histórico)'),
                        subtitle: const Text('Acompanhe suas compras'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.orders);
                        },
                      ),
                    ],
                    ListTile(
                      leading: const Icon(Icons.medication_outlined),
                      title: const Text('Lembretes de medicação'),
                      subtitle: const Text('Gerencie lembretes rapidamente'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AppRoutes.reminders);
                      },
                    ),


                    
                    // Admin stock management
                    if (profile.role.canManageProducts) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
                        title: const Text('Gerenciar Estoque'),
                        subtitle: const Text('Controle de produtos'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.adminProducts);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.shopping_cart_outlined, color: Colors.orange),
                        title: const Text('Gerenciar Pedidos'),
                        subtitle: const Text('Visualizar e gerenciar pedidos'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.adminOrders);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.category_outlined, color: Colors.orange),
                        title: const Text('Gerenciar Categorias'),
                        subtitle: const Text('Organizar produtos'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.adminCategories);
                        },
                      ),
                    ],

                    // Logout para usuários autenticados
                    if (isAuthenticated) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Sair', style: TextStyle(color: Colors.red)),
                        onTap: _handleLogout,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'PharmaConnect',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          ],
        ),
      ),
    );
  }
}


