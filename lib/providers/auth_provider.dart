import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class AuthProvider with ChangeNotifier {
  final AuthService authService;
  final _storage = const FlutterSecureStorage();
  
  bool _authenticated = false;
  Usuario? _usuario;
  
  // Propiedades para manejo de bloqueo
  String? _error;
  bool _bloqueado = false;
  int _segundosRestantes = 0;
  int? _intentosRestantes;

  AuthProvider({required this.authService});

  bool get isAuthenticated => _authenticated;
  Usuario? get usuario => _usuario;
  
  // Getters para el bloqueo
  String? get error => _error;
  bool get bloqueado => _bloqueado;
  int get segundosRestantes => _segundosRestantes;
  int? get intentosRestantes => _intentosRestantes;

  /// Login mejorado con manejo de bloqueo
  Future<bool> login(String username, String password) async {
    // Resetear estados de error
    _error = null;
    _bloqueado = false;
    _segundosRestantes = 0;
    _intentosRestantes = null;
    notifyListeners();

    // Llamar al servicio de autenticación
    final response = await authService.login(username, password);

    if (response.success) {
      final token = response.token ?? await authService.getToken();
      if (token != null) {
        _authenticated = true;

        // Decodificar el JWT
        final decoded = JwtDecoder.decode(token);
        _usuario = Usuario.fromJson({
          'id': decoded['id'] ?? decoded['_id'] ?? '',
          'nombre': decoded['nombre'] ?? '',
          'correo': decoded['correo'] ?? username,
          'rol': decoded['rol'] ?? 'trabajador',
        });

        // Guardar datos en storage
        final userId = decoded['id'] ?? decoded['_id'];
        if (userId != null) {
          await _storage.write(key: 'id_usuario', value: userId.toString());
          await _storage.write(key: 'nombre_usuario', value: decoded['nombre'] ?? '');
          await _storage.write(key: 'rol_usuario', value: decoded['rol'] ?? 'trabajador');
          await _storage.write(key: 'correo_usuario', value: decoded['correo'] ?? username);
        }

        notifyListeners();
        return true;
      }
    }

    // Manejar respuestas de error
    _authenticated = false;
    _usuario = null;
    _error = response.error;
    _bloqueado = response.bloqueado ?? false;
    _segundosRestantes = response.segundosRestantes ?? 0;
    _intentosRestantes = response.intentosRestantes;
    
    notifyListeners();
    return false;
  }

  /// Actualizar contador de bloqueo 
  void actualizarSegundosRestantes(int segundos) {
    _segundosRestantes = segundos;
    if (segundos <= 0) {
      _bloqueado = false;
      _error = null;
    }
    notifyListeners();
  }

  /// Limpiar solo el mensaje de error
  void limpiarMensajeError() {
    _error = null;
    notifyListeners();
  }

  /// Cierra sesión y borra token
  Future<void> logout() async {
    await authService.logout();
    
    await _storage.delete(key: 'id_usuario');
    await _storage.delete(key: 'nombre_usuario');
    await _storage.delete(key: 'rol_usuario');
    await _storage.delete(key: 'correo_usuario');
    
    _authenticated = false;
    _usuario = null;
    _error = null;
    _bloqueado = false;
    _segundosRestantes = 0;
    _intentosRestantes = null;
    
    notifyListeners();
  }

  /// Verifica token guardado al iniciar la app
  Future<void> checkAuthStatus() async {
    final token = await authService.getToken();
    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      _authenticated = true;
      final decoded = JwtDecoder.decode(token);
      _usuario = Usuario.fromJson({
        'id': decoded['id'] ?? decoded['_id'] ?? '',
        'nombre': decoded['nombre'] ?? '',
        'correo': decoded['correo'] ?? '',
        'rol': decoded['rol'] ?? 'trabajador',
      });

      final userId = decoded['id'] ?? decoded['_id'];
      if (userId != null) {
        await _storage.write(key: 'id_usuario', value: userId.toString());
        await _storage.write(key: 'nombre_usuario', value: decoded['nombre'] ?? '');
        await _storage.write(key: 'rol_usuario', value: decoded['rol'] ?? 'trabajador');
        await _storage.write(key: 'correo_usuario', value: decoded['correo'] ?? '');
      }
    } else {
      _authenticated = false;
      _usuario = null;
    }
    notifyListeners();
  }
}