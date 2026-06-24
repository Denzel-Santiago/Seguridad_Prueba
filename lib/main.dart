import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/secure_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registrar el manejador de mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 2. Inicializar Datos Sensibles (Solo la primera vez)
  await SecureStorageService.initializeSensitiveDataIfNeeded();
  
  // Diagnóstico
  await SecureStorageService.imprimirDatos();

  // 3. Inicializar FCM (Permisos, Token y Listeners de primer plano)
  await FCMService.inicializarFCM();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const App(),
    ),
  );
}
