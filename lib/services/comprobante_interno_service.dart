import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ComprobanteInternoService {
  /// Genera un comprobante de venta interno
  Future<void> generarComprobanteInterno({
    required BuildContext context,
    required String nombreEmpresa,
    required String rucEmpresa,
    required String direccionEmpresa,
    required String telefonoEmpresa,
    required String numeroComprobante,
    required DateTime fechaEmision,
    required String nombreCliente,
    required String documentoCliente,
    required List<Map<String, dynamic>> productos,
    required double descuentoGeneral,
    required double descuentoCombos,
    required double igv,
    required String metodoPago,
    String? observaciones,
  }) async {
    final pdf = pw.Document();
    
    // CARGAR EL LOGO
    final ByteData logoData = await rootBundle.load('assets/images/logo.jpg');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);
    
    // Calcular totales
    double subtotal = 0;
    for (var prod in productos) {
      final cantidad = prod['cantidad'] ?? 1;
      final precio = prod['precio_unitario'] ?? 0.0;
      subtotal += (cantidad * precio);
    }
    
    final montoDescuentoGeneral = subtotal * (descuentoGeneral / 100);
    final subtotalConDescuento = subtotal - montoDescuentoGeneral - descuentoCombos;
    final montoIgv = subtotalConDescuento * (igv / 100);
    final total = subtotalConDescuento + montoIgv;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ========== ENCABEZADO CON LOGO ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo y datos de la empresa
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // LOGO
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      // Datos de la empresa
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            nombreEmpresa,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'RUC: $rucEmpresa',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            direccionEmpresa,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'Tel: $telefonoEmpresa',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Recuadro del comprobante
                  pw.Container(
                    width: 180,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue900, width: 2),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'COMPROBANTE DE VENTA',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          numeroComprobante,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red100,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Text(
                            'SIN VALOR TRIBUTARIO',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 16),
              
              // ========== DATOS DEL CLIENTE ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CLIENTE',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        nombreCliente.isEmpty ? 'CLIENTE GENERAL' : nombreCliente,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        documentoCliente.isEmpty ? '-' : 'Doc: $documentoCliente',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'FECHA',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(fechaEmision),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        DateFormat('hh:mm a').format(fechaEmision),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              // ========== TABLA DE PRODUCTOS ==========
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Encabezado
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    children: [
                      _buildTableHeader('CANT.'),
                      _buildTableHeader('DESCRIPCIÓN'),
                      _buildTableHeader('P. UNIT.'),
                      _buildTableHeader('DESC.'),
                      _buildTableHeader('SUBTOTAL'),
                    ],
                  ),
                  
                  // Productos
                  ...productos.map((prod) {
                    final cantidad = prod['cantidad'] ?? 1;
                    final precio = prod['precio_unitario'] ?? 0.0;
                    final subtotalProd = cantidad * precio;
                    final observacion = prod['observaciones'] ?? '';
                    final esCombo = observacion.startsWith('COMBO:');
                    
                    return pw.TableRow(
                      decoration: esCombo
                          ? const pw.BoxDecoration(color: PdfColors.green50)
                          : null,
                      children: [
                        _buildTableCell(cantidad.toString()),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                prod['nombre_producto'] ?? 'Producto',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: esCombo
                                      ? pw.FontWeight.bold
                                      : pw.FontWeight.normal,
                                ),
                              ),
                              if (observacion.isNotEmpty)
                                pw.Text(
                                  observacion,
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    color: PdfColors.green900,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildTableCell('S/ ${precio.toStringAsFixed(2)}'),
                        _buildTableCell('-'),
                        _buildTableCell(
                          'S/ ${subtotalProd.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              // ========== RESUMEN DE TOTALES ==========
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Información adicional (izquierda)
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MÉTODO DE PAGO',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Text(
                            metodoPago.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        if (observaciones != null && observaciones.isNotEmpty) ...[
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'OBSERVACIONES',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            observaciones,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(width: 24),
                  
                  // Totales (derecha)
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _buildTotalRow('SUBTOTAL:', subtotal),
                        
                        if (descuentoGeneral > 0)
                          _buildTotalRow(
                            'DESCUENTO (${descuentoGeneral.toStringAsFixed(0)}%):',
                            -montoDescuentoGeneral,
                            isNegative: true,
                          ),
                        
                        if (descuentoCombos > 0)
                          _buildTotalRow(
                            'DESC. COMBOS:',
                            -descuentoCombos,
                            isNegative: true,
                          ),
                        
                        _buildTotalRow(
                          'IGV (${igv.toStringAsFixed(0)}%):',
                          montoIgv,
                        ),
                        
                        pw.Divider(thickness: 2),
                        
                        _buildTotalRow(
                          'TOTAL A PAGAR:',
                          total,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              // ========== PIE DE PÁGINA ==========
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red100,
                        border: pw.Border.all(color: PdfColors.red900),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        '⚠ DOCUMENTO SIN VALOR TRIBUTARIO - COMPROBANTE INTERNO ⚠',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Este documento es solo para control interno y no tiene validez ante SUNAT',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Gracias por su compra',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Mostrar el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'comprobante_$numeroComprobante.pdf',
    );
  }

  // ========== MÉTODOS AUXILIARES ==========
  
  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    double monto, {
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: isTotal
          ? pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 11 : 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.white : PdfColors.black,
            ),
          ),
          pw.Text(
            'S/ ${monto.abs().toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 10,
              fontWeight: pw.FontWeight.bold,
              color: isTotal
                  ? PdfColors.white
                  : isNegative
                      ? PdfColors.red
                      : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}