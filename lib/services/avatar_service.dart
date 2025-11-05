import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarService {
  static const String _prefsAvatarPathKey = 'user_avatar_path_v1';
  static const String _prefsUserNameKey = 'user_display_name_v1';

  final ImagePicker _picker;
  final SharedPreferences _prefs;

  AvatarService({ImagePicker? picker, required SharedPreferences prefs})
      : _picker = picker ?? ImagePicker(),
        _prefs = prefs;

  static Future<AvatarService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AvatarService(prefs: prefs);
  }

  Future<String?> getSavedAvatarPath() async {
    return _prefs.getString(_prefsAvatarPathKey);
  }

  Future<void> clearAvatar() async {
    final path = _prefs.getString(_prefsAvatarPathKey);
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {
        // ignore cleanup errors
      }
    }
    await _prefs.remove(_prefsAvatarPathKey);
  }

  Future<void> saveUserDisplayName(String name) async {
    await _prefs.setString(_prefsUserNameKey, name);
  }

  String getUserDisplayName({String fallback = 'Usuário'}) {
    return _prefs.getString(_prefsUserNameKey) ?? fallback;
  }

  String initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return 'U';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final letters = (first + last).toUpperCase();
    return letters.isEmpty ? 'U' : letters;
  }

  Future<String?> pickAndProcessAvatar({ImageSource source = ImageSource.gallery}) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 100);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final processed = await compute(processImageBytesForAvatar, bytes);

    final dir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${dir.path}/avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    final filePath = '${avatarsDir.path}/avatar.jpg';
    final file = File(filePath);
    await file.writeAsBytes(processed, flush: true);

    await _prefs.setString(_prefsAvatarPathKey, filePath);
    return filePath;
  }
}

/// Processes image bytes for avatar: resizes to max 512, compresses, strips metadata.
Uint8List processImageBytesForAvatar(Uint8List originalBytes) {
  // Decode image and strip metadata by re-encoding
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) return originalBytes;

  // Resize to fit within 512x512, maintaining aspect ratio
  final resized = img.copyResize(decoded, width: 512, height: 512, interpolation: img.Interpolation.average, maintainAspect: true);

  // Encode to JPEG with quality 85 (drops EXIF/GPS by default)
  final encoded = img.encodeJpg(resized, quality: 85);
  return Uint8List.fromList(encoded);
}


