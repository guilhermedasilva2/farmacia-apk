import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meu_app_inicial/services/avatar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('initialsFromName handles single and double names', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = AvatarService(prefs: prefs);
    expect(svc.initialsFromName('Maria'), 'M');
    expect(svc.initialsFromName('Maria Souza'), 'MS');
    expect(svc.initialsFromName('  João   Silva  '), 'JS');
    expect(svc.initialsFromName(''), 'U');
  });

  test('save and clear avatar path', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = AvatarService(prefs: prefs);
    await prefs.setString('user_avatar_path_v1', '/tmp/fake.jpg');
    expect(await svc.getSavedAvatarPath(), '/tmp/fake.jpg');
    await svc.clearAvatar();
    expect(await svc.getSavedAvatarPath(), isNull);
  });

  test('image processing produces jpeg bytes', () {
    // Create a small test image
    final img.Image input = img.Image(width: 2, height: 2);
    final bytes = Uint8List.fromList(img.encodePng(input));
    final processed = processImageBytesForAvatar(bytes);
    expect(processed, isNotEmpty);
    // JPEG starts with 0xFF 0xD8
    expect(processed[0], 0xFF);
    expect(processed[1], 0xD8);
  });
}


