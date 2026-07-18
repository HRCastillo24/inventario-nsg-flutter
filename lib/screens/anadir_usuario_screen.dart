import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

class AnadirUsuarioScreen extends StatefulWidget {
  const AnadirUsuarioScreen({Key? key}) : super(key: key);

  @override
  State<AnadirUsuarioScreen> createState() => _AnadirUsuarioScreenState();
}

class _AnadirUsuarioScreenState extends State<AnadirUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  String _rolSeleccionado = 'trabajador';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String _generarPasswordSeguro() {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#\$%&*';
    final random = List.generate(
      12, 
      (index) => caracteres[(DateTime.now().microsecondsSinceEpoch * (index + 1)) % caracteres.length]
    );
    return random.join();
  }

  void _generarPassword() {
    final password = _generarPasswordSeguro();
    setState(() {
      _passwordController.text = password;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Contraseña generada automáticamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _validarDominioCorreo(String email) {
    if (!email.contains('@')) return false;
    
    final partes = email.split('@');
    if (partes.length != 2) return false;
    
    final dominio = partes[1];
    
    if (!dominio.contains('.')) return false;
    
    final extension = dominio.split('.').last;
    if (extension.length < 2) return false;
    
    return true;
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = _correoController.text.trim();
    if (!_validarDominioCorreo(correo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ El dominio del correo parece inválido. Verifica que esté bien escrito.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final userService = UserService(apiService);
      
      final data = {
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'password': _passwordController.text.trim(),
        'rol': _rolSeleccionado,
        'telefono': _telefonoController.text.trim().isNotEmpty 
            ? _telefonoController.text.trim() 
            : null,
      };

      final response = await userService.crearUsuario(context, data);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Usuario Creado')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El usuario ha sido creado exitosamente.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📧 Correo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SelectableText(
                        _correoController.text,
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '🔑 Contraseña:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SelectableText(
                        _passwordController.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Guarda estas credenciales en un lugar seguro',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                if (response['notificacion_enviada'] == true)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Se envió notificación por correo al usuario',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: 'Usuario: ${_correoController.text}\nContraseña: ${_passwordController.text}'
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Credenciales copiadas al portapapeles'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: Icon(Icons.copy),
              label: Text('Copiar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Limpiar formulario
                _nombreController.clear();
                _correoController.clear();
                _passwordController.clear();
                _telefonoController.clear();
                setState(() {
                  _rolSeleccionado = 'trabajador';
                });
              },
              child: Text('Cerrar'),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      String mensajeError = e.toString();
      
      if (mensajeError.contains('dominio') || 
          mensajeError.contains('servidores de correo') ||
          mensajeError.contains('no existe')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('Correo No Válido')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('El correo ingresado no puede recibir mensajes:'),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mensajeError.replaceAll('Exception:', '').trim(),
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '✅ Verifica que:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text('• El correo esté escrito correctamente'),
                  Text('• El dominio exista (ej: @gmail.com)'),
                  Text('• No haya espacios o caracteres especiales'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Entendido'),
              ),
            ],
          ),
        );
      } else if (mensajeError.contains('ya está registrado') || 
                 mensajeError.contains('409')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Este correo ya está registrado en el sistema'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${mensajeError.replaceAll("Exception:", "").trim()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // NAVEGAR A LA LISTA DE USUARIOS
  void _verListaUsuarios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ListaUsuariosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Añadir Usuario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // BOTÓN PARA VER LISTA DE USUARIOS
          IconButton(
            onPressed: _verListaUsuarios,
            icon: Icon(Icons.people),
            tooltip: 'Ver lista de usuarios',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alerta informativa
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El usuario podrá iniciar sesión inmediatamente',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Nombre
              const Text(
                'Nombre completo *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej: Juan Pérez',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Correo
              const Text(
                'Correo electrónico *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Ej: juan@gmail.com',
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: _correoController.text.isNotEmpty
                      ? Icon(
                          _validarDominioCorreo(_correoController.text)
                              ? Icons.check_circle
                              : Icons.error,
                          color: _validarDominioCorreo(_correoController.text)
                              ? Colors.green
                              : Colors.red,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo es obligatorio';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Correo inválido';
                  }
                  if (!_validarDominioCorreo(value)) {
                    return 'El dominio del correo es inválido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Text(
                '💡 Usa correos válidos (@gmail.com, @outlook.com, etc.)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Teléfono (opcional)
              const Text(
                'Teléfono (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Ej: +51 999 999 999',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),

              // Contraseña
              const Text(
                'Contraseña *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _generarPassword,
                        tooltip: 'Generar contraseña automática',
                      ),
                      IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es obligatoria';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Text(
                '🔄 Presiona el ícono para generar una contraseña segura automáticamente',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Rol
              const Text(
                'Rol *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _rolSeleccionado,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(
                        value: 'trabajador',
                        child: Row(
                          children: [
                            Icon(Icons.work, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Trabajador'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'gerente',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.orange),
                            SizedBox(width: 12),
                            Text('Gerente'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _rolSeleccionado = value!);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Botón crear
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PANTALLA DE LISTA DE USUARIOS
class ListaUsuariosScreen extends StatefulWidget {
  const ListaUsuariosScreen({Key? key}) : super(key: key);

  @override
  State<ListaUsuariosScreen> createState() => _ListaUsuariosScreenState();
}

class _ListaUsuariosScreenState extends State<ListaUsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final userService = UserService(apiService);
      
      final usuarios = await userService.obtenerUsuarios(context);
      
      if (mounted) {
        setState(() {
          _usuarios = usuarios;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: ${e.toString().replaceAll("Exception:", "").trim()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarUsuario(String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text('Confirmar eliminación')),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar al usuario "$nombre"?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final userService = UserService(apiService);
      
      await userService.eliminarUsuario(context, id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Usuario eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarUsuarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception:", "").trim()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUserCard(dynamic usuario) {
    final rol = usuario['rol'] ?? 'trabajador';
    final estado = usuario['estado'] ?? 'activo';
    final verificado = usuario['email_verificado'] == 1 || usuario['email_verificado'] == true;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: rol == 'gerente' ? Colors.orange.shade100 : Colors.blue.shade100,
          child: Icon(
            rol == 'gerente' ? Icons.admin_panel_settings : Icons.person,
            color: rol == 'gerente' ? Colors.orange : Colors.blue,
          ),
        ),
        title: Text(
          usuario['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              usuario['correo'] ?? 'Sin correo',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rol == 'gerente' ? Colors.orange.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rol == 'gerente' ? 'Gerente' : 'Trabajador',
                    style: TextStyle(
                      fontSize: 12,
                      color: rol == 'gerente' ? Colors.orange.shade900 : Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                if (!verificado)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Sin verificar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (estado != 'activo')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _eliminarUsuario(
            usuario['id']?.toString() ?? '',
            usuario['nombre'] ?? 'Usuario',
          ),
          tooltip: 'Eliminar usuario',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Usuarios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay usuarios registrados',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarUsuarios,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Total de usuarios: ${_usuarios.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      ..._usuarios.map((usuario) => _buildUserCard(usuario)).toList(),
                    ],
                  ),
                ),
    );
  }
}