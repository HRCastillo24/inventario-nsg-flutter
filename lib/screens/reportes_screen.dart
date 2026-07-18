import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/api_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String periodoSeleccionado = "Día";
  DateTime fechaInicio = DateTime.now();
  DateTime fechaFin = DateTime.now();
  String? productoSeleccionado;
  
  bool cargando = false;

  final Color azul = const Color(0xFF2196F3);

  List<String> productos = ["Todos"];
  List<Map<String, dynamic>> ventas = [];
  Map<String, double> ventasPorPeriodo = {};
  double totalVentas = 0.0;
  int cantidadProductosVendidos = 0;

  @override
  void initState() {
    super.initState();
    productoSeleccionado = "Todos";
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await _cargarProductos();
    await _cargarVentas();
  }

  Future<void> _cargarProductos() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get(context, '/api/productos');
      
      final List<dynamic> data = response as List<dynamic>;
      if (mounted) {
        setState(() {
          productos = ["Todos"] + data.map((p) => p['nombre_producto'].toString()).toSet().toList();
        });
      }
    } catch (e) {
      debugPrint('Error al cargar productos: $e');
    }
  }

  Future<void> _cargarVentas() async {
    if (!mounted) return;
    setState(() => cargando = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final ventasResponse = await apiService.get(context, '/api/ventas');
      final List<dynamic> ventasData = ventasResponse as List<dynamic>;
      
      List<Map<String, dynamic>> ventasConDetalle = [];
      
      for (var venta in ventasData) {
        try {
          final detalleData = await apiService.get(context, '/api/ventas/${venta['id_venta']}');
          
          if (detalleData['detalle'] != null) {
            for (var producto in detalleData['detalle']) {
              ventasConDetalle.add({
                'id_venta': venta['id_venta'],
                'fecha': venta['fecha_venta'],
                'producto': producto['nombre_producto'],
                'cantidad': _toInt(producto['cantidad_vendida']),
                'precio_unitario': _toDouble(producto['precio_unitario']),
                'total': _toDouble(producto['subtotal']),
                'vendedor': venta['nombre_usuario'] ?? 'Sin asignar',
                'observaciones': producto['observaciones'],
              });
            }
          }
        } catch (e) {
          debugPrint('Error al obtener detalle de venta ${venta['id_venta']}: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          ventas = ventasConDetalle;
          cargando = false;
        });
        _calcularEstadisticasSinSetState();
      }
    } catch (e) {
      debugPrint('❌ Error al cargar ventas: $e');
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ventas: $e')),
        );
      }
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  void _calcularEstadisticasSinSetState() {
    totalVentas = 0.0;
    cantidadProductosVendidos = 0;
    ventasPorPeriodo.clear();

    final ventasFiltradas = ventas.where((v) {
      try {
        final fechaVenta = DateTime.parse(v['fecha']);
        final dentroRango = fechaVenta.isAfter(fechaInicio.subtract(const Duration(days: 1))) &&
                           fechaVenta.isBefore(fechaFin.add(const Duration(days: 1)));
        final cumpleProducto = productoSeleccionado == "Todos" || v['producto'] == productoSeleccionado;
        
        return dentroRango && cumpleProducto;
      } catch (e) {
        return false;
      }
    }).toList();

    for (var venta in ventasFiltradas) {
      totalVentas += _toDouble(venta['total']);
      cantidadProductosVendidos += _toInt(venta['cantidad']);
    }

    if (periodoSeleccionado == "Día") {
      final duracion = fechaFin.difference(fechaInicio).inDays + 1;
      for (int i = 0; i < duracion; i++) {
        final fecha = fechaInicio.add(Duration(days: i));
        final key = DateFormat('dd/MM').format(fecha);
        ventasPorPeriodo[key] = 0.0;
      }
      
      for (var venta in ventasFiltradas) {
        try {
          final fecha = DateTime.parse(venta['fecha']);
          final key = DateFormat('dd/MM').format(fecha);
          if (ventasPorPeriodo.containsKey(key)) {
            ventasPorPeriodo[key] = (ventasPorPeriodo[key] ?? 0.0) + _toDouble(venta['total']);
          }
        } catch (e) {}
      }
    } else if (periodoSeleccionado == "Mes") {
      final mesesSet = <String>{};
      
      for (var venta in ventas) {
        try {
          final fecha = DateTime.parse(venta['fecha']);
          final key = DateFormat('MMM yyyy', 'es').format(fecha);
          mesesSet.add(key);
        } catch (e) {}
      }
      
      final mesesOrdenados = mesesSet.toList()..sort((a, b) {
        try {
          final fechaA = DateFormat('MMM yyyy', 'es').parse(a);
          final fechaB = DateFormat('MMM yyyy', 'es').parse(b);
          return fechaA.compareTo(fechaB);
        } catch (e) {
          return 0;
        }
      });
      
      for (var mes in mesesOrdenados) {
        ventasPorPeriodo[mes] = 0.0;
      }
      
      for (var venta in ventasFiltradas) {
        try {
          final fecha = DateTime.parse(venta['fecha']);
          final key = DateFormat('MMM yyyy', 'es').format(fecha);
          if (ventasPorPeriodo.containsKey(key)) {
            ventasPorPeriodo[key] = (ventasPorPeriodo[key] ?? 0.0) + _toDouble(venta['total']);
          }
        } catch (e) {}
      }
    } else if (periodoSeleccionado == "Año") {
      final anosSet = <int>{};
      
      for (var venta in ventas) {
        try {
          final fecha = DateTime.parse(venta['fecha']);
          anosSet.add(fecha.year);
        } catch (e) {}
      }
      
      final anosOrdenados = anosSet.toList()..sort();
      
      for (var ano in anosOrdenados) {
        ventasPorPeriodo[ano.toString()] = 0.0;
      }
      
      for (var venta in ventasFiltradas) {
        try {
          final fecha = DateTime.parse(venta['fecha']);
          final key = fecha.year.toString();
          if (ventasPorPeriodo.containsKey(key)) {
            ventasPorPeriodo[key] = (ventasPorPeriodo[key] ?? 0.0) + _toDouble(venta['total']);
          }
        } catch (e) {}
      }
    }
  }

  void _calcularEstadisticas() {
    _calcularEstadisticasSinSetState();
    setState(() {});
  }

  List<Map<String, dynamic>> get ventasFiltradas {
    return ventas.where((v) {
      try {
        final fechaVenta = DateTime.parse(v['fecha']);
        final dentroRango = fechaVenta.isAfter(fechaInicio.subtract(const Duration(days: 1))) &&
                           fechaVenta.isBefore(fechaFin.add(const Duration(days: 1)));
        final cumpleProducto = productoSeleccionado == "Todos" || v['producto'] == productoSeleccionado;
        
        return dentroRango && cumpleProducto;
      } catch (e) {
        return false;
      }
    }).toList();
  }
  Future<void> _seleccionarMes() async {
    DateTime tempFecha = fechaInicio;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Seleccionar Mes"),
          content: SizedBox(
            width: 300,
            height: 350,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          tempFecha = DateTime(tempFecha.year - 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      "${tempFecha.year}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          tempFecha = DateTime(tempFecha.year + 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final mes = index + 1;
                      final nombreMes = DateFormat('MMM', 'es').format(DateTime(tempFecha.year, mes));
                      final esSeleccionado = fechaInicio.year == tempFecha.year && fechaInicio.month == mes;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            fechaInicio = DateTime(tempFecha.year, mes, 1);
                            fechaFin = DateTime(tempFecha.year, mes + 1, 0);
                            _calcularEstadisticas();
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: esSeleccionado ? azul : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              nombreMes,
                              style: TextStyle(
                                color: esSeleccionado ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarAno() async {
    int anoSeleccionado = fechaInicio.year;
    final anoActual = DateTime.now().year;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Año"),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) {
              final ano = anoActual - index;
              
              return ListTile(
                title: Text(
                  "$ano",
                  style: TextStyle(
                    fontWeight: ano == anoSeleccionado ? FontWeight.bold : FontWeight.normal,
                    color: ano == anoSeleccionado ? azul : Colors.black,
                  ),
                ),
                tileColor: ano == anoSeleccionado ? azul.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    fechaInicio = DateTime(ano, 1, 1);
                    fechaFin = DateTime(ano, 12, 31);
                    _calcularEstadisticas();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarRangoFechas() async {
    if (periodoSeleccionado == "Mes") {
      await _seleccionarMes();
      return;
    }
    
    if (periodoSeleccionado == "Año") {
      await _seleccionarAno();
      return;
    }
    
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fechaInicio, end: fechaFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: azul),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        fechaInicio = rango.start;
        fechaFin = rango.end;
        _calcularEstadisticas();
      });
    }
  }

  String get textoRangoFechas {
    if (periodoSeleccionado == "Mes") {
      return DateFormat('MMMM yyyy', 'es').format(fechaInicio);
    } else if (periodoSeleccionado == "Año") {
      return "${fechaInicio.year}";
    } else {
      return "${DateFormat('dd/MM/yyyy').format(fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(fechaFin)}";
    }
  }
  Future<void> _exportarPDF() async {
    final pdf = pw.Document();

    final logoData = await rootBundle.load('assets/images/logo.jpg');
    final logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 100, height: 60),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "NSG LATINOAMERICA E.I.R.L.",
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "Venta, Servicio, Mantenimiento e Importación",
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        "de Equipos de Cómputo",
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              pw.Text(
                "REPORTE DE VENTAS",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.Text("Período: $periodoSeleccionado"),
              pw.Text("Rango: $textoRangoFechas"),
              pw.Text("Producto: ${productoSeleccionado ?? 'Todos'}"),
              pw.SizedBox(height: 10),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Total Ventas: S/ ${totalVentas.toStringAsFixed(2)}", 
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Productos Vendidos: $cantidadProductosVendidos"),
                    pw.Text("Número de transacciones: ${ventasFiltradas.length}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Text("Detalle de Ventas:", 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              
              pw.Table.fromTextArray(
                headers: ["Fecha", "Producto", "Cant.", "P.Unit.", "Total", "Obs."],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                data: ventasFiltradas.map((v) => [
                  DateFormat('dd/MM/yy').format(DateTime.parse(v['fecha'])),
                  v['producto'].toString().substring(0, v['producto'].toString().length > 20 ? 20 : v['producto'].toString().length),
                  v['cantidad'].toString(),
                  "S/${_toDouble(v['precio_unitario']).toStringAsFixed(2)}",
                  "S/${_toDouble(v['total']).toStringAsFixed(2)}",
                  (v['observaciones'] ?? '').toString().substring(0, (v['observaciones'] ?? '').toString().length > 15 ? 15 : (v['observaciones'] ?? '').toString().length),
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/reporte_ventas_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF guardado: ${file.path}"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: "Abrir",
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al exportar: $e")),
        );
      }
    }
  }

  Future<void> _exportarExcel() async {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Ventas'];

    sheet.merge(excel_lib.CellIndex.indexByString("A1"), excel_lib.CellIndex.indexByString("F1"));
    sheet.cell(excel_lib.CellIndex.indexByString("A1")).value = excel_lib.TextCellValue("NSG LATINOAMERICA E.I.R.L.");
    
    sheet.merge(excel_lib.CellIndex.indexByString("A2"), excel_lib.CellIndex.indexByString("F2"));
    sheet.cell(excel_lib.CellIndex.indexByString("A2")).value = excel_lib.TextCellValue("REPORTE DE VENTAS");
    
    sheet.appendRow([excel_lib.TextCellValue("")]);
    sheet.appendRow([excel_lib.TextCellValue("Período: $periodoSeleccionado")]);
    sheet.appendRow([excel_lib.TextCellValue("Rango: $textoRangoFechas")]);
    sheet.appendRow([excel_lib.TextCellValue("Producto: ${productoSeleccionado ?? 'Todos'}")]);
    sheet.appendRow([excel_lib.TextCellValue("")]);

    sheet.appendRow([
      excel_lib.TextCellValue("Fecha"),
      excel_lib.TextCellValue("Producto"),
      excel_lib.TextCellValue("Cantidad"),
      excel_lib.TextCellValue("P. Unitario"),
      excel_lib.TextCellValue("Total"),
      excel_lib.TextCellValue("Vendedor"),
      excel_lib.TextCellValue("Observaciones"),
    ]);
    
    for (var venta in ventasFiltradas) {
      sheet.appendRow([
        excel_lib.TextCellValue(DateFormat('dd/MM/yyyy').format(DateTime.parse(venta['fecha']))),
        excel_lib.TextCellValue(venta['producto'].toString()),
        excel_lib.IntCellValue(_toInt(venta['cantidad'])),
        excel_lib.DoubleCellValue(_toDouble(venta['precio_unitario'])),
        excel_lib.DoubleCellValue(_toDouble(venta['total'])),
        excel_lib.TextCellValue(venta['vendedor']?.toString() ?? 'N/A'),
        excel_lib.TextCellValue(venta['observaciones']?.toString() ?? ''),
      ]);
    }
    
    sheet.appendRow([excel_lib.TextCellValue("")]);
    sheet.appendRow([
      excel_lib.TextCellValue(""),
      excel_lib.TextCellValue("TOTALES:"),
      excel_lib.IntCellValue(cantidadProductosVendidos),
      excel_lib.TextCellValue(""),
      excel_lib.DoubleCellValue(totalVentas),
      excel_lib.TextCellValue(""),
      excel_lib.TextCellValue(""),
    ]);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/reporte_ventas_${DateTime.now().millisecondsSinceEpoch}.xlsx");
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Excel guardado: ${file.path}"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: "Abrir",
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al exportar: $e")),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Reportes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: azul,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FILTROS
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Filtros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          
                          // Período
                          DropdownButtonFormField<String>(
                            value: periodoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: "Período",
                              border: OutlineInputBorder(),
                            ),
                            items: ["Día", "Mes", "Año"].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  periodoSeleccionado = newValue;
                                  
                                  // Ajustar fechas según el período seleccionado
                                  final ahora = DateTime.now();
                                  if (newValue == "Mes") {
                                    fechaInicio = DateTime(ahora.year, ahora.month, 1);
                                    fechaFin = DateTime(ahora.year, ahora.month + 1, 0);
                                  } else if (newValue == "Año") {
                                    fechaInicio = DateTime(ahora.year, 1, 1);
                                    fechaFin = DateTime(ahora.year, 12, 31);
                                  } else {
                                    fechaInicio = ahora;
                                    fechaFin = ahora;
                                  }
                                  
                                  _calcularEstadisticas();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Rango de fechas
                          OutlinedButton.icon(
                            onPressed: _seleccionarRangoFechas,
                            icon: const Icon(Icons.date_range),
                            label: Text(textoRangoFechas),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Producto
                          DropdownButtonFormField<String>(
                            value: productoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: "Producto",
                              border: OutlineInputBorder(),
                            ),
                            items: productos.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  productoSeleccionado = newValue;
                                  _calcularEstadisticas();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // RESUMEN
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.monetization_on, size: 32, color: Colors.green),
                                const SizedBox(height: 8),
                                Text(
                                  "S/ ${totalVentas.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const Text("Total Ventas"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2, size: 32, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  "$cantidadProductosVendidos",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const Text("Productos"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // GRÁFICO
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ventas por Período", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: _buildGrafico(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BOTONES DE EXPORTACIÓN
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportarPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("Exportar PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportarExcel,
                          icon: const Icon(Icons.table_chart),
                          label: const Text("Exportar Excel"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  Widget _buildGrafico() {
    final datos = ventasPorPeriodo.entries.toList();
    
    if (datos.isEmpty || datos.every((e) => e.value == 0)) {
      return const Center(
        child: Text(
          "No hay datos para mostrar",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }


    final maxY = datos.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    

    double interval;
    if (maxY <= 100) {
      interval = 20.0;
    } else if (maxY <= 500) {
      interval = 50.0;
    } else if (maxY <= 1000) {
      interval = 100.0;
    } else if (maxY <= 5000) {
      interval = 500.0;
    } else if (maxY <= 10000) {
      interval = 1000.0;
    } else {
      interval = (maxY / 10).ceilToDouble();
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                "S/ ${rod.toY.toStringAsFixed(2)}",
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < datos.length) {
                  String label = datos[value.toInt()].key;
                  
                  // Acortar etiquetas si son muy largas
                  if (label.length > 10) {
                    label = label.substring(0, 8) + '...';
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  );
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: interval,
              getTitlesWidget: (value, meta) {
                // Formatear números grandes
                String texto;
                if (value >= 10000) {
                  texto = '${(value / 1000).toStringAsFixed(0)}k';
                } else if (value >= 1000) {
                  texto = '${(value / 1000).toStringAsFixed(1)}k';
                } else {
                  texto = value.toInt().toString();
                }
                
                return Text(
                  texto,
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        barGroups: datos.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: azul,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}