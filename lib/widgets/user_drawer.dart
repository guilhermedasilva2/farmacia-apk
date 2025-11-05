import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meu_app_inicial/services/avatar_service.dart';

class UserDrawer extends StatefulWidget {
  const UserDrawer({super.key});

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  String? _avatarPath;
  AvatarService? _avatarService;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = await AvatarService.create();
    final saved = await service.getSavedAvatarPath();
    if (mounted) {
      setState(() {
        _avatarService = service;
        _avatarPath = saved;
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

  @override
  Widget build(BuildContext context) {
    final String displayName = _avatarService?.getUserDisplayName() ?? 'Usuário';
    final String initials = (_avatarService?.initialsFromName(displayName)) ?? 'U';

    final Widget avatar = Semantics(
      label: 'Foto de perfil do usuário',
      hint: _avatarPath == null ? 'Toque para adicionar foto' : 'Toque para alterar foto',
      button: true,
      child: Tooltip(
        message: _avatarPath == null ? 'Adicionar foto' : 'Alterar foto',
        child: InkWell(
          onTap: () async {
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
          },
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
              child: Row(
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
                        Text(
                          'Perfil',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                  if (mounted) setState(() {});
                }
              },
            ),
            const Spacer(),
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


