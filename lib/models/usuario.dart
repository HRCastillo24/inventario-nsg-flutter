class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'trabajador',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'nombre': nombre,
        'correo': correo,
        'rol': rol,
      };
}
