import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meu_app_inicial/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Drawer shows initials by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle(); // Wait for initial build

    // Open the drawer
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle(); // Wait for drawer animation to complete

    expect(find.textContaining('U'), findsWidgets); // Fallback initials from 'Usuário'
  });

  testWidgets('Drawer shows image when avatar path is saved', (tester) async {
    // Create a small jpg file in temp
    final tmpDir = Directory.systemTemp.createTempSync();
    final file = File('${tmpDir.path}/avatar.jpg');
    final testImage = img.Image(width: 4, height: 4);
    await file.writeAsBytes(img.encodeJpg(testImage));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_path_v1', file.path);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle(); // Wait for initial build
    
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle(); // Wait for drawer animation

    // The CircleAvatar with backgroundImage doesn't expose a direct matcher; we at least ensure no initials text now
    expect(find.text('U'), findsNothing);
  });
}


