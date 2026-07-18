import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl;
  final _storage = const FlutterSecureStorage();

  ApiService({required this.baseUrl});

  // Leer token JWT almacenado
  Future<String?> _getToken() async => await _storage.read(key: 'jwt_token');

  // Cabeceras dinámicas
  Future<Map<String, String>> _headers({bool isMultipart = false}) async {
    final token = await _getToken();
    final headers = <String, String>{};

    if (!isMultipart) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';

    return headers;
  }

  // Cabeceras públicas
  Future<Map<String, String>> headers({bool isMultipart = false}) async {
    return _headers(isMultipart: isMultipart);
  }

  // GET
  Future<dynamic> get(BuildContext context, String path) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.get(uri, headers: headers);
      return _handleResponse(context, response);
    } on SocketException {
      throw Exception('No hay conexión con el servidor.');
    } catch (e) {
      throw Exception('Error en la solicitud GET: $e');
    }
  }

  // POST
  Future<dynamic> post(BuildContext context, String path, Map<String, dynamic> data) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(data));
      return _handleResponse(context, response);
    } on SocketException {
      throw Exception('No hay conexión con el servidor.');
    } catch (e) {
      throw Exception('Error en la solicitud POST: $e');
    }
  }

  // PUT
  Future<dynamic> put(BuildContext context, String path, Map<String, dynamic> data) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.put(uri, headers: headers, body: jsonEncode(data));
      return _handleResponse(context, response);
    } on SocketException {
      throw Exception('No hay conexión con el servidor.');
    } catch (e) {
      throw Exception('Error en la solicitud PUT: $e');
    }
  }

  // DELETE
  Future<dynamic> delete(BuildContext context, String path) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.delete(uri, headers: headers);
      return _handleResponse(context, response);
    } on SocketException {
      throw Exception('No hay conexión con el servidor.');
    } catch (e) {
      throw Exception('Error en la solicitud DELETE: $e');
    }
  }

  // SUBIR ARCHIVO (PDF, imágenes, etc.)
  Future<dynamic> uploadFile(BuildContext context, String path, File file) async {
    final headers = await _headers(isMultipart: true);
    final uri = Uri.parse('$baseUrl$path');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(context, response);
    } on SocketException {
      throw Exception('No hay conexión con el servidor.');
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  // SUBIR ARCHIVO CON DATOS
  Future<dynamic> uploadFileWithData(
    BuildContext context,
    String path,
    File file,
    Map<String, dynamic> data, {
    String fileFieldName = 'file',
  }) async {
    final headers = await _headers(isMultipart: true);
    final uri = Uri.parse('$baseUrl$path');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath(fileFieldName, file.path))
        ..fields.addAll(data.map((key, value) => MapEntry(key, value.toString())));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(context, response);
    } on SocketException {
      throw Exception('No hay conexión con el servidor.');
    } catch (e) {
      throw Exception('Error al subir archivo con datos: $e');
    }
  }

  // POST 
  Future<dynamic> postWithoutContext(String endpoint, Map<String, dynamic> data) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(data));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en POST sin contexto: $e');
    }
  }

  // PUT
  Future<dynamic> putWithoutContext(String endpoint, Map<String, dynamic> data) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(uri, headers: headers, body: jsonEncode(data));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en PUT sin contexto: $e');
    }
  }

  // Manejo centralizado de respuestas HTTP
  dynamic _handleResponse(BuildContext context, http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      _handleTokenExpired(context);
      throw Exception('Token expirado o inválido.');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // Si el token expiró, borrar y volver al login
  Future<void> _handleTokenExpired(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión ha expirado. Inicia sesión nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}
