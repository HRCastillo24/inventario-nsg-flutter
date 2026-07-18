class Movimiento {
  final int idMovimiento;
  final int? idProducto;
  final String tipoMovimiento; // 'entrada', 'salida', 'cambio', 'solicitud', 'aprobacion', 'rechazo'
  final int cantidadMovimiento;
  final DateTime fechaMovimiento;
  final int? idUsuario;
  final int? idSolicitud;
  final String? descripcion;
  final String? nombreProducto;
  final String? codigo;
  final String? marca;
  final String? tipo;
  final String? nombreUsuario;
  final String? correoUsuario;
  final String? tipoSolicitud;
  final String? estadoSolicitud;

  Movimiento({
    required this.idMovimiento,
    this.idProducto,
    required this.tipoMovimiento,
    required this.cantidadMovimiento,
    required this.fechaMovimiento,
    this.idUsuario,
    this.idSolicitud,
    this.descripcion,
    this.nombreProducto,
    this.codigo,
    this.marca,
    this.tipo,
    this.nombreUsuario,
    this.correoUsuario,
    this.tipoSolicitud,
    this.estadoSolicitud,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      idMovimiento: json['id_movimiento'] ?? 0,
      idProducto: json['id_producto'],
      tipoMovimiento: json['tipo_movimiento'] ?? '',
      cantidadMovimiento: json['cantidad_movimiento'] ?? 0,
      fechaMovimiento: json['fecha_movimiento'] != null
          ? DateTime.parse(json['fecha_movimiento'])
          : DateTime.now(),
      idUsuario: json['id_usuario'],
      idSolicitud: json['id_solicitud'],
      descripcion: json['descripcion'],
      nombreProducto: json['nombre_producto'],
      codigo: json['codigo'],
      marca: json['marca'],
      tipo: json['tipo'],
      nombreUsuario: json['nombre_usuario'],
      correoUsuario: json['correo_usuario'],
      tipoSolicitud: json['tipo_solicitud'],
      estadoSolicitud: json['estado_solicitud'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'tipo_movimiento': tipoMovimiento,
      'cantidad_movimiento': cantidadMovimiento,
      'id_usuario': idUsuario,
      'descripcion': descripcion,
    };
  }

  // Obtener icono según tipo
  String getIcono() {
    switch (tipoMovimiento.toLowerCase()) {
      case 'entrada':
        return '📥';
      case 'salida':
        return '📤';
      case 'cambio':
        return '✏️';
      case 'solicitud':
        return '📩';
      case 'aprobacion':
        return '✅';
      case 'rechazo':
        return '❌';
      default:
        return '📋';
    }
  }

  // Obtener color
  String getColorHex() {
    switch (tipoMovimiento.toLowerCase()) {
      case 'entrada':
        return '4CAF50'; // Verde
      case 'salida':
        return 'F44336'; // Rojo
      case 'cambio':
        return 'FF9800'; // Naranja
      case 'solicitud':
        return '2196F3'; // Azul
      case 'aprobacion':
        return '4CAF50'; // Verde
      case 'rechazo':
        return 'F44336'; // Rojo
      default:
        return '9E9E9E';
    }
  }

  // Descripción legible
  String getDescripcion() {
    switch (tipoMovimiento.toLowerCase()) {
      case 'entrada':
        return 'Ingreso de producto';
      case 'salida':
        return 'Venta realizada';
      case 'cambio':
        return 'Producto modificado';
      case 'solicitud':
        return 'Solicitud de revisión';
      case 'aprobacion':
        return 'Solicitud aprobada';
      case 'rechazo':
        return 'Solicitud rechazada';
      default:
        return 'Movimiento registrado';
    }
  }

  // Formato de fecha MEJORADO
  String getFechaFormateada() {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaMovimiento);

    if (diferencia.inDays == 0) {
      // Mismo día
      if (diferencia.inHours == 0) {
        if (diferencia.inMinutes == 0) {
          return 'Hace un momento';
        }
        return 'Hace ${diferencia.inMinutes} min';
      }
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays == 1) {
      // Ayer
      return 'Ayer';
    } else if (diferencia.inDays <= 3) {
      // Hace 2-3 días
      return 'Hace ${diferencia.inDays} días';
    } else {
      // 4 días o más → Mostrar fecha completa
      final meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      final dia = fechaMovimiento.day.toString().padLeft(2, '0');
      final mes = meses[fechaMovimiento.month - 1];
      final anio = fechaMovimiento.year;
      
      return '$dia $mes $anio';
    }
  }

  String getFechaCompletaFormateada() {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    final dia = fechaMovimiento.day.toString().padLeft(2, '0');
    final mes = meses[fechaMovimiento.month - 1];
    final anio = fechaMovimiento.year;
    final hora = fechaMovimiento.hour.toString().padLeft(2, '0');
    final minuto = fechaMovimiento.minute.toString().padLeft(2, '0');
    
    return '$dia $mes $anio - $hora:$minuto';
  }
}