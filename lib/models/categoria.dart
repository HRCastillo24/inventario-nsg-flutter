class Categoria {
  final int id;
  final String nombre;
  final String tipo; // 'tipo' o 'marca'
  final String? descripcion;
  final String estado;
  final DateTime fechaCreacion;

  Categoria({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    required this.estado,
    required this.fechaCreacion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id_categoria'],
      nombre: json['nombre_categoria'],
      tipo: json['tipo_categoria'],
      descripcion: json['descripcion'],
      estado: json['estado_categoria'] ?? 'activa',
      fechaCreacion: DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_categoria': nombre,
      'tipo_categoria': tipo,
      'descripcion': descripcion,
      'estado_categoria': estado,
    };
  }
}