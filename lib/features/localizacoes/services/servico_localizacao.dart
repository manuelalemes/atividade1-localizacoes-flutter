import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum ResultadoPermissao {
  concedida,
  servicoDesativado,
  negada,
  negadaPermanentemente,
}

class ServicoLocalizacao {
  static const Duration intervalo = Duration(seconds: 20);

  /// Verifica o GPS e as permissões, solicitando quando necessário.
  Future<ResultadoPermissao> verificarPermissoes() async {
    final habilitado = await Geolocator.isLocationServiceEnabled();
    if (!habilitado) return ResultadoPermissao.servicoDesativado;

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      return ResultadoPermissao.negada;
    }
    if (permissao == LocationPermission.deniedForever) {
      return ResultadoPermissao.negadaPermanentemente;
    }

    // Android 13+: necessária para exibir a notificação do serviço.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }
    return ResultadoPermissao.concedida;
  }

  /// Stream contínuo de posições (alta precisão, intervalo de 20 s).
  /// No Android roda como serviço em primeiro plano, com notificação.
  Stream<Position> posicoes() {
    return Geolocator.getPositionStream(locationSettings: _configuracao());
  }

  LocationSettings _configuracao() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: intervalo,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Coleta de localização ativa',
            notificationText: 'Gravando sua posição a cada 20 segundos.',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.otherNavigation,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
    }
  }

  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();
}
