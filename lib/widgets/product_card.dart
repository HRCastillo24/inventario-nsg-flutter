import 'package:flutter/material.dart';
import '../models/producto.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final Producto producto;

  const ProductCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(symbol: 'S/', decimalDigits: 2);
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del producto
            Text(
              producto.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),

            // Datos principales
            Text("Código: ${producto.codigo}"),
            
            // Mostrar tipo y marca con sus NOMBRES
            if (producto.nombreTipo != null && producto.nombreTipo!.isNotEmpty)
              Text("Tipo: ${producto.nombreTipo}"),
            if (producto.nombreMarca != null && producto.nombreMarca!.isNotEmpty)
              Text("Marca: ${producto.nombreMarca}"),
            
            Text("Documento: ${producto.documento}"),
            Text("Cantidad: ${producto.cantidad}"),
            Text("Stock mínimo: ${producto.stockMinimo}"),
            if (producto.ubicacion.isNotEmpty)
              Text("Ubicación: ${producto.ubicacion}"),
            Text("Compra: ${formatoMoneda.format(producto.precioCompra)}"),
            Text("Venta: ${formatoMoneda.format(producto.precioVenta)}"),
            const SizedBox(height: 4),

            // Fecha de ingreso
            Text(
              "Ingreso: ${formatoFecha.format(producto.fechaIngreso)}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            // Si tiene PDF asociado
            if (producto.archivoPdf != null)
              TextButton.icon(
                onPressed: () {
                  // abrir PDF
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                label: const Text("Ver documento"),
              ),
          ],
        ),
      ),
    );
  }
}