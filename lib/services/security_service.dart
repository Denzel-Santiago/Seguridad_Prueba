import 'package:flutter/services.dart';

class SecurityService {
  static const _channel = MethodChannel('com.example.flutter_prueba/security');

  static Future<bool> isUsbDebuggingEnabled() async {
    try {
      final bool isEnabled = await _channel.invokeMethod('isUsbDebuggingEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      print("Error checking USB debugging: '${e.message}'.");
      return false;
    }
  }
}
