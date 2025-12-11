import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço para armazenamento seguro de dados sensíveis
/// Usa Keychain no iOS e KeyStore no Android
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys para armazenamento
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  /// Salva o token de autenticação
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  /// Obtém o token de autenticação
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  /// Salva o refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Obtém o refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Salva o ID do usuário
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  /// Obtém o ID do usuário
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Salva preferência de biometria
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  /// Verifica se biometria está habilitada
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Limpa todos os dados armazenados (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Verifica se existe sessão salva
  Future<bool> hasSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
