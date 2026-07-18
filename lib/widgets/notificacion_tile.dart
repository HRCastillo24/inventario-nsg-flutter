import 'package:flutter/material.dart';
import '../models/notificacion.dart';
import '../utils/date_utils.dart';

class NotificacionTile extends StatelessWidget {
  final Notificacion notificacion;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const NotificacionTile({
    Key? key,
    required this.notificacion,
    required this.onTap,
    this.onDismiss,
  }) : super(key: key);

  IconData _getIconData() {
    switch (notificacion.tipoNotificacion) {
      case 'bajo_stock':
        return Icons.inventory_2_outlined;
      case 'ausencia':
        return Icons.person_off_outlined;
      case 'solicitud_cambio':
        return Icons.assignment_outlined;
      case 'aprobacion':
        return Icons.check_circle_outline;
      case 'rechazo':
        return Icons.cancel_outlined;
      case 'movimiento':
        return Icons.swap_horiz;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notificacion.idNotificacion.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        if (onDismiss != null) onDismiss!();
      },
      child: Container(
        // ESPACIADO MEJORADO: más separación entre notificaciones
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: notificacion.leido ? Colors.white : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: notificacion.getColor(),
              width: 5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            // 🔧 PADDING INTERNO AUMENTADO
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de no leído
                if (!notificacion.leido)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 12, top: 6),
                    decoration: BoxDecoration(
                      color: notificacion.getColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                
                // Icono
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notificacion.getColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(),
                    color: notificacion.getColor(),
                    size: 26,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacion.mensajeNotificacion,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notificacion.leido 
                            ? FontWeight.w500 
                            : FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateUtilsCustom.formatearFechaRelativa(
                              notificacion.fechaNotificacion
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Flecha para indicar navegación
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}