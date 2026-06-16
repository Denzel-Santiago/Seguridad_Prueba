import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'services/security_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool bloqueado = false;
  String mensajeBloqueo = "";
  Timer? securityTimer;

  @override
  void initState() {
    super.initState();
    iniciarSeguridad();

    securityTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => verificarUsbDebuggingTiempoReal(),
    );
  }

  @override
  void dispose() {
    securityTimer?.cancel();
    super.dispose();
  }

  Future<void> iniciarSeguridad() async {
    // 1. Protección de capturas (Ahora se maneja nativamente en MainActivity.kt)

    // 2. Verificar USB Debugging (RASP)
    await verificarUsbDebugging();

    // 3. Verificar Fake GPS
    if (!bloqueado) {
      await verificarFakeGPS();
    }
  }

  Future<void> verificarUsbDebugging() async {
    bool adbEnabled = await SecurityService.isUsbDebuggingEnabled();

    if (adbEnabled) {
      setState(() {
        bloqueado = true;
        mensajeBloqueo = "Depuración USB Detectada";
      });
      _mostrarAlertaBloqueo(
        "Depuración USB Activa",
        "La aplicación no puede ejecutarse porque la Depuración USB está activa. Por favor, desactívela en las Opciones de Desarrollador.",
      );
    }
  }

  Future<void> verificarUsbDebuggingTiempoReal() async {
    bool adbEnabled = await SecurityService.isUsbDebuggingEnabled();

    if (adbEnabled && !bloqueado) {
      setState(() {
        bloqueado = true;
        mensajeBloqueo = "Depuración USB Detectada";
      });

      _mostrarAlertaBloqueo(
        "Depuración USB Activa",
        "La aplicación ha detectado que la Depuración USB fue activada. Por motivos de seguridad la aplicación será bloqueada hasta que se desactive.",
      );
    } else if (!adbEnabled && bloqueado && mensajeBloqueo == "Depuración USB Detectada") {
      setState(() {
        bloqueado = false;
        mensajeBloqueo = "";
      });

      // Cerramos el diálogo de alerta si está presente
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> verificarFakeGPS() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    if (position.isMocked) {
      setState(() {
        bloqueado = true;
        mensajeBloqueo = "Fake GPS Detectado";
      });
      _mostrarAlertaBloqueo(
        "Fake GPS Detectado",
        "La aplicación no puede ejecutarse porque se detectó una ubicación falsa.",
      );
    }
  }

  void _mostrarAlertaBloqueo(String titulo, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text("Cerrar Aplicación"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Seguro"),
      ),
      body: bloqueado
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_update_warning, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              mensajeBloqueo,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Por seguridad, la aplicación ha sido deshabilitada en este dispositivo.",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Usuario",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Lógica de ingreso
                },
                child: const Text("Ingresar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
