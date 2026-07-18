import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class GestionarVentasScreen extends StatefulWidget {
  const GestionarVentasScreen({super.key});

  @override
  State<GestionarVentasScreen> createState() => _GestionarVentasScreenState();
}

class _GestionarVentasScreenState extends State<GestionarVentasScreen> {
  List<dynamic> _ventas = [];
  bool _cargando = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  // Cargar todas las ventas desde la API
  Future<void> _cargarVentas() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get(context, '/api/ventas');

      if (mounted) {
        setState(() {
          _ventas = response as List<dynamic>;
          _cargando = false;
        });
      }
      
      print('✅ ${_ventas.length} ventas cargadas');
    } catch (e) {
      print('❌ Error al cargar ventas: $e');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar ventas: $e';
          _cargando = false;
        });
      }
    }
  }

  // Eliminar venta (solo gerente)
  Future<void> _eliminarVenta(int idVenta, BuildContext context) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.delete(context, '/api/ventas/$idVenta');

      if (mounted) {
        // Actualizar la lista localmente primero
        setState(() {
          _ventas.removeWhere((venta) => venta['id_venta'] == idVenta);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Venta eliminada y stock restaurado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Recargar desde el servidor para asegurar sincronización
        await _cargarVentas();
      }
    } catch (e) {
      print('❌ Error al eliminar venta: $e');
      if (mounted) {
        // Si hay error, recargar la lista original
        _cargarVentas();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar venta: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Ver detalle de venta
  Future<void> _verDetalleVenta(int idVenta) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.get(context, '/api/ventas/$idVenta');

      if (!mounted) return;
      Navigator.pop(context); 

      _mostrarDialogDetalle(data);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostrar dialog con detalle de venta
  void _mostrarDialogDetalle(Map<String, dynamic> data) {
    final venta = data['venta'];
    final detalle = data['detalle'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFFE91E63), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalle de Venta #${venta['id_venta']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Información general
              _buildInfoRow('Usuario:', venta['nombre_usuario'] ?? 'N/A'),
              _buildInfoRow('Fecha:', _formatearFecha(venta['fecha_venta'])),
              _buildInfoRow('Método de pago:', _formatearMetodoPago(venta['metodo_pago'])),
              _buildInfoRow('Descuento:', '${venta['descuento'] ?? 0}%'),
              _buildInfoRow('IGV:', '${venta['igv'] ?? 0}%'),
              
              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Lista de productos
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: detalle.length,
                  itemBuilder: (context, index) {
                    final item = detalle[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nombre_producto'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Código: ${item['codigo'] ?? 'N/A'}'),
                            Text('Cantidad: ${item['cantidad_vendida']}'),
                            Text('Precio Unit.: S/. ${item['precio_unitario']}'),
                            Text(
                              'Subtotal: S/. ${item['subtotal']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (item['observaciones'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '📝 ${item['observaciones']}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 24),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'S/. ${venta['total']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Confirmar eliminación
  void _confirmarEliminacion(int idVenta, String numeroVenta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Confirmar Eliminación',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Estás seguro de eliminar la Venta #$numeroVenta?'),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Esta acción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('• Eliminará la venta permanentemente'),
              const Text('• Restaurará el stock de los productos'),
              const Text('• No se puede deshacer'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarVenta(idVenta, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Formatear fecha
  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return fecha;
    }
  }

  // Formatear método de pago
  String _formatearMetodoPago(String? metodo) {
    if (metodo == null) return 'N/A';
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return '💵 Efectivo';
      case 'tarjeta':
        return '💳 Tarjeta';
      case 'transferencia':
        return '🏦 Transferencia';
      default:
        return metodo;
    }
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Gestionar Ventas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
            tooltip: 'Recargar',
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
                    'Cargando ventas...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarVentas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _ventas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay ventas registradas',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarVentas,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ventas.length,
                        itemBuilder: (context, index) {
                          final venta = _ventas[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _verDetalleVenta(venta['id_venta']),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE91E63).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Venta #${venta['id_venta']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE91E63),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'S/. ${venta['total']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE91E63),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Información
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            venta['nombre_usuario'] ?? 'N/A',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatearFecha(venta['fecha_venta']),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.payment, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatearMetodoPago(venta['metodo_pago']),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    
                                    // Botones de acción
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _verDetalleVenta(venta['id_venta']),
                                            icon: const Icon(Icons.visibility, size: 18),
                                            label: const Text('Ver Detalle'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFFE91E63),
                                              side: const BorderSide(color: Color(0xFFE91E63)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _confirmarEliminacion(
                                              venta['id_venta'],
                                              venta['id_venta'].toString(),
                                            ),
                                            icon: const Icon(Icons.delete, size: 18),
                                            label: const Text('Eliminar'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}