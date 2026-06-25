// core/permissions_handler.dart
// Centraliza la solicitud de permisos.
// Cada pantalla llama a este handler en lugar de pedir permisos directamente,
// así la lógica de "qué pedir en qué plataforma" vive en un solo lugar.

import 'package:permission_handler/permission_handler.dart';
import 'platform_info.dart';

class PermissionsResult {
  final bool camera;
  final bool location;
  final bool notifications;
  final bool allRequired; // location + notifications son obligatorios

  const PermissionsResult({
    required this.camera,
    required this.location,
    required this.notifications,
  }) : allRequired = location && notifications;
}

class PermissionsHandler {
  PermissionsHandler._();
  static final PermissionsHandler instance = PermissionsHandler._();

  final _platform = PlatformInfo.instance;

  // ─── Solicitud inicial completa ────────────────────────────────────────────
  // Llamar una vez al entrar a la pantalla de configuración del local.
  // Devuelve el resultado para que la UI reaccione.

  Future<PermissionsResult> requestAll() async {
    bool camera = false;
    bool location = false;
    bool notifications = false;

    // Cámara — solo en móvil
    if (_platform.hasCamera) {
      final status = await Permission.camera.request();
      camera = status.isGranted;
    } else {
      camera = true; // En desktop, la foto se sube desde archivo — no necesita permiso
    }

    // Ubicación — GPS en móvil, no disponible en web/desktop puro
    if (_platform.hasGps) {
      final status = await Permission.locationWhenInUse.request();
      location = status.isGranted;
    } else {
      // En desktop/web mostramos campo manual de dirección
      location = false; // El caller debe manejar esto mostrando input manual
    }

    // Notificaciones push
    if (_platform.hasPushNotifications) {
      final status = await Permission.notification.request();
      notifications = status.isGranted;
    } else {
      notifications = false;
    }

    return PermissionsResult(
      camera: camera,
      location: location,
      notifications: notifications,
    );
  }

  // ─── Re-verificación (sin volver a pedir) ─────────────────────────────────
  // Útil para revisar el estado actual sin molestar al usuario.

  Future<PermissionsResult> checkStatus() async {
    final camera = _platform.hasCamera
        ? (await Permission.camera.status).isGranted
        : true;

    final location = _platform.hasGps
        ? (await Permission.locationWhenInUse.status).isGranted
        : false;

    final notifications = _platform.hasPushNotifications
        ? (await Permission.notification.status).isGranted
        : false;

    return PermissionsResult(
      camera: camera,
      location: location,
      notifications: notifications,
    );
  }

  // ─── Abrir configuración del sistema ──────────────────────────────────────
  // Para cuando el usuario denegó permanentemente y hay que ir a Ajustes.

  Future<void> openAppSettings() => openAppSettings();
}
