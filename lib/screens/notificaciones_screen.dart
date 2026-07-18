import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/notificacion.dart';
import '../services/notification_service.dart';
import '../widgets/notificacion_tile.dart';
import '../providers/auth_provider.dart';
import 'solicitudpendiente.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({Key? key}) : super(key: key);

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Notificacion> _notificaciones = [];
  bool _isLoading = true;
  Timer? _timer;
  int _contadorNoLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
    _iniciarActualizacionAutomatica();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarActualizacionAutomatica() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cargarNotificaciones(silencioso: true);
    });
  }

  Future<void> _actualizarContador() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usuario = authProvider.usuario;
      if (usuario == null) return;

      final usuarioId = int.parse(usuario.id);
      final resultado = await _notificationService.obtenerContadorNoLeidas(
        usuario.rol,
        usuarioId,
      );

      if (mounted) {
        setState(() {
          _contadorNoLeidas = resultado['total'] ?? 0;
        });
      }

      print('Contador actualizado: $_contadorNoLeidas');
    } catch (e) {
      print('❌ Error al actualizar contador: $e');
    }
  }

  Future<void> _cargarNotificaciones({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() => _isLoading = true);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usuario = authProvider.usuario;

      if (usuario == null) {
        throw Exception('Usuario no autenticado');
      }

      final usuarioId = int.parse(usuario.id);

      final notificaciones = await _notificationService.obtenerNotificaciones(
        usuario.rol,
        usuarioId,
      );

      final contador = await _notificationService.obtenerContadorNoLeidas(
        usuario.rol,
        usuarioId,
      );

      if (mounted) {
        setState(() {
          _notificaciones = notificaciones;
          _contadorNoLeidas = contador['total'] ?? 0;
          _isLoading = false;
        });
      }

      print('Notificaciones cargadas: ${notificaciones.length}');
      print('Contador no leídas: $_contadorNoLeidas');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notificaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final usuario = authProvider.usuario;
    if (usuario == null) return;

    final usuarioId = int.parse(usuario.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _notificationService.marcarTodasComoLeidas(
        usuario.rol,
        usuarioId,
      );

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        await _cargarNotificaciones();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Todas marcadas como leídas'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleNotificacionTap(Notificacion notificacion) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final usuario = authProvider.usuario;

    await _notificationService.marcarComoLeida(notificacion.idNotificacion);
    await _actualizarContador();

    if (notificacion.tipoNotificacion == 'solicitud_cambio' && 
        notificacion.idSolicitud != null &&
        usuario?.rol == 'gerente') {
      
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SolicitudPendienteScreen(
            idSolicitud: notificacion.idSolicitud!,
            productoData: notificacion.productoData,
          ),
        ),
      );

      if (resultado == true) _cargarNotificaciones();
    } 
    else if (notificacion.tipoNotificacion == 'aprobacion' || 
             notificacion.tipoNotificacion == 'rechazo') {
      _mostrarDetalleRespuesta(notificacion);
    }
    else if (notificacion.tipoNotificacion == 'bajo_stock') {
      Navigator.pushNamed(context, '/bajo_stock');
    }
    else if (notificacion.tipoNotificacion == 'ausencia') {
      _mostrarDialogoAusencia(notificacion);
    }

    _cargarNotificaciones();
  }


  void _mostrarDetalleRespuesta(Notificacion notificacion) {
    final esAprobacion = notificacion.tipoNotificacion == 'aprobacion';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: esAprobacion 
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      esAprobacion ? Icons.check_circle : Icons.cancel,
                      color: esAprobacion ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        esAprobacion ? 'Solicitud Aprobada' : 'Solicitud Rechazada',
                        style: TextStyle(
                          color: esAprobacion ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // CONTENIDO SCROLLABLE
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacion.mensajeNotificacion,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                      
                      if (notificacion.productoData != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildProductoInfo(notificacion.productoData!),
                      ],
                    ],
                  ),
                ),
              ),

              // BOTONES
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    if (esAprobacion) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/inventario');
                        },
                        icon: const Icon(Icons.inventory_2, size: 18),
                        label: const Text('Ver Inventario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _mostrarDialogoAusencia(Notificacion notificacion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.person_off, color: Colors.red, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Alerta de Ausencia',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // CONTENIDO SCROLLABLE
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacion.mensajeNotificacion,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Por favor, revisa el inventario y tus solicitudes pendientes.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // BOTONES
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/inventario');
                      },
                      icon: const Icon(Icons.inventory_2, size: 18),
                      label: const Text('Ver Inventario'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductoInfo(Map<String, dynamic> productoData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles del Producto:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _infoRow('Nombre', productoData['nombre_producto'] ?? 'N/A'),
        _infoRow('Código', productoData['codigo'] ?? 'N/A'),
        _infoRow('Marca', productoData['marca'] ?? 'N/A'),
        _infoRow('Cantidad', productoData['cantidad']?.toString() ?? '0'),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarNotificacion(Notificacion notificacion) async {
    final success = await _notificationService.eliminarNotificacion(
      notificacion.idNotificacion,
    );

    if (success && mounted) {
      await _actualizarContador();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text('🗑️ Notificación eliminada'),
            ],
          ),
        ),
      );
      _cargarNotificaciones();
    }
  }

  Widget _buildNotificacionesPorTipo(
    String tipo, 
    List<Notificacion> notificaciones, 
    String rol
  ) {
    final notifsTipo = notificaciones
        .where((n) => n.tipoNotificacion == tipo)
        .toList();
    
    if (notifsTipo.isEmpty) return const SizedBox.shrink();

    String titulo = '';
    IconData icono = Icons.notifications;
    Color color = Colors.grey;

    switch (tipo) {
      case 'bajo_stock':
        titulo = 'Stock Bajo';
        icono = Icons.inventory_2;
        color = Colors.orange;
        break;
      case 'ausencia':
        titulo = 'Ausencias';
        icono = Icons.person_off;
        color = Colors.red;
        break;
      case 'solicitud_cambio':
        titulo = 'Solicitudes de Revisión';
        icono = Icons.assignment;
        color = Colors.blue;
        break;
      case 'aprobacion':
        titulo = 'Aprobaciones';
        icono = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rechazo':
        titulo = 'Rechazos';
        icono = Icons.cancel;
        color = Colors.red;
        break;
      case 'movimiento':
        titulo = 'Movimientos';
        icono = Icons.swap_horiz;
        color = Colors.purple;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifsTipo.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...notifsTipo.map((notif) => NotificacionTile(
          notificacion: notif,
          onTap: () => _handleNotificacionTap(notif),
          onDismiss: () => _eliminarNotificacion(notif),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usuario = authProvider.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_contadorNoLeidas > 0) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_contadorNoLeidas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _marcarTodasComoLeidas,
              tooltip: 'Marcar todas como leídas',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargarNotificaciones(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando notificaciones...'),
                ],
              ),
            )
          : _notificaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes notificaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Te avisaremos cuando haya algo nuevo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _cargarNotificaciones(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (usuario?.rol == 'gerente') ...[
                        _buildNotificacionesPorTipo(
                          'solicitud_cambio', 
                          _notificaciones, 
                          usuario!.rol
                        ),
                        _buildNotificacionesPorTipo(
                          'movimiento', 
                          _notificaciones, 
                          usuario.rol
                        ),
                      ],
                      
                      _buildNotificacionesPorTipo(
                        'bajo_stock', 
                        _notificaciones, 
                        usuario?.rol ?? ''
                      ),
                      _buildNotificacionesPorTipo(
                        'ausencia', 
                        _notificaciones, 
                        usuario?.rol ?? ''
                      ),
                      
                      if (usuario?.rol == 'trabajador') ...[
                        _buildNotificacionesPorTipo(
                          'aprobacion', 
                          _notificaciones, 
                          usuario!.rol
                        ),
                        _buildNotificacionesPorTipo(
                          'rechazo', 
                          _notificaciones, 
                          usuario.rol
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}