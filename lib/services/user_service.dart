import 'package:flutter/material.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  /// Obtener todos los usuarios (solo gerente)
  Future<List<dynamic>> obtenerUsuarios(BuildContext context) async {
    try {
      final response = await _apiService.get(context, '/api/usuarios');
      return response['usuarios'] ?? [];
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Crear usuario (solo gerente)
  Future<Map<String, dynamic>> crearUsuario(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _apiService.post(context, '/api/usuarios', data);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// Actualizar usuario (solo gerente)
  Future<void> actualizarUsuario(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _apiService.put(context, '/api/usuarios/$id', data);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// Eliminar usuario (solo gerente)
  Future<void> eliminarUsuario(BuildContext context, String id) async {
    try {
      await _apiService.delete(context, '/api/usuarios/$id');
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  /// Obtener perfil del usuario autenticado
  Future<Map<String, dynamic>> obtenerPerfil(BuildContext context) async {
    try {
      return await _apiService.get(context, '/api/usuarios/perfil');
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }
}