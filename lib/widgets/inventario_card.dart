import 'package:flutter/material.dart';

class InventarioCard extends StatelessWidget {
  final Map<String, dynamic> producto;

  const InventarioCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final bool bajoStock = producto['cantidad'] <= producto['stock_minimo'];

    return Card(
      elevation: 3,
      color: bajoStock ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          bajoStock ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
          color: bajoStock ? Colors.red : Colors.blue,
          size: 30,
        ),
        title: Text(
          producto['nombre_producto'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Código: ${producto['codigo']}"),
            Text("Tipo: ${producto['tipo']}"),
            Text("Marca: ${producto['marca']}"),
            Text("Cantidad: ${producto['cantidad']}"),
            Text("Stock mínimo: ${producto['stock_minimo']}"),
            Text("Precio venta: S/ ${producto['precio_venta']}"),
          ],
        ),
        trailing: bajoStock
            ? const Text("Bajo stock", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            : null,
      ),
    );
  }
}
