import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/secure_storage_service.dart';
import 'services/fcm_service.dart';
import 'services/session_timeout_manager.dart';
import 'widgets/session_inactivity_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, String> _datos = {};
  bool _isLoading = true;
  String _fcmToken = "Obteniendo token...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatos();
    _obtenerToken();
    
    // Escuchar el notificador de wipe para actualizar la UI en tiempo real
    wipeNotifier.addListener(_onWipeDetected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    wipeNotifier.removeListener(_onWipeDetected);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pasar el estado del ciclo de vida al gestor de sesión
    SessionTimeoutManager().handleAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('[HOME] App resumida, verificando integridad de datos...');
      _cargarDatos();
    }
  }

  void _onWipeDetected() {
    if (mounted) {
      _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡ALERTA! Se ha ejecutado un borrado remoto (WIPE_SECURE_DATA)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _obtenerToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (mounted) {
        setState(() {
          _fcmToken = token ?? "No disponible";
        });
      }
    } catch (e) {
      debugPrint('Error al obtener token para UI: $e');
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final datos = await SecureStorageService.readAllSensitiveData();
    if (mounted) {
      setState(() {
        _datos = datos;
        _isLoading = false;
      });
    }
  }

  Future<void> _restaurarDatos() async {
    await SecureStorageService.restoreSensitiveData();
    await _cargarDatos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos de demostración restaurados correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _copiarToken() {
    Clipboard.setData(ClipboardData(text: _fcmToken));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token FCM copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listener para detectar cualquier interacción del usuario
    return Listener(
      onPointerDown: (_) => SessionTimeoutManager().registerActivity(),
      onPointerMove: (_) => SessionTimeoutManager().registerActivity(),
      onPointerUp: (_) => SessionTimeoutManager().registerActivity(),
      onPointerSignal: (_) => SessionTimeoutManager().registerActivity(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión de Datos Sensibles"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Recargar manualmente",
              onPressed: _cargarDatos,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Cerrar sesión",
              onPressed: () {
                SessionTimeoutManager().stopSession();
                Navigator.of(context).pop();
              },
            )
          ],
        ),
        body: Column(
          children: [
            // El indicador visual de inactividad aparece solo si la sesión está activa
            const SessionInactivityIndicator(),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Información Protegida",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Estos datos están cifrados en el almacenamiento seguro y pueden ser borrados remotamente.",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          _buildDataCard("TOKEN JWT", SecureStorageService.keyToken),
                          _buildDataCard("PIN SEGURIDAD", SecureStorageService.keyPin),
                          _buildDataCard("NÚMERO DE TARJETA", SecureStorageService.keyTarjeta),
                          _buildDataCard("CURP", SecureStorageService.keyCurp),
                          const SizedBox(height: 30),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.restore_outlined),
                              label: const Text("Restaurar datos"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _restaurarDatos,
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          const Divider(),
                          const Text("DIAGNÓSTICO FCM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _copiarToken,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Token FCM: ${_fcmToken.substring(0, _fcmToken.length > 20 ? 20 : _fcmToken.length)}...",
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                    ),
                                  ),
                                  const Icon(Icons.copy, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String key) {
    final value = _datos[key] ?? SecureStorageService.valBorrado;
    final bool isBorrado = value == SecureStorageService.valBorrado;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isBorrado ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  isBorrado ? Icons.warning_amber_rounded : Icons.verified_user,
                  color: isBorrado ? Colors.red : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
