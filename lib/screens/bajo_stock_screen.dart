import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:nsg_inventario/screens/anadir_producto_screen.dart';
import 'editar_producto_screen.dart';

class BajoStockScreen extends StatefulWidget {
  const BajoStockScreen({super.key});

  @override
  State<BajoStockScreen> createState() => _BajoStockScreenState();
}

class _BajoStockScreenState extends State<BajoStockScreen> {
  List productos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerProductos();
  }

  Future<void> obtenerProductos() async {
    setState(() => cargando = true);
    try {

      final url = Uri.parse('https://nsglatinoamerica.duckdns.org/api/productos/bajo-stock');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);


        setState(() {
          productos = data;
          cargando = false;
        });
      } else {
        throw Exception('Error al cargar productos (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() => cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al conectar con el servidor: $e')),
        );
      }
    }
  }

  // Función para reponer stock 
  void _reponerStock(Map<String, dynamic> producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarProductoScreen(producto: producto),
      ),
    ).then((value) {
      // Si se actualizó el producto, recargar la lista
      if (value == true) {
        obtenerProductos();
      }
    });
  }

  // Determinar el color según la cantidad
  Color _obtenerColorPorCantidad(int cantidad) {
    if (cantidad == 0) {
      return Colors.red;
    } else if (cantidad <= 2) {
      return Colors.orange;
    } else {
      return Colors.amber;
    }
  }

  // Determinar el mensaje de urgencia
  String _obtenerMensajeUrgencia(int cantidad) {
    if (cantidad == 0) {
      return '🔴 CRÍTICO - Sin stock';
    } else if (cantidad <= 2) {
      return '🟠 URGENTE - Stock muy bajo';
    } else {
      return '🟡 ADVERTENCIA - Stock bajo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Productos con Bajo Stock',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: obtenerProductos,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen de productos con bajo stock
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Productos con Stock Bajo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${productos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'producto${productos.length != 1 ? 's' : ''} requieren atención',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de productos
                Expanded(
                  child: productos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '¡Excelente! 🎉',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No hay productos con bajo stock',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: obtenerProductos,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: productos.length,
                            itemBuilder: (context, index) {
                              final producto = productos[index];
                              final cantidad = producto['cantidad'] ?? 0;
                              final nombre = producto['nombre_producto'] ?? 'Sin nombre';
                              final marca = producto['marca'] ?? 'Sin marca';
                              final tipo = producto['tipo'] ?? 'Sin tipo';
                              final stockMinimo = producto['stock_minimo'] ?? 5;
                              final stockMaximo = stockMinimo * 4; // Valor de referencia
                              final double porcentaje = (cantidad / stockMaximo).clamp(0.0, 1.0);
                              
                              final colorEstado = _obtenerColorPorCantidad(cantidad);
                              final mensajeUrgencia = _obtenerMensajeUrgencia(cantidad);

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: colorEstado.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado con nombre y badge de cantidad
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nombre,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      marca,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(Icons.category, size: 14, color: Colors.grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        tipo,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorEstado,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorEstado.withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '$cantidad',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Mensaje de urgencia
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorEstado.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: colorEstado.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          mensajeUrgencia,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: cantidad == 0 
                                                ? Colors.red.shade800
                                                : cantidad <= 2 
                                                    ? Colors.orange.shade800
                                                    : Colors.amber.shade800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Barra de progreso
                                      LinearPercentIndicator(
                                        lineHeight: 12.0,
                                        percent: porcentaje,
                                        backgroundColor: Colors.grey.shade300,
                                        progressColor: colorEstado,
                                        barRadius: const Radius.circular(8),
                                        animation: true,
                                        animationDuration: 800,
                                      ),
                                      const SizedBox(height: 12),

                                      // Información adicional
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Disponible: $cantidad unidades',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${(porcentaje * 100).toInt()}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: colorEstado,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Botón de reponer
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _reponerStock(producto),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF7043),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Reponer Stock',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
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
                ),
              ],
            ),
    );
  }
}