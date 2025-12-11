import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Serviço para autenticação biométrica
/// Suporta impressão digital e reconhecimento facial
class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica se o dispositivo suporta biometria
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Verifica se há biometria cadastrada no dispositivo
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Lista os tipos de biometria disponíveis
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Autentica usando biometria
  /// Retorna true se autenticação foi bem-sucedida
  Future<bool> authenticate({
    String localizedReason = 'Autentique-se para acessar o aplicativo',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final canAuthenticate = await canCheckBiometrics() || await isDeviceSupported();
      
      if (!canAuthenticate) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      // Erros comuns:
      // - NotAvailable: biometria não disponível
      // - NotEnrolled: sem biometria cadastrada
      // - LockedOut: muitas tentativas falhas
      // - PermanentlyLockedOut: bloqueado permanentemente
      debugPrint('Erro de autenticação biométrica: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// Cancela autenticação em andamento
  Future<void> stopAuthentication() async {
    await _auth.stopAuthentication();
  }

  /// Verifica se biometria está disponível e configurada
  Future<bool> isBiometricAvailable() async {
    final canCheck = await canCheckBiometrics();
    final isSupported = await isDeviceSupported();
    final biometrics = await getAvailableBiometrics();
    
    return canCheck && isSupported && biometrics.isNotEmpty;
  }

  /// Obtém descrição amigável do tipo de biometria
  String getBiometricTypeDescription(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Reconhecimento Facial';
      case BiometricType.fingerprint:
        return 'Impressão Digital';
      case BiometricType.iris:
        return 'Reconhecimento de Íris';
      case BiometricType.strong:
        return 'Biometria Forte';
      case BiometricType.weak:
        return 'Biometria Fraca';
    }
  }
}
