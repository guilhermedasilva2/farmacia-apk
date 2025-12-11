import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço para gerenciar conectividade e retry de operações
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream de mudanças de conectividade
  Stream<List<ConnectivityResult>> get onConnectivityChanged => 
      _connectivity.onConnectivityChanged;

  /// Verifica se há conexão com internet
  Future<bool> hasConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty && !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Verifica conectividade real fazendo ping
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Executa uma operação com retry em caso de falha de rede
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } on SocketException {
        attempts++;
        
        if (attempts >= maxRetries) {
          throw Exception(
            'Sem conexão com a internet. Verifique sua conexão e tente novamente.',
          );
        }

        // Aguarda antes de tentar novamente
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
        
      } on TimeoutException {
        attempts++;
        
        if (attempts >= maxRetries) {
          throw Exception(
            'Tempo esgotado. Verifique sua conexão e tente novamente.',
          );
        }

        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
        
      } catch (e) {
        // Outros erros não são retentados
        rethrow;
      }
    }

    throw Exception('Falha após $maxRetries tentativas');
  }

  /// Aguarda até que haja conexão
  Future<void> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      if (await hasConnection()) {
        return;
      }
      await Future.delayed(checkInterval);
    }
    
    throw TimeoutException('Timeout aguardando conexão');
  }

  /// Monitora mudanças de conectividade
  void startMonitoring(void Function(List<ConnectivityResult>) onChanged) {
    _subscription = onConnectivityChanged.listen(onChanged);
  }

  /// Para de monitorar conectividade
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Limpa recursos
  void dispose() {
    stopMonitoring();
  }
}
