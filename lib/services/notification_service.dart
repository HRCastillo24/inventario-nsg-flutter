import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notificacion.dart';

class NotificationService {
  static const String baseUrl = 'https://nsglatinoamerica.duckdns.org/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // OBTENER NOTIFICACIONES
  Future<List<Notificacion>> obtenerNotificaciones(String rol, int idUsuario) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/notificaciones?rol=$rol&id_usuario=$idUsuario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Notificacion.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerNotificaciones: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // OBTENER CONTADOR DE NO LEÍDAS - CORREGIDO
  Future<Map<String, dynamic>> obtenerContadorNoLeidas(String rol, int idUsuario) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/notificaciones/no-leidas?rol=$rol&id_usuario=$idUsuario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response contador status: ${response.statusCode}');
      print('Response contador body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // EXTRAER CORRECTAMENTE EL TOTAL
        final int total = data['total'] is int 
            ? data['total'] 
            : int.tryParse(data['total'].toString()) ?? 0;

        print('✅ Contador obtenido del backend: $total');

        return {
          'total': total,
          'detalle': data['detalle'] ?? {},
        };
      } else {
        print('⚠️ Error status code: ${response.statusCode}');
        throw Exception('Error al obtener contador');
      }
    } catch (e) {
      print('❌ Error en obtenerContadorNoLeidas: $e');
      // En caso de error, retornar 0
      return {'total': 0, 'detalle': {}};
    }
  }

  // MARCAR COMO LEÍDA
  Future<bool> marcarComoLeida(int idNotificacion) async {
    try {
      final token = await _getToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl/notificaciones/$idNotificacion/leer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('✅ Marcada como leída ID: $idNotificacion - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en marcarComoLeida: $e');
      return false;
    }
  }

  // MARCAR TODAS COMO LEÍDAS
  Future<bool> marcarTodasComoLeidas(String rol, int idUsuario) async {
    try {
      final token = await _getToken();
      
      print(' Marcando todas como leídas - Rol: $rol, Usuario: $idUsuario');
      
      final response = await http.put(
        Uri.parse('$baseUrl/notificaciones/marcar-todas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rol': rol,
          'id_usuario': idUsuario,
        }),
      );

      print('✅ Response marcar todas: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en marcarTodasComoLeidas: $e');
      return false;
    }
  }

  // ELIMINAR NOTIFICACIÓN
  Future<bool> eliminarNotificacion(int idNotificacion) async {
    try {
      final token = await _getToken();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/notificaciones/$idNotificacion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('✅ Notificación eliminada ID: $idNotificacion - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en eliminarNotificacion: $e');
      return false;
    }
  }

  // LIMPIAR NOTIFICACIONES ANTIGUAS (OPCIONAL)
  Future<bool> limpiarNotificacionesAntiguas(String rol, int idUsuario) async {
    try {
      final token = await _getToken();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/notificaciones/limpiar?rol=$rol&id_usuario=$idUsuario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en limpiarNotificacionesAntiguas: $e');
      return false;
    }
  }
}