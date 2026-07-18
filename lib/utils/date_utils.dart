import 'package:intl/intl.dart';

/// Utilidades para manejar y formatear fechas y horas
class DateUtilsCustom {
  /// Fecha completa
  static String formatearFechaHora(DateTime fecha) {
    final localFecha = fecha.toLocal();
    final formato = DateFormat("d 'de' MMMM 'de' y – HH:mm 'h'", 'es_ES');
    return formato.format(localFecha);
  }

  /// Formatea solo la fecha
  static String formatearSoloFecha(DateTime fecha) {
    final localFecha = fecha.toLocal();
    final formato = DateFormat('dd/MM/yyyy', 'es_ES');
    return formato.format(localFecha);
  }

  /// Formatea solo la hora
  static String formatearHora(DateTime fecha) {
    final localFecha = fecha.toLocal();
    final formato = DateFormat('HH:mm', 'es_ES');
    return "${formato.format(localFecha)} h";
  }

  /// Convierte un String (ISO o timestamp) a DateTime
  static DateTime? parsearStringAFecha(String? texto) {
    if (texto == null || texto.isEmpty) return null;
    try {
      return DateTime.parse(texto).toLocal();
    } catch (_) {
      return null;
    }
  }

  ///  Devuelve la diferencia entre dos fechas en formato legible
  static String tiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) return "justo ahora";
    if (diferencia.inMinutes < 60) return "hace ${diferencia.inMinutes} min";
    if (diferencia.inHours < 24) return "hace ${diferencia.inHours} h";
    if (diferencia.inDays < 7) return "hace ${diferencia.inDays} días";

    // Si ya pasó más de una semana, mostramos la fecha normal
    return formatearSoloFecha(fecha);
  }

  /// Formatea fecha relativa para notificaciones 
  static String formatearFechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'Hace ${diferencia.inSeconds}s';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes}m';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays}d';
    } else {
      return formatearSoloFecha(fecha);
    }
  }
}