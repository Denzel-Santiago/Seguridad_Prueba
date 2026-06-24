import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'secure_storage_service.dart';

/// Notificador global para avisar a la interfaz que los datos fueron borrados.
final ValueNotifier<int> wipeNotifier = ValueNotifier<int>(0);

/// Manejador de mensajes en segundo plano.
/// Debe ser una función top-level y tener @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final action = message.data['action'];
  debugPrint('[FCM][BACKGROUND] Mensaje recibido: ${message.data}');

  if (action == 'WIPE_SECURE_DATA') {
    debugPrint('[FCM][BACKGROUND] Orden WIPE_SECURE_DATA recibida');
    await SecureStorageService.deleteAllSensitiveData();
    debugPrint('[FCM][BACKGROUND] Datos sensibles eliminados');
  }
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> inicializarFCM() async {
    if (_initialized) return;

    // 1. Solicitar permisos (especialmente para Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[FCM] Permisos concedidos');
    } else {
      debugPrint('[FCM] Permisos denegados o no otorgados');
    }

    // 2. Obtener Token FCM
    try {
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('===== TOKEN FCM =====');
        debugPrint('[FCM] Token del dispositivo: $token');
        debugPrint('=====================');
      }
    } catch (e) {
      debugPrint('[FCM] Error al obtener el token: $e');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token actualizado: $newToken');
    });

    // 3. Listeners
    FirebaseMessaging.onMessage.listen((message) => _processMessage(message, 'FOREGROUND'));
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _processMessage(message, 'MESSAGE_OPENED'));

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _processMessage(initialMessage, 'INITIAL_MESSAGE');
    }

    _initialized = true;
  }

  static Future<void> _processMessage(RemoteMessage message, String source) async {
    final action = message.data['action'];
    debugPrint('[FCM][$source] action: $action');

    if (action == 'WIPE_SECURE_DATA') {
      await SecureStorageService.deleteAllSensitiveData();
      // Notificar a la UI activa
      wipeNotifier.value++;
    }
  }
}
