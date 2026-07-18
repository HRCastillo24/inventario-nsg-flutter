import 'package:flutter/material.dart';
import '../models/movimiento.dart';

class MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;

  const MovimientoTile({
    super.key,
    required this.movimiento,
  });

  Color _getColor() {
    switch (movimiento.tipoMovimiento.toLowerCase()) {
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
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (movimiento.tipoMovimiento.toLowerCase()) {
      case 'entrada':
        return Icons.add_circle_outline;
      case 'salida':
        return Icons.remove_circle_outline;
      case 'cambio':
        return Icons.edit_outlined;
      case 'solicitud':
        return Icons.rate_review;
      case 'aprobacion':
        return Icons.check_circle_outline;
      case 'rechazo':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final esSolicitud = ['solicitud', 'aprobacion', 'rechazo']
        .contains(movimiento.tipoMovimiento.toLowerCase());
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalles(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getIcon(), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movimiento.getDescripcion(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          movimiento.getFechaFormateada(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge de cantidad (solo si no es solicitud)
                  if (!esSolicitud && movimiento.cantidadMovimiento > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        movimiento.tipoMovimiento.toLowerCase() == 'salida'
                            ? '-${movimiento.cantidadMovimiento}'
                            : '+${movimiento.cantidadMovimiento}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Descripción adicional (para solicitudes)
              if (movimiento.descripcion != null && movimiento.descripcion!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          movimiento.descripcion!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Información del producto
              if (movimiento.nombreProducto != null) ...[
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        movimiento.nombreProducto!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              
              // Código y marca
              Row(
                children: [
                  if (movimiento.codigo != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        movimiento.codigo!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  if (movimiento.marca != null)
                    Expanded(
                      child: Text(
                        movimiento.marca!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              
              // Usuario
              if (movimiento.nombreUsuario != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Por: ${movimiento.nombreUsuario}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getIcon(), color: _getColor()),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Detalles del Movimiento', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo:', movimiento.getDescripcion()),
              _buildDetailRow('Cantidad:', '${movimiento.cantidadMovimiento} unidades'),
              _buildDetailRow('Fecha:', movimiento.getFechaCompletaFormateada()),
              
              if (movimiento.descripcion != null)
                _buildDetailRow('Descripción:', movimiento.descripcion!),
              
              if (movimiento.nombreProducto != null)
                _buildDetailRow('Producto:', movimiento.nombreProducto!),
              
              if (movimiento.codigo != null)
                _buildDetailRow('Código:', movimiento.codigo!),
              
              if (movimiento.marca != null)
                _buildDetailRow('Marca:', movimiento.marca!),
              
              if (movimiento.tipo != null)
                _buildDetailRow('Categoría:', movimiento.tipo!),
              
              if (movimiento.nombreUsuario != null)
                _buildDetailRow('Realizado por:', movimiento.nombreUsuario!),
              
              if (movimiento.correoUsuario != null)
                _buildDetailRow('Correo:', movimiento.correoUsuario!),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}