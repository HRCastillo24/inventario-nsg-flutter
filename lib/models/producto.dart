class Producto {
  final int? id;
  final String nombre;
  final String documento;
  final String codigo;
  final double precioCompra;
  final double precioVenta;
  final double tipoCambio;
  final double utilidad;
  final double margen;
  final DateTime fechaIngreso;
  final String? archivoPdf;

  // IDs de categorías (lo que se envía al backend)
  final int? tipoId;
  final int? marcaId;
  
  // Nombres de categorías (lo que viene del JOIN del backend)
  final String? nombreTipo;
  final String? nombreMarca;

  final int cantidad;
  final int stockMinimo;
  final String ubicacion;

  Producto({
    this.id,
    required this.nombre,
    required this.documento,
    required this.codigo,
    required this.precioCompra,
    required this.precioVenta,
    required this.tipoCambio,
    required this.utilidad,
    required this.margen,
    required this.fechaIngreso,
    this.archivoPdf,
    this.tipoId,
    this.marcaId,
    this.nombreTipo,
    this.nombreMarca,
    required this.cantidad,
    required this.stockMinimo,
    required this.ubicacion,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id_producto': id,
      'nombre_producto': nombre,
      'documento_producto': documento,
      'codigo': codigo,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'tipo': tipoId,
      'marca': marcaId,
      'cantidad': cantidad,
      'stock_minimo': stockMinimo,
      'ubicacion': ubicacion,
      if (archivoPdf != null) 'documento_url': archivoPdf,
    };
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id_producto'],
      nombre: json['nombre_producto'] ?? '',
      documento: json['documento_producto'] ?? '',
      codigo: json['codigo'] ?? '',
      precioCompra: (json['precio_compra'] as num?)?.toDouble() ?? 0,
      precioVenta: (json['precio_venta'] as num?)?.toDouble() ?? 0,
      tipoCambio: 0,
      utilidad: 0,
      margen: 0,
      fechaIngreso: DateTime.tryParse(json['fecha_ingreso'] ?? '') ?? DateTime.now(),
      archivoPdf: json['documento_url'],
      tipoId: json['tipo'],           
      marcaId: json['marca'],           
      nombreTipo: json['nombre_tipo'], 
      nombreMarca: json['nombre_marca'],
      cantidad: json['cantidad'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? 0,
      ubicacion: json['ubicacion'] ?? '',
    );
  }
}