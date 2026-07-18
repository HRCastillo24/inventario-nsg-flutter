import 'package:flutter/material.dart';
import '../models/movimiento.dart';
import '../services/movimiento_service.dart';
import '../widgets/movimiento_tile.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final MovimientoService _service = MovimientoService();
  
  List<Movimiento> movimientos = [];
  List<Movimiento> movimientosFiltrados = [];
  bool cargando = true;
  String filtroActivo = 'todos'; 
  Map<String, dynamic>? estadisticas;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    
    try {
      // Cargar movimientos y estadísticas en paralelo
      final resultados = await Future.wait([
        _service.obtenerTodosLosMovimientos(),
        _service.obtenerEstadisticas(),
      ]);
      
      setState(() {
        movimientos = resultados[0] as List<Movimiento>;
        movimientosFiltrados = movimientos;
        estadisticas = resultados[1] as Map<String, dynamic>;
        cargando = false;
      });
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() => cargando = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar movimientos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filtrar movimientos por tipo
  void filtrarMovimientos(String tipo) {
    setState(() {
      filtroActivo = tipo;
      
      if (tipo == 'todos') {
        movimientosFiltrados = movimientos;
      } else {
        movimientosFiltrados = movimientos
            .where((m) => m.tipoMovimiento.toLowerCase() == tipo)
            .toList();
      }
    });
  }

  // Color para cada tipo de filtro
  Color _getColorFiltro(String tipo) {
    switch (tipo) {
      case 'entrada':
        return Colors.green;
      case 'salida':
        return Colors.red;
      case 'cambio':
        return Colors.orange;
      case 'solicitud':
        return Colors.blue;
      case 'aprobacion':
        return Colors.green;
      case 'rechazo':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Historial de Movimientos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tarjetas de estadísticas
                if (estadisticas != null) _buildEstadisticas(),
                
                // Botones de filtro
                _buildFiltros(),
                
                const SizedBox(height: 8),
                
                // Lista de movimientos
                Expanded(
                  child: movimientosFiltrados.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: cargarDatos,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: movimientosFiltrados.length,
                            itemBuilder: (context, index) {
                              return MovimientoTile(
                                movimiento: movimientosFiltrados[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // Widget de estadísticas
  Widget _buildEstadisticas() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primera fila: Entradas, Salidas, Cambios
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Entradas',
                  estadisticas!['entrada']?['total_movimientos']?.toString() ?? '0',
                  Colors.green,
                  Icons.add_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Salidas',
                  estadisticas!['salida']?['total_movimientos']?.toString() ?? '0',
                  Colors.red,
                  Icons.remove_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Cambios',
                  estadisticas!['cambio']?['total_movimientos']?.toString() ?? '0',
                  Colors.orange,
                  Icons.edit_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segunda fila: Solicitudes, Aprobadas, Rechazadas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Solicitudes',
                  estadisticas!['solicitud']?['total_movimientos']?.toString() ?? '0',
                  Colors.blue,
                  Icons.rate_review,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Aprobadas',
                  estadisticas!['aprobacion']?['total_movimientos']?.toString() ?? '0',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Rechazadas',
                  estadisticas!['rechazo']?['total_movimientos']?.toString() ?? '0',
                  Colors.red,
                  Icons.cancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget de filtros
  Widget _buildFiltros() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChipFiltro('todos', 'Todos', Colors.blue),
          _buildChipFiltro('entrada', 'Entradas', Colors.green),
          _buildChipFiltro('salida', 'Salidas', Colors.red),
          _buildChipFiltro('cambio', 'Cambios', Colors.orange),
          _buildChipFiltro('solicitud', 'Solicitudes', Colors.blue),
          _buildChipFiltro('aprobacion', 'Aprobadas', Colors.green),
          _buildChipFiltro('rechazo', 'Rechazadas', Colors.red),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String tipo, String label, Color color) {
    final isSelected = filtroActivo == tipo;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => filtrarMovimientos(tipo),
        backgroundColor: Colors.white,
        selectedColor: color,
        checkmarkColor: Colors.white,
        side: BorderSide(color: color),
        elevation: isSelected ? 4 : 0,
      ),
    );
  }

  // Widget cuando no hay movimientos
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            filtroActivo == 'todos'
                ? 'No hay movimientos registrados'
                : 'No hay movimientos de tipo "$filtroActivo"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (filtroActivo != 'todos') {
                filtrarMovimientos('todos');
              } else {
                cargarDatos();
              }
            },
            icon: Icon(
              filtroActivo != 'todos' ? Icons.clear_all : Icons.refresh,
            ),
            label: Text(
              filtroActivo != 'todos' ? 'Ver Todos' : 'Actualizar',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de filtros avanzados
  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros Avanzados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Movimientos de Hoy'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => cargando = true);
                
                try {
                  final movs = await _service.obtenerMovimientosDeHoy();
                  setState(() {
                    movimientosFiltrados = movs;
                    filtroActivo = 'hoy';
                    cargando = false;
                  });
                } catch (e) {
                  setState(() => cargando = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.green),
              title: const Text('Última Semana'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => cargando = true);
                
                try {
                  final movs = await _service.obtenerMovimientosSemana();
                  setState(() {
                    movimientosFiltrados = movs;
                    filtroActivo = 'semana';
                    cargando = false;
                  });
                } catch (e) {
                  setState(() => cargando = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}