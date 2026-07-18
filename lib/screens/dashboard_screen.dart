import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NotificationService _notificationService = NotificationService();
  
  int _contadorNoLeidas = 0;
  Timer? _timer;
  bool _cargando = true;

  Map<String, dynamic> _estadisticas = {};

  @override
  void initState() {
    super.initState();
    _cargarContadorNotificaciones();
    _cargarEstadisticas();
    _iniciarActualizacionAutomatica();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarActualizacionAutomatica() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cargarContadorNotificaciones();
      _cargarEstadisticas();
    });
  }

  Future<void> _cargarContadorNotificaciones() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usuario = authProvider.usuario;

      if (usuario == null) return;

      final usuarioId = int.parse(usuario.id);
      final contador = await _notificationService.obtenerContadorNoLeidas(
        usuario.rol,
        usuarioId,
      );

      if (mounted) {
        setState(() {
          _contadorNoLeidas = contador['total'] ?? 0;
        });
      }
    } catch (e) {
      print('❌ Error al cargar contador de notificaciones: $e');
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final movimientos = await apiService.get(context, '/api/movimientos/estadisticas');
      final productos = await apiService.get(context, '/api/productos');
      final bajoStock = await apiService.get(context, '/api/productos/bajo-stock');

      final List<dynamic> dataMovimientos = movimientos as List<dynamic>;
      final Map<String, int> statsMovimientos = {};
      
      for (var stat in dataMovimientos) {
        final tipo = stat['tipo_movimiento'].toString().toLowerCase();
        final total = stat['total_movimientos'] ?? 0;
        statsMovimientos[tipo] = total;
      }

      final List<dynamic> dataProductos = productos as List<dynamic>;
      final List<dynamic> dataBajoStock = bajoStock as List<dynamic>;

      if (mounted) {
        setState(() {
          _estadisticas = {
            'entradas': statsMovimientos['entrada'] ?? 0,
            'salidas': statsMovimientos['salida'] ?? 0,
            'cambios': statsMovimientos['cambio'] ?? 0,
            'solicitudes': statsMovimientos['solicitud'] ?? 0,
            'aprobadas': statsMovimientos['aprobacion'] ?? 0,
            'rechazadas': statsMovimientos['rechazo'] ?? 0,
            'productosTotal': dataProductos.length,
            'bajoStock': dataBajoStock.length,
          };
          _cargando = false;
        });
      }

      print('✅ Estadísticas cargadas: $_estadisticas');
    } catch (e) {
      print('❌ Error al cargar estadísticas: $e');
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  bool _esGerente(AuthProvider authProvider) {
    return authProvider.usuario?.rol.toLowerCase() == 'gerente';
  }

  // Navegación con actualización automática
  Future<void> _navegarYActualizar(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    _cargarEstadisticas();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final esGerente = _esGerente(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'INICIO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/notificaciones');
                  _cargarContadorNotificaciones();
                },
              ),
              if (_contadorNoLeidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _contadorNoLeidas > 9 ? '9+' : '$_contadorNoLeidas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),

      body: _cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Cargando estadísticas...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _cargarEstadisticas();
                await _cargarContadorNotificaciones();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HISTORIAL DE MOVIMIENTOS
                    _seccionTitulo('Historial de Movimientos'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _tarjetaEstadistica(
                            '${_estadisticas['entradas'] ?? 0}',
                            'Entradas',
                            Icons.add_circle,
                            const Color(0xFFE8F5E9),
                            const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tarjetaEstadistica(
                            '${_estadisticas['salidas'] ?? 0}',
                            'Salidas',
                            Icons.remove_circle,
                            const Color(0xFFFFEBEE),
                            const Color(0xFFF44336),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tarjetaEstadistica(
                            '${_estadisticas['cambios'] ?? 0}',
                            'Cambios',
                            Icons.edit,
                            const Color(0xFFFFF3E0),
                            const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SOLICITUDES
                    _seccionTitulo('Solicitudes'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _tarjetaEstadistica(
                            '${_estadisticas['solicitudes'] ?? 0}',
                            'Pendientes',
                            Icons.hourglass_empty,
                            const Color(0xFFFFF3E0),
                            const Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tarjetaEstadistica(
                            '${_estadisticas['aprobadas'] ?? 0}',
                            'Aprobadas',
                            Icons.check_circle,
                            const Color(0xFFE8F5E9),
                            const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tarjetaEstadistica(
                            '${_estadisticas['rechazadas'] ?? 0}',
                            'Rechazadas',
                            Icons.cancel,
                            const Color(0xFFFFEBEE),
                            const Color(0xFFF44336),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ESTADO DEL INVENTARIO
                    _seccionTitulo('Estado del Inventario'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _tarjetaInventario(
                            '${_estadisticas['productosTotal'] ?? 0}',
                            'Productos Total',
                            Icons.inventory_2,
                            const Color(0xFF2196F3),
                            () => _navegarYActualizar('/inventario'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tarjetaInventario(
                            '${_estadisticas['bajoStock'] ?? 0}',
                            'Bajo Stock',
                            Icons.warning,
                            const Color(0xFFF44336),
                            () => _navegarYActualizar('/bajo_stock'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ACCESOS RÁPIDOS
                    _seccionTitulo('Accesos Rápidos'),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _botonAccesoRapido(
                          Icons.add_box,
                          'Añadir\nProducto',
                          const Color(0xFF2196F3),
                          () => _navegarYActualizar('/anadir_producto'),
                        ),
                        _botonAccesoRapido(
                          Icons.point_of_sale,
                          'Registrar\nVenta',
                          const Color(0xFF4CAF50),
                          () => _navegarYActualizar('/ventas'),
                        ),
                        _botonAccesoRapido(
                          Icons.bar_chart,
                          'Reportes',
                          const Color(0xFF9C27B0),
                          () => _navegarYActualizar('/reportes'),
                        ),
                        _botonAccesoRapido(
                          Icons.category,
                          'Categorías',
                          const Color(0xFF009688),
                          () => _navegarYActualizar('/categorias'),
                        ),
                        if (esGerente)
                          _botonAccesoRapido(
                            Icons.receipt_long,
                            'Gestionar\nVentas',
                            const Color(0xFFE91E63),
                            () => _navegarYActualizar('/gestionar_ventas'),
                          ),
                        if (esGerente)
                          _botonAccesoRapido(
                            Icons.person_add,
                            'Añadir\nUsuario',
                            const Color(0xFFFF5722),
                            () => _navegarYActualizar('/anadir_usuario'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _tarjetaEstadistica(
    String numero,
    String titulo,
    IconData icono,
    Color colorFondo,
    Color colorIcono,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: colorIcono, size: 28),
          const SizedBox(height: 6),
          Text(
            numero,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorIcono,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colorIcono,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaInventario(
    String numero,
    String titulo,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text(
              numero,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botón sin overflow
  Widget _botonAccesoRapido(
    IconData icono,
    String titulo,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}