import 'package:flutter/material.dart';
import 'api_service.dart';

class VentaService {
  final ApiService _api;

  VentaService(this._api);

  // Observaciones en cada producto
  Future<void> registrarVenta(
    BuildContext context, {
    required int idUsuario,
    required String fechaVenta,
    required double descuento,
    required double igv,
    required String metodoPago,
    required List<Map<String, dynamic>> productos,
  }) async {
    final body = {
      "id_usuario": idUsuario,
      "fecha_venta": fechaVenta,
      "descuento": descuento,
      "igv": igv,
      "metodo_pago": metodoPago,
      "productos": productos, 
    };

    await _api.post(context, "/api/ventas", body);
  }

  Future<List<dynamic>> getVentas(BuildContext context) async {
    final response = await _api.get(context, "/api/ventas");
    if (response is List) return response;
    if (response is Map && response.containsKey('ventas')) return response['ventas'];
    return [];
  }

  Future<Map<String, dynamic>?> getVentaById(BuildContext context, int id) async {
    final response = await _api.get(context, "/api/ventas/$id");
    return response as Map<String, dynamic>?;
  }

  Future<void> deleteVenta(BuildContext context, int id) async {
    await _api.delete(context, "/api/ventas/$id");
  }
}