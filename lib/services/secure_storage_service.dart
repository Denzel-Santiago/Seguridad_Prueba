import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Claves constantes internas (Requisito)
  static const String keyInitialized = 'sensitive_data_initialized';
  static const String keyToken = 'token_jwt';
  static const String keyPin = 'pin_seguridad';
  static const String keyTarjeta = 'numero_tarjeta';
  static const String keyCurp = 'curp_usuario';

  static const String valBorrado = 'BORRADO REMOTAMENTE';

  /// Inicializa los datos sensibles solo si es la primera vez que se instala la aplicación.
  /// Esto asegura que después de un wipe no se regeneren automáticamente.
  static Future<void> initializeSensitiveDataIfNeeded() async {
    try {
      String? isInitialized = await _storage.read(key: keyInitialized);
      if (isInitialized == null) {
        await restoreSensitiveData();
        await _storage.write(key: keyInitialized, value: 'true');
        debugPrint('[SECURE_STORAGE] Inicialización por primera vez completada');
      } else {
        bool exists = await hasSensitiveData();
        debugPrint('[SECURE_STORAGE] Datos sensibles existentes: $exists');
      }
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error en initializeSensitiveDataIfNeeded: $e');
    }
  }

  /// Lee los cuatro campos sensibles. Devuelve 'BORRADO REMOTAMENTE' si no existen.
  static Future<Map<String, String>> readAllSensitiveData() async {
    try {
      final token = await _storage.read(key: keyToken);
      final pin = await _storage.read(key: keyPin);
      final tarjeta = await _storage.read(key: keyTarjeta);
      final curp = await _storage.read(key: keyCurp);

      return {
        keyToken: token ?? valBorrado,
        keyPin: pin ?? valBorrado,
        keyTarjeta: tarjeta ?? valBorrado,
        keyCurp: curp ?? valBorrado,
      };
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error al leer datos sensibles: $e');
      return {
        keyToken: valBorrado,
        keyPin: valBorrado,
        keyTarjeta: valBorrado,
        keyCurp: valBorrado,
      };
    }
  }

  /// Borra individualmente los cuatro datos sensibles (REQUISITO CRÍTICO).
  /// No borra la clave de inicialización para evitar regeneración automática.
  static Future<void> deleteAllSensitiveData() async {
    try {
      await _storage.delete(key: keyToken);
      await _storage.delete(key: keyPin);
      await _storage.delete(key: keyTarjeta);
      await _storage.delete(key: keyCurp);
      debugPrint('[SECURE_STORAGE] Los cuatro datos sensibles fueron eliminados');
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error al realizar el wipe: $e');
    }
  }

  /// Escribe los valores de demostración en los cuatro campos.
  static Future<void> restoreSensitiveData() async {
    try {
      await _storage.write(key: keyToken, value: 'eyJhbGciOiJIUzI1NiJ9.demo.token');
      await _storage.write(key: keyPin, value: '7291');
      await _storage.write(key: keyTarjeta, value: '4532-1234-5678-9012');
      await _storage.write(key: keyCurp, value: 'HEGJ990512HCSRNV04');
      debugPrint('[SECURE_STORAGE] Datos de demostración restaurados');
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error al restaurar datos: $e');
    }
  }

  /// Verifica si el token (primer campo) existe.
  static Future<bool> hasSensitiveData() async {
    final token = await _storage.read(key: keyToken);
    return token != null;
  }

  /// Método de diagnóstico para imprimir en consola.
  static Future<void> imprimirDatos() async {
    final datos = await readAllSensitiveData();
    debugPrint('[SECURE_STORAGE] Contenido actual: $datos');
  }
}
