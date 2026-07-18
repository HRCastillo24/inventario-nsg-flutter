import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/inventario_service.dart';
import '../services/venta_service.dart';
import '../services/comprobante_interno_service.dart';
import '../providers/auth_provider.dart';

class RegistrarVentaScreen extends StatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  State<RegistrarVentaScreen> createState() => _RegistrarVentaScreenState();
}

class ProductoVenta {
  final int idProducto;
  final String nombre;
  final String codigo;
  int cantidad;
  final double precioUnitario;
  final int stockDisponible;
  String? observacion;

  ProductoVenta({
    required this.idProducto,
    required this.nombre,
    required this.codigo,
    required this.cantidad,
    required this.precioUnitario,
    required this.stockDisponible,
    this.observacion,
  });

  double get subtotal => cantidad * precioUnitario;
}

// Modelo para agrupar productos en combo visualmente
class GrupoCombo {
  final String nombreCombo;
  final String tipoDescuento;
  final double valorDescuento;
  final List<ProductoVenta> productos;

  GrupoCombo({
    required this.nombreCombo,
    required this.tipoDescuento,
    required this.valorDescuento,
    required this.productos,
  });

  double get subtotalOriginal => productos.fold(0, (sum, p) => sum + p.subtotal);
  
  double get descuentoAplicado {
    if (tipoDescuento == 'porcentaje') {
      return subtotalOriginal * (valorDescuento / 100);
    }
    return valorDescuento;
  }
  
  double get precioFinal => subtotalOriginal - descuentoAplicado;
}

class _RegistrarVentaScreenState extends State<RegistrarVentaScreen> {
  late InventarioService _inventarioService;
  late VentaService _ventaService;
  late ComprobanteInternoService _comprobanteService;
  List<dynamic> productos = [];
  List<ProductoVenta> productosEnVenta = [];
  List<GrupoCombo> combosCreados = [];

  bool cargando = false;
  bool _productosCargados = false;
  DateTime fechaSeleccionada = DateTime.now();

  final TextEditingController _descuentoController = TextEditingController(text: "0");
  final double _igvFijo = 18.0;
  String _metodoPagoSeleccionado = 'efectivo';

