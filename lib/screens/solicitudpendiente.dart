import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/api_service.dart';

class SolicitudPendienteScreen extends StatefulWidget {
  final int? idSolicitud;
  final Map<String, dynamic>? productoData;

  const SolicitudPendienteScreen({
    super.key,
    this.idSolicitud,
    this.productoData,
  });

  @override
  State<SolicitudPendienteScreen> createState() => _SolicitudPendienteScreenState();
}

class _SolicitudPendienteScreenState extends State<SolicitudPendienteScreen> {
  List<dynamic> _solicitudes = [];
  bool _cargando = true;
  String? _errorMensaje;
  String? _estadoProcesado;


  final Color amarilloSuave = const Color(0xFFFFA726);

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
      _estadoProcesado = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      if (widget.idSolicitud != null) {
        print('📡 Cargando solicitud ID: ${widget.idSolicitud}');
        
        try {
          final response = await apiService.get(
            context, 
            '/api/solicitudes/${widget.idSolicitud}',
          );
          
          print('Response tipo: ${response.runtimeType}');
          print('Response completo: $response');

          // VERIFICAR SI LA RESPUESTA ES UN MAP
          if (response is Map<String, dynamic>) {
            // VERIFICAR SI HAY ERROR EN LA RESPUESTA
            if (response.containsKey('error')) {
              print('⚠️ Error en response: ${response['error']}');
              setState(() {
                _solicitudes = [];
                _cargando = false;
                _errorMensaje = response['error'];
                _estadoProcesado = response['estado'];
              });
              return;
            }

            // 🔧 VALIDAR QUE TENGA LOS CAMPOS NECESARIOS
            if (!response.containsKey('id_solicitud')) {
              print('⚠️ Response no tiene id_solicitud: $response');
              throw Exception('Respuesta del servidor incompleta');
            }

            // 🔧 VALIDAR ESTADO
            if (response['estado_cambio'] != 'pendiente') {
              print('⚠️ Solicitud ya procesada: ${response['estado_cambio']}');
              setState(() {
                _solicitudes = [];
                _cargando = false;
                _errorMensaje = 'Esta solicitud ya fue ${response['estado_cambio']}';
                _estadoProcesado = response['estado_cambio'];
              });
              return;
            }
            
            // ✅ TODO OK, CARGAR SOLICITUD
            print('✅ Solicitud cargada correctamente');
            setState(() {
              _solicitudes = [response];
              _cargando = false;
            });
          } else if (response is List) {
            // Si devuelve un array vacío
            if (response.isEmpty) {
              setState(() {
                _solicitudes = [];
                _cargando = false;
                _errorMensaje = 'Solicitud no encontrada';
              });
            } else {
              setState(() {
                _solicitudes = response;
                _cargando = false;
              });
            }
          } else {
            print('❌ Tipo de respuesta inesperado: ${response.runtimeType}');
            throw Exception('Respuesta inesperada del servidor');
          }
        } on Exception catch (e) {
          print('❌ Excepción capturada: $e');
          
          String mensajeError = 'Error al cargar la solicitud';
          
          // Detectar diferentes tipos de error
          if (e.toString().contains('410')) {
            mensajeError = 'Esta solicitud ya fue procesada';
            _estadoProcesado = 'procesada';
          } else if (e.toString().contains('404')) {
            mensajeError = 'Solicitud no encontrada';
          } else if (e.toString().contains('500')) {
            mensajeError = 'Error del servidor. Intenta nuevamente.';
          }
          
          setState(() {
            _cargando = false;
            _errorMensaje = mensajeError;
          });
        }
      } else {
        // Cargar todas las solicitudes pendientes
        print(' Cargando todas las solicitudes pendientes...');
        
        final response = await apiService.get(
          context, 
          '/api/solicitudes/pendientes',
        );
        
        print(' Response pendientes: $response');
        
        if (response is! List) {
          throw Exception('Se esperaba una lista de solicitudes');
        }

        setState(() {
          _solicitudes = response;
          _cargando = false;
        });
      }
    } catch (e) {
      print('❌ Error general no capturado: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      setState(() {
        _cargando = false;
        _errorMensaje = 'Error de conexión: Por favor verifica tu internet';
      });
      
     
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _aprobarSolicitud(int idSolicitud, String nombreProducto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aprobar Solicitud',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Aprobar el registro de "$nombreProducto"?\n\nEl producto se añadirá al inventario.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text('Aprobar', style: TextStyle(color: Colors.white)),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    if (confirmar == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.put(context, '/api/solicitudes/$idSolicitud/aprobar', {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('✅ Solicitud aprobada. Producto registrado en inventario.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al aprobar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rechazarSolicitud(int idSolicitud, String nombreProducto) async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Rechazar Solicitud',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Rechazar "$nombreProducto"?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: Información incompleta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            label: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    if (confirmar == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.put(
          context,
          '/api/solicitudes/$idSolicitud/rechazar',
          {'motivo': motivoController.text.trim()},
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.white),
                  SizedBox(width: 12),
                  Text('❌ Solicitud rechazada'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
          
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al rechazar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.idSolicitud != null 
            ? 'Detalle de Solicitud' 
            : 'Solicitudes Pendientes',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: amarilloSuave,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando solicitudes...'),
                ],
              ),
            )
          : _errorMensaje != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _estadoProcesado != null 
                            ? Icons.info_outline 
                            : Icons.error_outline, 
                          size: 80, 
                          color: _estadoProcesado != null 
                            ? Colors.orange.shade300 
                            : Colors.red.shade300
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMensaje!,
                          style: TextStyle(
                            fontSize: 16, 
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_estadoProcesado != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _estadoProcesado == 'aprobado' 
                                ? Colors.green.shade100 
                                : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Estado: ${_estadoProcesado!.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _estadoProcesado == 'aprobado' 
                                  ? Colors.green.shade800 
                                  : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: amarilloSuave,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _solicitudes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No hay solicitudes pendientes',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarSolicitudes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _solicitudes.length,
                        itemBuilder: (context, index) {
                          final solicitud = _solicitudes[index];
                          final detalles = solicitud['descripcion_cambio'] ?? '';
                          final fecha = DateTime.tryParse(solicitud['fecha_cambio'] ?? '') ?? DateTime.now();
                          final usuario = solicitud['nombre_usuario'] ?? 'Desconocido';

                          // Extraer nombre del producto
                          String nombreProducto = 'Producto';
                          final match = RegExp(r'Nombre:\s*(.+?)(?:\n|$)').firstMatch(detalles);
                          if (match != null) {
                            nombreProducto = match.group(1)?.trim() ?? 'Producto';
                          }

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: amarilloSuave.withOpacity(0.2),
                                child: Icon(Icons.rate_review, color: amarilloSuave, size: 26),
                              ),
                              title: Text(
                                nombreProducto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        usuario,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📋 Detalles del Producto',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: amarilloSuave,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          detalles,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'monospace',
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _rechazarSolicitud(
                                                solicitud['id_solicitud'],
                                                nombreProducto,
                                              ),
                                              icon: const Icon(Icons.close, size: 20),
                                              label: const Text('Rechazar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _aprobarSolicitud(
                                                solicitud['id_solicitud'],
                                                nombreProducto,
                                              ),
                                              icon: const Icon(Icons.check, size: 20),
                                              label: const Text('Aprobar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}