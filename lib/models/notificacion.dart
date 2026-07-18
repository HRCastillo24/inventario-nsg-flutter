import 'dart:convert';
import 'package:flutter/material.dart';

class Notificacion {
  final int idNotificacion;
  final int? idUsuario;
  final int? idSolicitud;
  final String tipoNotificacion;
  final String rolDestinatario;
  final String mensajeNotificacion;
  final DateTime fechaNotificacion;
  final bool leido;
  final String colorNotificacion;
  final String tipoBadge;
  
  // Datos adicionales si es solicitud
  final String? estadoCambio;
  final Map<String, dynamic>? productoData;
  final String? nombreSolicitante;
  final String? correoSolicitante;

  Notificacion({
    required this.idNotificacion,
    this.idUsuario,
    this.idSolicitud,
    required this.tipoNotificacion,
    required this.rolDestinatario,
    required this.mensajeNotificacion,
    required this.fechaNotificacion,
    required this.leido,
    required this.colorNotificacion,
    required this.tipoBadge,
    this.estadoCambio,
    this.productoData,
    this.nombreSolicitante,
    this.correoSolicitante,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      idNotificacion: json['id_notificacion'],
      idUsuario: json['id_usuario'],
      idSolicitud: json['id_solicitud'],
      tipoNotificacion: json['tipo_notificacion'] ?? '',
      rolDestinatario: json['rol_destinatario'] ?? 'ambos',
      mensajeNotificacion: json['mensaje_notificacion'] ?? '',
      fechaNotificacion: DateTime.parse(json['fecha_notificacion']),
      leido: json['leido'] == 1 || json['leido'] == true,
      colorNotificacion: json['color_notificacion'] ?? '#757575',
      tipoBadge: json['tipo_badge'] ?? 'default',
      estadoCambio: json['estado_cambio'],
      productoData: json['producto_data'] != null
          ? (json['producto_data'] is String
              ? _parseJsonString(json['producto_data'])
              : json['producto_data'])
          : null,
      nombreSolicitante: json['nombre_solicitante'],
      correoSolicitante: json['correo_solicitante'],
    );
  }

  static Map<String, dynamic>? _parseJsonString(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      print('Error parsing JSON: $e');
      return null;
    }
  }

  String getIconEmoji() {
    switch (tipoNotificacion) {
      case 'bajo_stock':
        return '⚠️';
      case 'ausencia':
        return '❌';
      case 'solicitud_cambio':
        return '📋';
      case 'aprobacion':
        return '✅';
      case 'rechazo':
        return '❌';
      case 'movimiento':
        return '📦';
      default:
        return '📢';
    }
  }

  Color getColor() {
    try {
      return Color(int.parse(colorNotificacion.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}