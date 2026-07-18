import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movimiento.dart';

class MovimientoService {
  // URL base de tu backend
  static const String baseUrl = 'https://nsglatinoamerica.duckdns.org/api/movimientos';

  // ==================================================
  // OBTENER TODOS LOS MOVIMIENTOS
  // ==================================================
  Future<List<Movimiento>> obtenerTodosLosMovimientos() async {
    try {
      final url = Uri.parse(baseUrl);
      print('🔍 Llamando a: $url'); // Debug
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      print('📡 Status Code: ${response.statusCode}'); // Debug
      print('📄 Response Body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movimiento.fromJson(json)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('❌ Error en obtenerTodosLosMovimientos: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================================================
  // OBTENER MOVIMIENTOS POR PRODUCTO
  // ==================================================
  Future<List<Movimiento>> obtenerMovimientosPorProducto(int idProducto) async {
    try {
      final url = Uri.parse('$baseUrl/producto/$idProducto');
      print('🔍 Llamando a: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movimiento.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener movimientos del producto');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================================================
  // OBTENER MOVIMIENTOS POR RANGO DE FECHAS
  // ==================================================
  Future<List<Movimiento>> obtenerMovimientosPorFecha({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final inicio = '${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}';
      final fin = '${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}';
      
      final url = Uri.parse('$baseUrl/fecha?inicio=$inicio&fin=$fin');
      print('🔍 Llamando a: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movimiento.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener movimientos por fecha');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================================================
  // OBTENER MOVIMIENTOS POR TIPO
  // ==================================================
  Future<List<Movimiento>> obtenerMovimientosPorTipo(String tipo) async {
    try {
      // Validar tipo
      if (!['entrada', 'salida', 'cambio'].contains(tipo.toLowerCase())) {
        throw Exception('Tipo de movimiento inválido');
      }

      final url = Uri.parse('$baseUrl/tipo/${tipo.toLowerCase()}');
      print('🔍 Llamando a: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movimiento.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener movimientos por tipo');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================================================
  // OBTENER ESTADÍSTICAS DE MOVIMIENTOS
  // ==================================================
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final url = Uri.parse('$baseUrl/estadisticas');
      print('🔍 Llamando a: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Convertir el array de estadísticas en un mapa
        Map<String, dynamic> stats = {};
        for (var item in data) {
          stats[item['tipo_movimiento']] = {
            'total_movimientos': item['total_movimientos'],
            'total_cantidad': item['total_cantidad'],
            'ultimo_movimiento': item['ultimo_movimiento'],
          };
        }
        
        return stats;
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerEstadisticas: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================================================
  // CREAR MOVIMIENTO MANUAL
  // ==================================================
  Future<bool> crearMovimiento({
    required int idProducto,
    required String tipoMovimiento,
    required int cantidadMovimiento,
    int? idUsuario,
  }) async {
    try {
      final url = Uri.parse(baseUrl);
      print('🔍 Creando movimiento en: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'id_producto': idProducto,
          'tipo_movimiento': tipoMovimiento.toLowerCase(),
          'cantidad_movimiento': cantidadMovimiento,
          'id_usuario': idUsuario,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error al crear movimiento: $e');
      throw Exception('Error al crear movimiento: $e');
    }
  }

  // ==================================================
  //  OBTENER MOVIMIENTOS DE HOY
  // ==================================================
  Future<List<Movimiento>> obtenerMovimientosDeHoy() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    
    return await obtenerMovimientosPorFecha(
      fechaInicio: inicio,
      fechaFin: fin,
    );
  }

  // ==================================================
  //  OBTENER MOVIMIENTOS DE LA ÚLTIMA SEMANA
  // ==================================================
  Future<List<Movimiento>> obtenerMovimientosSemana() async {
    final hoy = DateTime.now();
    final hace7Dias = hoy.subtract(const Duration(days: 7));
    
    return await obtenerMovimientosPorFecha(
      fechaInicio: hace7Dias,
      fechaFin: hoy,
    );
  }

  // ==================================================
  // VERIFICAR CONEXIÓN AL SERVIDOR
  // ==================================================
  Future<bool> verificarConexion() async {
    try {
      final url = Uri.parse(baseUrl);
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error de conexión: $e');
      return false;
    }
  }
}