  final Color azul = Colors.blueAccent;
  final Color verde = Colors.green;
  final Color naranja = Colors.orange;
  final Color grisFondo = const Color(0xFFF5F5F5);
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    final api = ApiService(baseUrl: "https://nsglatinoamerica.duckdns.org");
    _inventarioService = InventarioService(api);
    _ventaService = VentaService(api);
    _comprobanteService = ComprobanteInternoService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_productosCargados) {
      _productosCargados = true;
      _cargarProductos();
    }
  }

  @override
  void dispose() {
    _descuentoController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    if (!mounted) return;
    setState(() => cargando = true);
    try {
      final lista = await _inventarioService.getProductos(context);
      if (mounted) {
        setState(() {
          productos = lista;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar productos: $e")),
        );
      }
    }
  }

  // CALCULOS 
  double get subtotalVenta {
    return productosEnVenta.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get descuentoTotalCombos {
    return combosCreados.fold(0.0, (sum, combo) => sum + combo.descuentoAplicado);
  }

  double get montoDescuento {
    final descuento = double.tryParse(_descuentoController.text) ?? 0;
    final descuentoValido = descuento >= 100 ? 99 : descuento;
    return subtotalVenta * (descuentoValido / 100);
  }

  double get subtotalConDescuento {
    return subtotalVenta - montoDescuento - descuentoTotalCombos;
  }

  double get montoIgv {
    return subtotalConDescuento * (_igvFijo / 100);
  }

  double get totalVenta {
    return subtotalConDescuento + montoIgv;
  }
  // Mostrar dialog para datos del cliente
  Future<Map<String, String>?> _mostrarDialogDatosCliente() async {
    final TextEditingController nombreCtrl = TextEditingController();
    final TextEditingController docCtrl = TextEditingController();
    final TextEditingController obsCtrl = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_outline, color: azul),
            const SizedBox(width: 12),
            const Text("Datos del Cliente"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: "Nombre del cliente (opcional)",
                  hintText: "Ej: Juan Pérez",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: docCtrl,
                decoration: InputDecoration(
                  labelText: "DNI/RUC (opcional)",
                  hintText: "12345678",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                decoration: InputDecoration(
                  labelText: "Observaciones (opcional)",
                  hintText: "Notas adicionales",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estos datos son opcionales. Si los dejas vacíos, se generará como "Cliente General"',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'nombre': nombreCtrl.text.trim(),
                'documento': docCtrl.text.trim(),
                'observaciones': obsCtrl.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: azul,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Generar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 NUEVO MÉTODO: Generar comprobante interno
  Future<void> _generarComprobanteInterno() async {
    if (productosEnVenta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ No hay productos en la venta"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Solicitar datos del cliente
    final datosCliente = await _mostrarDialogDatosCliente();
    
    if (datosCliente == null) {
      return;
    }

    setState(() => cargando = true);

    try {
      // Generar número de comprobante
      final numeroComprobante = 'CV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      // Preparar productos para el PDF
      final productosParaPDF = productosEnVenta.map((p) => {
        'nombre_producto': p.nombre,
        'cantidad': p.cantidad,
        'precio_unitario': p.precioUnitario,
        'observaciones': p.observacion ?? '',
      }).toList();

      // Generar PDF
      await _comprobanteService.generarComprobanteInterno(
        context: context,
        nombreEmpresa: "NSG LATINOAMERICA EIRL",
        rucEmpresa: "20441807741",
        direccionEmpresa: "Av. Grau A-12",
        telefonoEmpresa: "998256029 / 944676900",
        numeroComprobante: numeroComprobante,
        fechaEmision: fechaSeleccionada,
        nombreCliente: datosCliente['nombre'] ?? '',
        documentoCliente: datosCliente['documento'] ?? '',
        productos: productosParaPDF,
        descuentoGeneral: double.tryParse(_descuentoController.text) ?? 0,
        descuentoCombos: descuentoTotalCombos,
        igv: _igvFijo,
        metodoPago: _metodoPagoSeleccionado,
        observaciones: datosCliente['observaciones'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Comprobante generado correctamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error al generar comprobante: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }
  // CREAR COMBO
  Future<void> _crearComboModal() async {
    final TextEditingController nombreComboCtrl = TextEditingController();
    final TextEditingController descuentoCtrl = TextEditingController();
    String tipoDescuento = 'porcentaje';
    List<dynamic> productosSeleccionados = [];
    Map<int, int> cantidades = {};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          // CALCULAR EN TIEMPO REAL
          double calcularSubtotalCombo() {
            return productosSeleccionados.fold(0.0, (sum, p) {
              final cant = cantidades[p['id_producto']] ?? 1;
              final precio = (p['precio_venta'] is num
                  ? p['precio_venta'].toDouble()
                  : double.tryParse(p['precio_venta'].toString()) ?? 0.0);
              return sum + (cant * precio);
            });
          }

          double calcularDescuentoEnSoles() {
            final descuentoValor = double.tryParse(descuentoCtrl.text) ?? 0;
            if (descuentoValor == 0) return 0;
            
            final subtotal = calcularSubtotalCombo();
            if (tipoDescuento == 'porcentaje') {
              return subtotal * (descuentoValor / 100);
            }
            return descuentoValor;
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: verde.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, color: verde, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Crear Combo/Oferta",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del combo
                        TextField(
                          controller: nombreComboCtrl,
                          decoration: InputDecoration(
                            labelText: "Nombre del combo *",
                            hintText: "Ej: Pack Gamer, Combo Oficina",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.label),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Selección de productos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Productos del combo (${productosSeleccionados.length})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // Modal para seleccionar productos
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (ctx) => DraggableScrollableSheet(
                                    initialChildSize: 0.7,
                                    minChildSize: 0.5,
                                    maxChildSize: 0.95,
                                    expand: false,
                                    builder: (_, scrollController) => Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          child: const Text(
                                            "Seleccionar Productos",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            itemCount: productos.length,
                                            itemBuilder: (context, index) {
                                              final prod = productos[index];
                                              final yaSeleccionado = productosSeleccionados
                                                  .any((p) => p['id_producto'] == prod['id_producto']);

                                              return ListTile(
                                                leading: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: verde.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(Icons.inventory_2, color: verde),
                                                ),
                                                title: Text(
                                                  prod["nombre_producto"],
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                subtitle: Text(
                                                  "${prod['codigo']} • Stock: ${prod['cantidad']} • S/ ${(prod['precio_venta'] is num ? prod['precio_venta'] : double.tryParse(prod['precio_venta'].toString()) ?? 0.0).toStringAsFixed(2)}",
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                ),
                                                trailing: yaSeleccionado
                                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                                    : null,
                                                enabled: prod['cantidad'] > 0,
                                                onTap: () {
                                                  if (prod['cantidad'] > 0) {
                                                    setStateModal(() {
                                                      if (!yaSeleccionado) {
                                                        productosSeleccionados.add(prod);
                                                        cantidades[prod['id_producto']] = 1;
                                                      }
                                                    });
                                                    Navigator.pop(ctx);
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_circle),
                              label: const Text("Agregar"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Lista de productos seleccionados
                        if (productosSeleccionados.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      size: 50, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No hay productos seleccionados",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...productosSeleccionados.map((prod) {
                            final cantidad = cantidades[prod['id_producto']] ?? 1;
                            final precio = (prod['precio_venta'] is num
                                ? prod['precio_venta'].toDouble()
                                : double.tryParse(prod['precio_venta'].toString()) ?? 0.0);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod['nombre_producto'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          "S/ ${precio.toStringAsFixed(2)} c/u",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: () {
                                          setStateModal(() {
                                            if (cantidad > 1) {
                                              cantidades[prod['id_producto']] = cantidad - 1;
                                            }
                                          });
                                        },
                                      ),
                                      Text(
                                        "$cantidad",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () {
                                          setStateModal(() {
                                            if (cantidad < prod['cantidad']) {
                                              cantidades[prod['id_producto']] = cantidad + 1;
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Stock máximo: ${prod['cantidad']}"),
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setStateModal(() {
                                        productosSeleccionados.remove(prod);
                                        cantidades.remove(prod['id_producto']);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                        const SizedBox(height: 20),
                        const Divider(),

                        // Tipo de descuento
                        const Text(
                          "Descuento del combo:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setStateModal(() {
                                    tipoDescuento = 'porcentaje';
                                    descuentoCtrl.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: tipoDescuento == 'porcentaje'
                                        ? verde.withOpacity(0.2)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: tipoDescuento == 'porcentaje'
                                          ? verde
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.percent,
                                        color: tipoDescuento == 'porcentaje'
                                            ? verde
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Porcentaje",
                                        style: TextStyle(
                                          fontWeight: tipoDescuento == 'porcentaje'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setStateModal(() {
                                    tipoDescuento = 'precio_fijo';
                                    descuentoCtrl.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: tipoDescuento == 'precio_fijo'
                                        ? verde.withOpacity(0.2)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: tipoDescuento == 'precio_fijo'
                                          ? verde
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        color: tipoDescuento == 'precio_fijo'
                                            ? verde
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Monto Fijo",
                                        style: TextStyle(
                                          fontWeight: tipoDescuento == 'precio_fijo'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descuentoCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: tipoDescuento == 'porcentaje'
                                ? "Descuento (%)"
                                : "Descuento (S/)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(
                              tipoDescuento == 'porcentaje'
                                  ? Icons.percent
                                  : Icons.money,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            setStateModal(() {});
                          },
                        ),

                        // 🔥 RESUMEN ACTUALIZADO EN TIEMPO REAL
                        if (productosSeleccionados.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Resumen del Combo:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("Productos: ${productosSeleccionados.length}"),
                                
                                Builder(
                                  builder: (context) {
                                    final subtotal = calcularSubtotalCombo();
                                    final descuentoEnSoles = calcularDescuentoEnSoles();
                                    final precioFinal = subtotal - descuentoEnSoles;
                                    final descuentoValor = double.tryParse(descuentoCtrl.text) ?? 0;
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Subtotal: S/ ${subtotal.toStringAsFixed(2)}"),
                                        
                                        if (descuentoValor > 0) ...[
                                          Text(
                                            "Descuento: ${tipoDescuento == 'porcentaje' ? '${descuentoValor.toStringAsFixed(0)}%' : 'S/ ${descuentoValor.toStringAsFixed(2)}'} (-S/ ${descuentoEnSoles.toStringAsFixed(2)})",
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Divider(height: 16),
                                          Text(
                                            "Precio Final: S/ ${precioFinal.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: verde,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validaciones
                            if (nombreComboCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("⚠️ Ingresa un nombre para el combo"),
                                ),
                              );
                              return;
                            }

                            if (productosSeleccionados.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("⚠️ Selecciona al menos un producto"),
                                ),
                              );
                              return;
                            }

                            final descuento = double.tryParse(descuentoCtrl.text) ?? 0;

                            if (tipoDescuento == 'porcentaje' && descuento >= 100) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("⚠️ El descuento no puede ser 100% o más"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            // Calcular subtotal del combo
                            final subtotalCombo = productosSeleccionados.fold(0.0, (sum, p) {
                              final cant = cantidades[p['id_producto']] ?? 1;
                              final precio = (p['precio_venta'] is num
                                  ? p['precio_venta'].toDouble()
                                  : double.tryParse(p['precio_venta'].toString()) ?? 0.0);
                              return sum + (cant * precio);
                            });

                            if (tipoDescuento == 'precio_fijo' && descuento >= subtotalCombo) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("⚠️ El descuento no puede ser mayor o igual al subtotal"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            // Crear el combo
                            final observacionCombo = "COMBO: ${nombreComboCtrl.text}";
                            List<ProductoVenta> productosCombo = [];

                            for (var prod in productosSeleccionados) {
                              productosCombo.add(ProductoVenta(
                                idProducto: prod["id_producto"],
                                nombre: prod["nombre_producto"],
                                codigo: prod["codigo"],
                                cantidad: cantidades[prod['id_producto']] ?? 1,
                                precioUnitario: (prod["precio_venta"] is num
                                    ? prod["precio_venta"].toDouble()
                                    : double.tryParse(prod["precio_venta"].toString()) ?? 0.0),
                                stockDisponible: prod["cantidad"],
                                observacion: observacionCombo,
                              ));
                            }

                            setState(() {
                              combosCreados.add(GrupoCombo(
                                nombreCombo: nombreComboCtrl.text,
                                tipoDescuento: tipoDescuento,
                                valorDescuento: descuento,
                                productos: productosCombo,
                              ));
                              productosEnVenta.addAll(productosCombo);
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ Combo '${nombreComboCtrl.text}' creado"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: verde,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Crear Combo",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _agregarProducto() {
    if (productos.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Seleccionar Producto",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: azul,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final prod = productos[index];
                  final yaAgregado = productosEnVenta.any(
                    (p) => p.idProducto == prod["id_producto"] && p.observacion == null,
                  );

                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: azul.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.inventory_2, color: azul),
                    ),
                    title: Text(
                      prod["nombre_producto"],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "${prod['codigo']} • Stock: ${prod['cantidad']} • S/ ${(prod['precio_venta'] is num ? prod['precio_venta'] : double.tryParse(prod['precio_venta'].toString()) ?? 0.0).toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: yaAgregado
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    enabled: !yaAgregado && prod['cantidad'] > 0,
                    onTap: () {
                      if (!yaAgregado && prod['cantidad'] > 0) {
                        setState(() {
                          productosEnVenta.add(ProductoVenta(
                            idProducto: prod["id_producto"],
                            nombre: prod["nombre_producto"],
                            codigo: prod["codigo"],
                            cantidad: 1,
                            precioUnitario: (prod["precio_venta"] is num
                                ? prod["precio_venta"].toDouble()
                                : double.tryParse(prod["precio_venta"].toString()) ?? 0.0),
                            stockDisponible: prod["cantidad"],
                          ));
                        });
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarProducto(int index) {
    setState(() => productosEnVenta.removeAt(index));
  }

  void _eliminarCombo(int indexCombo) {
    final combo = combosCreados[indexCombo];
    setState(() {
      productosEnVenta.removeWhere((p) => p.observacion == "COMBO: ${combo.nombreCombo}");
      combosCreados.removeAt(indexCombo);
    });
  }

  void _editarCantidad(int index, ProductoVenta producto) {
    final TextEditingController cantidadCtrl = TextEditingController(
      text: producto.cantidad.toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Cantidad"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto.nombre),
            Text("Stock disponible: ${producto.stockDisponible}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Cantidad",
                border: const OutlineInputBorder(),
                suffixText: "/ ${producto.stockDisponible}",
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevaCantidad = int.tryParse(cantidadCtrl.text) ?? 0;
              
              if (nuevaCantidad < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("⚠️ La cantidad debe ser mayor a 0"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              if (nuevaCantidad > producto.stockDisponible) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("⚠️ Stock insuficiente. Máximo: ${producto.stockDisponible}"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              setState(() => producto.cantidad = nuevaCantidad);
              Navigator.pop(context);
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }

  void _actualizarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad > 0 && nuevaCantidad <= productosEnVenta[index].stockDisponible) {
      setState(() => productosEnVenta[index].cantidad = nuevaCantidad);
    } else if (nuevaCantidad > productosEnVenta[index].stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Stock insuficiente. Máximo: ${productosEnVenta[index].stockDisponible}"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: azul,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (nuevaFecha != null) {
      setState(() => fechaSeleccionada = nuevaFecha);
    }
  }
  //  Registrar venta con opción de comprobante
  Future<void> _registrarVenta() async {
    if (productosEnVenta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Agrega al menos un producto")),
      );
      return;
    }

    // Preguntar si desea generar comprobante
    final generarComprobante = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: azul),
            const SizedBox(width: 12),
            const Text("¿Generar Comprobante?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "¿Deseas generar un comprobante de venta para esta operación?",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este comprobante es solo para control interno y no tiene valor tributario',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No, solo registrar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: azul,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Sí, generar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    setState(() => cargando = true);

    try {
      final idUsuarioStr = await _storage.read(key: 'id_usuario');
      int? idUsuario = int.tryParse(idUsuarioStr ?? '');

      if (idUsuario == null || idUsuario == 0) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.usuario != null) {
          idUsuario = int.tryParse(authProvider.usuario!.id);
        }
      }

      if (idUsuario == null || idUsuario == 0) {
        throw Exception("No se encontró el usuario. Inicia sesión nuevamente.");
      }

      final descuentoGeneral = double.tryParse(_descuentoController.text) ?? 0;

      final productosArray = productosEnVenta.map((p) => {
        "id_producto": p.idProducto,
        "cantidad_vendida": p.cantidad,
        "precio_unitario": p.precioUnitario,
        if (p.observacion != null) "observaciones": p.observacion,
      }).toList();

      // Registrar venta
      await _ventaService.registrarVenta(
        context,
        idUsuario: idUsuario,
        fechaVenta: fechaSeleccionada.toIso8601String(),
        descuento: descuentoGeneral.clamp(0, 99),
        igv: _igvFijo,
        metodoPago: _metodoPagoSeleccionado,
        productos: productosArray,
      );

      if (!mounted) return;

      // Si eligió generar comprobante, generarlo
      if (generarComprobante == true) {
        await _generarComprobanteInterno();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Venta registrada correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        productosEnVenta.clear();
        combosCreados.clear();
        _descuentoController.text = "0";
        fechaSeleccionada = DateTime.now();
        _metodoPagoSeleccionado = 'efectivo';
      });

      await _cargarProductos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosIndividuales = productosEnVenta.where((p) => p.observacion == null).toList();

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        title: const Text("Nueva Venta", style: TextStyle(color: Colors.white)),
        backgroundColor: azul,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fecha
                        InkWell(
                          onTap: _seleccionarFecha,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: azul, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(fechaSeleccionada),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Método de Pago
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.payment, color: azul, size: 20),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Método de Pago",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetodoPagoOption('efectivo', 'Efectivo', Icons.money),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetodoPagoOption('tarjeta', 'Tarjeta', Icons.credit_card),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetodoPagoOption('transferencia', 'Transfer.', Icons.account_balance),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // COMBOS CREADOS
                        if (combosCreados.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, color: verde, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Combos/Ofertas (${combosCreados.length})",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          ...List.generate(combosCreados.length, (index) {
                            final combo = combosCreados[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300, width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.card_giftcard, color: verde, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          combo.nombreCombo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: verde,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _eliminarCombo(index),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Text("Productos incluidos:", 
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  ...combo.productos.map((p) => Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 2),
                                    child: Text(
                                      "• ${p.nombre} (x${p.cantidad}) - S/ ${p.subtotal.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )).toList(),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Subtotal: S/ ${combo.subtotalOriginal.toStringAsFixed(2)}",
                                              style: const TextStyle(fontSize: 12)),
                                            Text(
                                              "Descuento: ${combo.tipoDescuento == 'porcentaje' ? '${combo.valorDescuento}%' : 'S/ ${combo.valorDescuento.toStringAsFixed(2)}'} (-S/ ${combo.descuentoAplicado.toStringAsFixed(2)})",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "S/ ${combo.precioFinal.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: verde,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                        // PRODUCTOS INDIVIDUALES
                        Row(
                          children: [
                            Icon(Icons.shopping_cart, color: azul, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Productos (${productosIndividuales.length})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (productosIndividuales.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      size: 50, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No hay productos en la venta",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(productosIndividuales.length, (index) {
                            final prod = productosIndividuales[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: azul.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.inventory_2, color: azul),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          "${prod.codigo} • S/ ${prod.precioUnitario.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: () => _actualizarCantidad(
                                          productosEnVenta.indexOf(prod),
                                          prod.cantidad - 1,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _editarCantidad(
                                          productosEnVenta.indexOf(prod),
                                          prod,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: azul.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "${prod.cantidad}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () => _actualizarCantidad(
                                          productosEnVenta.indexOf(prod),
                                          prod.cantidad + 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "S/ ${prod.subtotal.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        onPressed: () => _eliminarProducto(
                                          productosEnVenta.indexOf(prod),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 16),

                        // BOTONES DE ACCIÓN
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _crearComboModal,
                                icon: const Icon(Icons.card_giftcard, size: 20),
                                label: const Text("Crear Combo"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: verde,
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
                                onPressed: _agregarProducto,
                                icon: const Icon(Icons.add_shopping_cart, size: 20),
                                label: const Text("Agregar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: azul,
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
                        const SizedBox(height: 16),

                        // DESCUENTO GENERAL
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.discount, color: naranja, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Descuento General",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _descuentoController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Descuento (%)",
                                  hintText: "0",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.percent),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                onChanged: (value) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // RESUMEN DE LA VENTA
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [azul.withOpacity(0.1), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: azul.withOpacity(0.3), width: 2),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt_long, color: azul, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Resumen de Venta",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildResumenRow("Subtotal:", subtotalVenta),
                              if (montoDescuento > 0)
                                _buildResumenRow(
                                  "Descuento (${_descuentoController.text}%):",
                                  -montoDescuento,
                                  color: Colors.red,
                                ),
                              if (descuentoTotalCombos > 0)
                                _buildResumenRow(
                                  "Descuento Combos:",
                                  -descuentoTotalCombos,
                                  color: Colors.red,
                                ),
                              _buildResumenRow("IGV ($_igvFijo%):", montoIgv),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "TOTAL:",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "S/ ${totalVenta.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: verde,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTONES FINALES
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: productosEnVenta.isEmpty
                              ? null
                              : _generarComprobanteInterno,
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text("Comprobante"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: productosEnVenta.isEmpty
                                  ? Colors.grey
                                  : naranja,
                            ),
                            foregroundColor: naranja,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: productosEnVenta.isEmpty ? null : _registrarVenta,
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text("Registrar Venta"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: verde,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // HELPER: Fila del resumen
  Widget _buildResumenRow(String label, double monto, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.grey[800],
            ),
          ),
          Text(
            "S/ ${monto.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // HELPER: Botón de método de pago
  Widget _buildMetodoPagoOption(String valor, String label, IconData icon) {
    final seleccionado = _metodoPagoSeleccionado == valor;
    return InkWell(
      onTap: () => setState(() => _metodoPagoSeleccionado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? azul.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionado ? azul : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: seleccionado ? azul : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                color: seleccionado ? azul : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}