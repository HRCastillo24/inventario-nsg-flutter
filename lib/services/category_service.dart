import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/categoria.dart';

class CategoryService {
  final ApiService _apiService;

  CategoryService(this._apiService);

  // ==========================================
  // OBTENER CATEGORÍAS
  // ==========================================

  // Obtener todos los tipos
  Future<List<Categoria>> obtenerTipos(BuildContext context) async {
    try {
      final response = await _apiService.get(context, '/api/categorias/tipos');
      return (response as List).map((json) => Categoria.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error al obtener tipos: $e');
      rethrow;
    }
  }

  // Obtener todas las marcas
  Future<List<Categoria>> obtenerMarcas(BuildContext context) async {
    try {
      final response = await _apiService.get(context, '/api/categorias/marcas');
      return (response as List).map((json) => Categoria.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error al obtener marcas: $e');
      rethrow;
    }
  }

  // Obtener todas las categorías
  Future<List<Categoria>> obtenerTodasCategorias(BuildContext context) async {
    try {
      final response = await _apiService.get(context, '/api/categorias');
      return (response as List).map((json) => Categoria.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      rethrow;
    }
  }

  // Obtener categoría por ID
  Future<Categoria> obtenerCategoriaPorId(BuildContext context, int id) async {
    try {
      final response = await _apiService.get(context, '/api/categorias/$id');
      return Categoria.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener categoría: $e');
      rethrow;
    }
  }

  // ==========================================
  // CREAR CATEGORÍA
  // ==========================================

  // Crear nueva categoría
  Future<Map<String, dynamic>> crearCategoria(
    BuildContext context,
    String nombre,
    String tipoCategoria, 
    {String? descripcion}
  ) async {
    try {
      final data = {
        'nombre_categoria': nombre,
        'tipo_categoria': tipoCategoria,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'estado_categoria': 'activa'
      };

      final response = await _apiService.post(
        context,
        '/api/categorias',
        data,
      );

      return response;
    } catch (e) {
      if (e.toString().contains('409')) {
        throw Exception('Ya existe una categoría con ese nombre');
      }
      print('❌ Error al crear categoría: $e');
      rethrow;
    }
  }

  // ==========================================
  // ACTUALIZAR CATEGORÍA
  // ==========================================

  // Actualizar categoría existente
  Future<void> actualizarCategoria(
    BuildContext context,
    int id,
    String nombre,
    String tipoCategoria,
    {String? descripcion}
  ) async {
    try {
      final data = {
        'nombre_categoria': nombre,
        'tipo_categoria': tipoCategoria,
        if (descripcion != null && descripcion.isNotEmpty) 
          'descripcion': descripcion
        else 
          'descripcion': null,
        'estado_categoria': 'activa'
      };

      await _apiService.put(
        context,
        '/api/categorias/$id',
        data,
      );
    } catch (e) {
      if (e.toString().contains('409')) {
        throw Exception('Ya existe otra categoría con ese nombre');
      }
      print('❌ Error al actualizar categoría: $e');
      rethrow;
    }
  }

  // ==========================================
  // ELIMINAR CATEGORÍA
  // ==========================================

  // Eliminar categoría
  Future<void> eliminarCategoria(BuildContext context, int id) async {
    try {
      await _apiService.delete(
        context,
        '/api/categorias/$id',
      );
    } catch (e) {
      
      if (e.toString().contains('400')) {
        throw Exception('No se puede eliminar: La categoría está siendo usada por productos');
      }
      if (e.toString().contains('404')) {
        throw Exception('Categoría no encontrada');
      }
      print('❌ Error al eliminar categoría: $e');
      rethrow;
    }
  }
}