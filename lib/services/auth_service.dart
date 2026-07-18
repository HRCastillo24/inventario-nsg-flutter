import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginResponse {
  final bool success;
  final String? token;
  final String? error;
  final bool? bloqueado;
  final int? segundosRestantes;
  final int? intentosRestantes;

  LoginResponse({
    required this.success,
    this.token,
    this.error,
    this.bloqueado,
    this.segundosRestantes,
    this.intentosRestantes,
  });
}

class AuthService {
  final String baseUrl;
  final _storage = const FlutterSecureStorage();

  AuthService({required this.baseUrl});

  /// Login mejorado con manejo de bloqueo
  Future<LoginResponse> login(String correo, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/api/usuarios/login');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'password': password}),
      );

      final data = jsonDecode(response.body);

      // LOGIN EXITOSO
      if (response.statusCode == 200) {
        final token = data['token'] ?? data['access_token'];

        if (token != null) {
          await _storage.write(key: 'jwt_token', value: token);
          return LoginResponse(success: true, token: token);
        }
      }

      // BLOQUEADO 
      if (response.statusCode == 429) {
        return LoginResponse(
          success: false,
          bloqueado: true,
          segundosRestantes: data['segundos_restantes'] ?? 30,
          error: data['mensaje'] ?? 'Demasiados intentos. Espera 30 segundos.',
        );
      }

      // CONTRASEÑA INCORRECTA 
      if (response.statusCode == 401) {
        return LoginResponse(
          success: false,
          intentosRestantes: data['intentos_restantes'],
          error: data['mensaje'] ?? 'Credenciales incorrectas',
        );
      }

      // OTROS ERRORES
      return LoginResponse(
        success: false,
        error: data['error'] ?? 'Error al iniciar sesión',
      );
    } catch (e) {
      print('Error en login: $e');
      return LoginResponse(
        success: false,
        error: 'Error de conexión. Verifica tu internet.',
      );
    }
  }

  /// Logout: elimina el token guardado
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  /// Obtener token almacenado
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}