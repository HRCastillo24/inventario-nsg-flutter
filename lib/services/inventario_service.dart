import 'package:flutter/material.dart';
import 'api_service.dart';

class InventarioService {
  final ApiService _apiService;

  InventarioService(this._apiService);

  // Obtener todos los productos
  Future<List<dynamic>> getProductos(BuildContext context) async {
    try {
      final response = await _apiService.get(context, "/api/productos");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error al obtener productos: $e");
      rethrow;
    }
  }

  // Obtener productos con bajo stock
  Future<List<dynamic>> getBajoStock(BuildContext context) async {
    try {
      final response = await _apiService.get(context, "/api/productos/bajo-stock");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error al obtener bajo stock: $e");
      rethrow;
    }
  }

  // Actualizar stock automáticamente (entrada o salida)
  Future<Map<String, dynamic>> actualizarStock(
      BuildContext context, String codigo, String tipo, int cantidad) async {
    try {
      final response = await _apiService.post(
        context,
        "/api/productos/stock/$codigo",
        {"tipo": tipo, "cantidad": cantidad},
      );
      return response;
    } catch (e) {
      debugPrint("❌ Error al actualizar stock: $e");
      rethrow;
    }
  }

  // Obtener movimientos de inventario
  Future<List<dynamic>> getMovimientos(BuildContext context) async {
    try {
      final response = await _apiService.get(context, "/api/movimientos");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error al obtener movimientos: $e");
      rethrow;
    }
  }

  // Eliminar producto
  Future<void> deleteProducto(int id, BuildContext context) async {
    try {
      await _apiService.delete(context, "/api/productos/$id");
      debugPrint("✅ Producto eliminado correctamente: ID $id");
    } catch (e) {
      debugPrint("❌ Error al eliminar producto: $e");
      rethrow;
    }
  }

  // Crear producto
  Future<Map<String, dynamic>> addProducto(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(context, "/api/productos", data);
      return response;
    } catch (e) {
      debugPrint("❌ Error al agregar producto: $e");
      rethrow;
    }
  }

  // Actualizar producto
  Future<Map<String, dynamic>> updateProducto(
      BuildContext context, int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(context, "/api/productos/$id", data);
      return response;
    } catch (e) {
      debugPrint("❌ Error al actualizar producto: $e");
      rethrow;
    }
  }
}
