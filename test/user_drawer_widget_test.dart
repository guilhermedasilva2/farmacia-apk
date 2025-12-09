import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meu_app_inicial/features/app/widgets/user_drawer.dart';
import 'package:meu_app_inicial/features/auth/infrastructure/services/auth_service.dart';
import 'package:meu_app_inicial/features/auth/infrastructure/services/user_role_service.dart';
import 'package:meu_app_inicial/features/profile/domain/entities/user_profile.dart';
import 'package:meu_app_inicial/features/auth/domain/entities/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    
    // Initialize Supabase with dummy values to prevent AuthService constructor from crashing
    try {
      await Supabase.initialize(
        url: 'https://dummy.supabase.co',
        anonKey: 'dummy-key',
      );
    } catch (_) {}
  });

  testWidgets('Drawer shows initials by default', (tester) async {
    // Initialize Supabase with dummy data to avoid crash in AuthService constructor
    // Note: In a real app, we should use a MockSupabaseClient, but for now this workaround allows AuthService to be instantiated
    // However, we will use a MockAuthService that overrides the methods, so the client won't be used.
    
    final mockAuthService = MockAuthService();
    final mockRoleService = MockUserRoleService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UserDrawer(
          authService: mockAuthService,
          roleService: mockRoleService,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('U'), findsOneWidget); 
  });

  testWidgets('Drawer shows image when avatar path is saved', (tester) async {
    final tmpDir = Directory.systemTemp.createTempSync();
    final file = File('${tmpDir.path}/avatar.jpg');
    final testImage = img.Image(width: 4, height: 4);
    await file.writeAsBytes(img.encodeJpg(testImage));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_path_v1', file.path);

    final mockAuthService = MockAuthService();
    final mockRoleService = MockUserRoleService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UserDrawer(
          authService: mockAuthService,
          roleService: mockRoleService,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The CircleAvatar with backgroundImage doesn't expose a direct matcher; we at least ensure no initials text now
    expect(find.text('U'), findsNothing);
  });
}

class MockAuthService extends AuthService {
  @override
  User? get currentUser => const User(
    id: 'test-id',
    appMetadata: {},
    userMetadata: {'display_name': 'Usuário'},
    aud: 'authenticated',
    createdAt: '2023-01-01T00:00:00.000Z',
  );

  @override
  Stream<User?> get authStateChanges => Stream.value(currentUser);

  @override
  Future<UserProfile?> getUserProfile() async {
    return UserProfile(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Usuário',
      role: UserRole.user,
      createdAt: DateTime.now(),
    );
  }
}

class MockUserRoleService extends UserRoleService {
  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    return UserProfile(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Usuário',
      role: UserRole.user,
      createdAt: DateTime.now(),
    );
  }
}


