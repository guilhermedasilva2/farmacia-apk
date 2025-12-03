import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meu_app_inicial/core/services/avatar_service.dart';
import 'package:meu_app_inicial/core/services/auth_service.dart';
import 'package:meu_app_inicial/core/services/user_role_service.dart';
import 'package:meu_app_inicial/domain/entities/user_profile.dart';
import 'package:meu_app_inicial/domain/entities/user_role.dart';
import 'package:meu_app_inicial/presentation/widgets/role_badge.dart';
import 'package:meu_app_inicial/core/utils/app_routes.dart';


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
      });
    }
  }

  Future<void> _pick(ImageSource source) async {
    final service = _avatarService ?? await AvatarService.create();
    _avatarService = service;
    final path = await service.pickAndProcessAvatar(source: source);
    if (mounted) {
      setState(() => _avatarPath = path);
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
              backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
              child: _avatarPath == null
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Painel admin em desenvolvimento')),
                          );
                        },
                      ),
                    ],
                    
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
                        title: const Text('Meus Pedidos'),
                        subtitle: const Text('Veja seus produtos para comprar'),
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
                    if (profile.role == UserRole.admin) ...[
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
                        title: const Text('Gerenciar Estoque'),
                        subtitle: const Text('Controle de produtos (Admin)'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.adminProducts);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.shopping_cart_outlined, color: Colors.orange),
                        title: const Text('Gerenciar Pedidos'),
                        subtitle: const Text('Visualizar e gerenciar pedidos (Admin)'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.adminOrders);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.category_outlined, color: Colors.orange),
                        title: const Text('Gerenciar Categorias'),
                        subtitle: const Text('Organizar produtos por categorias (Admin)'),
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


