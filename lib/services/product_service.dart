import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  // ➕ AGREGAR PRODUCTO NUEVO
  Future<Map<String, dynamic>> agregarProducto(
    Map<String, dynamic> data,
    File? archivoPDF,
  ) async {
    try {
      final uri = Uri.parse('${_apiService.baseUrl}/api/productos');
      var request = http.MultipartRequest('POST', uri);

      final headers = await _apiService.headers(isMultipart: true);
      request.headers.addAll(headers);

      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (archivoPDF != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'documento',
          archivoPDF.path,
          contentType: MediaType('application', 'pdf'),
        ));
      }

      print('📤 Enviando producto NUEVO a: $uri');
      print('📋 Datos: $data');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al agregar producto: $e');
      rethrow;
    }
  }

  // ACTUALIZAR PRODUCTO EXISTENTE
  Future<Map<String, dynamic>> actualizarProducto(
    int idProducto,
    Map<String, dynamic> data,
    File? archivoPDF,
  ) async {
    try {
      final uri = Uri.parse('${_apiService.baseUrl}/api/productos/$idProducto');
      var request = http.MultipartRequest('PUT', uri);

      final headers = await _apiService.headers(isMultipart: true);
      request.headers.addAll(headers);

      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (archivoPDF != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'documento',
          archivoPDF.path,
          contentType: MediaType('application', 'pdf'),
        ));
      }

      print('📤 Actualizando producto ID: $idProducto');
      print('📋 Datos: $data');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al actualizar producto: $e');
      rethrow;
    }
  }

  // LIMINAR PRODUCTO
  Future<Map<String, dynamic>> eliminarProducto(
    BuildContext context, 
    int idProducto
  ) async {
    try {
      print('🗑️ Eliminando producto ID: $idProducto');
      
      final uri = Uri.parse('${_apiService.baseUrl}/api/productos/$idProducto');
      final headers = await _apiService.headers();
      
      final response = await http.delete(
        uri,
        headers: headers,
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      // Considerar exitoso cualquier código 2xx
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Producto eliminado correctamente');
        
        // Intentar parsear la respuesta como JSON
        try {
          return json.decode(response.body);
        } catch (e) {
          // Si no es JSON, devolver un mapa simple
          return {
            'success': true,
            'message': 'Producto eliminado correctamente'
          };
        }
      } else {
        // Manejar errores
        String errorMessage = 'Error desconocido';
        
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? 
                        errorData['error'] ?? 
                        errorData['detalle'] ?? 
                        errorMessage;
        } catch (e) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }

        throw Exception('Error ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('Error al eliminar producto: $e');
      rethrow;
    }
  }

  // OBTENER TODOS LOS PRODUCTOS
  Future<List<dynamic>> obtenerProductos(BuildContext context) async {
    try {
      final response = await _apiService.get(context, '/api/productos');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener productos: $e');
      rethrow;
    }
  }

  // OBTENER PRODUCTO POR ID
  Future<Map<String, dynamic>> obtenerProductoPorId(
    BuildContext context,
    int idProducto,
  ) async {
    try {
      final response = await _apiService.get(
        context,
        '/api/productos/$idProducto',
      );
      return response;
    } catch (e) {
      print('Error al obtener producto: $e');
      rethrow;
    }
  }
}