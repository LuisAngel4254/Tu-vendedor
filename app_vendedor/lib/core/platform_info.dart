// core/platform_info.dart
// Detecta en qué plataforma y entorno está corriendo el app.
// Centraliza esta lógica para que el resto del código nunca
// use Platform.isAndroid directamente — todo pasa por aquí.

import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppPlatform {
  androidPhone,
  androidTablet,
  ios,
  miui,         // MIUI (Xiaomi) — restricciones extra de permisos
  windows,
  macos,
  linux,
  webBrowser,
  unknown,
}

class PlatformInfo {
  PlatformInfo._();
  static final PlatformInfo instance = PlatformInfo._();

  // ─── Detección principal ───────────────────────────────────────────────────

  AppPlatform get current {
    if (kIsWeb) return AppPlatform.webBrowser;

    if (Platform.isAndroid) {
      // MIUI se detecta por variable de entorno del sistema.
      // Lo hacemos en tiempo de ejecución desde la capa nativa
      // (ver _isMiui abajo). En Flutter puro no hay acceso directo,
      // pero dejamos el hook para cuando se agregue el channel nativo.
      if (_isMiuiFlagSet) return AppPlatform.miui;
      return AppPlatform.androidPhone; // tablet se refina en runtime
    }

    if (Platform.isIOS) return AppPlatform.ios;
    if (Platform.isWindows) return AppPlatform.windows;
    if (Platform.isMacOS) return AppPlatform.macos;
    if (Platform.isLinux) return AppPlatform.linux;

    return AppPlatform.unknown;
  }

  // Flag que el canal nativo Android puede setear al detectar MIUI
  bool _isMiuiFlagSet = false;
  void markAsMiui() => _isMiuiFlagSet = true;

  // ─── Booleanos de conveniencia ─────────────────────────────────────────────

  bool get isMobile =>
      current == AppPlatform.androidPhone ||
      current == AppPlatform.androidTablet ||
      current == AppPlatform.ios ||
      current == AppPlatform.miui;

  bool get isDesktop =>
      current == AppPlatform.windows ||
      current == AppPlatform.macos ||
      current == AppPlatform.linux;

  bool get isAndroid =>
      current == AppPlatform.androidPhone ||
      current == AppPlatform.androidTablet ||
      current == AppPlatform.miui;

  bool get isIOS => current == AppPlatform.ios;

  bool get isMiui => current == AppPlatform.miui;

  bool get isWeb => current == AppPlatform.webBrowser;

  // ─── Capacidades por plataforma ────────────────────────────────────────────
  // Estas flags determinan qué permisos se pedirán y qué features están
  // disponibles. La pantalla de configuración las consulta antes de intentar
  // acceder a cámara, ubicación, etc.

  /// ¿Puede tomar fotos desde cámara o galería?
  bool get hasCamera => isMobile;

  /// ¿Tiene GPS nativo?
  bool get hasGps => isMobile;

  /// ¿Puede recibir notificaciones push (FCM)?
  bool get hasPushNotifications =>
      isAndroid || isIOS || isMiui || isMacos;

  bool get isMacos => current == AppPlatform.macos;

  /// En MIUI, la batería y las notificaciones tienen restricciones extra.
  /// El app debe mostrar instrucciones adicionales al usuario.
  bool get needsMiuiExtraSetup => isMiui;

  // ─── Descripción legible (para logs y pantalla de debug) ──────────────────

  String get label {
    switch (current) {
      case AppPlatform.androidPhone:
        return 'Android';
      case AppPlatform.androidTablet:
        return 'Android (Tablet)';
      case AppPlatform.ios:
        return 'iOS';
      case AppPlatform.miui:
        return 'Android MIUI (Xiaomi)';
      case AppPlatform.windows:
        return 'Windows';
      case AppPlatform.macos:
        return 'macOS';
      case AppPlatform.linux:
        return 'Linux';
      case AppPlatform.webBrowser:
        return 'Navegador Web';
      case AppPlatform.unknown:
        return 'Plataforma desconocida';
    }
  }

  @override
  String toString() => 'PlatformInfo(platform: $label)';
}
