import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';
import '../services/category_service.dart';
import '../providers/auth_provider.dart';
import '../models/categoria.dart';

class AnadirProductoScreen extends StatefulWidget {
  const AnadirProductoScreen({super.key});

  @override
  State<AnadirProductoScreen> createState() => _AnadirProductoScreenState();
}

class _AnadirProductoScreenState extends State<AnadirProductoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioCompraController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _precioDolarController = TextEditingController(text: '3.80');
  final TextEditingController _codigoProductoController = TextEditingController();
  final TextEditingController _codigoDocumentoController = TextEditingController();
  final TextEditingController _utilidadController = TextEditingController(text: '0.00');
  final TextEditingController _margenController = TextEditingController(text: '0.00');
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  // Variables para categorías
  int? _tipoSeleccionadoId;
  int? _marcaSeleccionadaId;
  
  // Listas de categorías desde el backend
  List<Categoria> _tiposDisponibles = [];
  List<Categoria> _marcasDisponibles = [];
  bool _cargandoCategorias = true;

  // Variables existentes
  String? _tipoDocumento;
  bool _generarCodigoProductoAutomatico = false;
  bool _generarCodigoDocumentoAutomatico = false;
  String _monedaCompra = 'Soles';
  File? _archivoPDF;
  bool _isLoading = false;
  DateTime _fechaIngreso = DateTime.now();
  String? _rolUsuario;

  @override
  void initState() {
    super.initState();
    _precioCompraController.addListener(_calcularUtilidadMargen);
    _precioVentaController.addListener(_calcularUtilidadMargen);
    _precioDolarController.addListener(_calcularUtilidadMargen);
    _cargarRolUsuario();
    _cargarCategorias(); 
  }

  // CARGAR CATEGORÍAS DESDE EL BACKEND
  Future<void> _cargarCategorias() async {
    setState(() => _cargandoCategorias = true);
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final categoryService = CategoryService(apiService);

      final tipos = await categoryService.obtenerTipos(context);
      final marcas = await categoryService.obtenerMarcas(context);

      setState(() {
        _tiposDisponibles = tipos;
        _marcasDisponibles = marcas;
        _cargandoCategorias = false;
      });

      print('Categorías cargadas: ${tipos.length} tipos, ${marcas.length} marcas');
    } catch (e) {
      setState(() => _cargandoCategorias = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar categorías: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _cargarRolUsuario() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _rolUsuario = authProvider.usuario?.rol ?? 'trabajador';
    });
  }

  void _calcularUtilidadMargen() {
    final precioCompra = double.tryParse(_precioCompraController.text) ?? 0;
    final tipoCambio = double.tryParse(_precioDolarController.text) ?? 3.80;
    final precioVenta = double.tryParse(_precioVentaController.text) ?? 0;

    final precioFinalSoles = _monedaCompra == 'Dólar' ? precioCompra * tipoCambio : precioCompra;
    final utilidad = precioVenta - precioFinalSoles;
    final margen = precioVenta > 0 ? (utilidad / precioVenta) * 100 : 0;

    setState(() {
      _utilidadController.text = utilidad.toStringAsFixed(2);
      _margenController.text = margen.toStringAsFixed(2);
    });
  }

  String _generarCodigoProducto() {
    final random = Random();
    return 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${random.nextInt(1000)}';
  }

  String _generarCodigoDocumento() {
    final random = Random();
    return 'DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-${random.nextInt(999)}';
  }

  Future<void> _seleccionarPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _archivoPDF = File(result.files.single.path!);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF seleccionado: ${result.files.single.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar PDF: $e')),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _fechaIngreso) {
      setState(() {
        _fechaIngreso = picked;
      });
    }
  }

  void _onDocumentoChanged(String? value) {
    setState(() {
      _tipoDocumento = value;
      _archivoPDF = null;
      _codigoDocumentoController.clear();
      _generarCodigoDocumentoAutomatico = false;

      if (_tipoDocumento == 'Sin documento') {
        _generarCodigoDocumentoAutomatico = true;
        _codigoDocumentoController.text = _generarCodigoDocumento();
      }
    });
  }

  bool get _mostrarBotonPDF {
    return _tipoDocumento == 'Factura' ||
        _tipoDocumento == 'Boleta' ||
        _tipoDocumento == 'Guía de remisión';
  }

  // REGISTRAR PRODUCTO 
  Future<void> _registrarProducto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mostrarBotonPDF && _archivoPDF == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes seleccionar el PDF del documento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final productService = ProductService(apiService);

      // Enviar IDs de categorías, no strings
      final data = {
        'nombre_producto': _nombreController.text,
        'codigo': _codigoProductoController.text,
        'numero_serie': _codigoDocumentoController.text,
        'documento_producto': _tipoDocumento ?? 'Sin documento',
        'precio_compra': _precioCompraController.text,
        'precio_venta': _precioVentaController.text,
        'tipo': _tipoSeleccionadoId?.toString() ?? '',
        'marca': _marcaSeleccionadaId?.toString() ?? '',
        'color': _colorController.text,
        'cantidad': _cantidadController.text,
        'ubicacion': _ubicacionController.text,
        'fecha_ingreso': _fechaIngreso.toIso8601String(),
        'moneda_compra': _monedaCompra,
        'tipo_cambio': _precioDolarController.text,
      };

      await productService.agregarProducto(data, _archivoPDF);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Producto registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al registrar producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // SOLICITAR REVISIÓN 
  Future<void> _enviarSolicitudRevision() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mostrarBotonPDF && _archivoPDF == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes seleccionar el PDF del documento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Obtener nombres de las categorías seleccionadas para el mensaje
      final tipoNombre = _tiposDisponibles
          .firstWhere((t) => t.id == _tipoSeleccionadoId, orElse: () => Categoria(
            id: 0, nombre: 'N/A', tipo: 'tipo', estado: 'activa', fechaCreacion: DateTime.now()
          ))
          .nombre;
      
      final marcaNombre = _marcasDisponibles
          .firstWhere((m) => m.id == _marcaSeleccionadaId, orElse: () => Categoria(
            id: 0, nombre: 'N/A', tipo: 'marca', estado: 'activa', fechaCreacion: DateTime.now()
          ))
          .nombre;

      final productoData = {
        'nombre_producto': _nombreController.text,
        'codigo': _codigoProductoController.text,
        'numero_serie': _codigoDocumentoController.text,
        'documento_producto': _tipoDocumento ?? 'Sin documento',
        'precio_compra': _precioCompraController.text,
        'precio_venta': _precioVentaController.text,
        'tipo': _tipoSeleccionadoId?.toString() ?? '', 
        'marca': _marcaSeleccionadaId?.toString() ?? '', 
        'color': _colorController.text,
        'cantidad': _cantidadController.text,
        'ubicacion': _ubicacionController.text,
        'fecha_ingreso': _fechaIngreso.toIso8601String(),
        'moneda_compra': _monedaCompra,
        'tipo_cambio': _precioDolarController.text,
      };

      final solicitudData = {
        'usuario_id': auth.usuario?.id ?? '',
        'detalles': '''
📦 SOLICITUD DE REVISIÓN - NUEVO PRODUCTO

👤 Usuario: ${auth.usuario?.nombre ?? 'Desconocido'}
📅 Fecha: ${DateTime.now().toString().split('.')[0]}

📝 INFORMACIÓN DEL PRODUCTO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Nombre: ${_nombreController.text}
- Código: ${_codigoProductoController.text}
- Tipo: $tipoNombre
- Marca: $marcaNombre
- Color: ${_colorController.text}

💰 PRECIOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Precio Compra: ${_monedaCompra} ${_precioCompraController.text}
- Precio Venta: S/ ${_precioVentaController.text}
- Utilidad: S/ ${_utilidadController.text}
- Margen: ${_margenController.text}%

📊 STOCK:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Cantidad: ${_cantidadController.text}
- Ubicación: ${_ubicacionController.text}

📄 DOCUMENTO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Tipo: ${_tipoDocumento ?? 'Sin documento'}
- Serie: ${_codigoDocumentoController.text}
- PDF: ${_archivoPDF != null ? '✓ Adjunto' : '✗ No adjunto'}
        ''',
        'producto_data': productoData,
      };

      await apiService.post(context, '/api/solicitudes', solicitudData);

      final notificacionData = {
        'titulo': 'Nueva solicitud de producto',
        'mensaje': '${auth.usuario?.nombre ?? 'Usuario'} solicitó revisar un nuevo producto: ${_nombreController.text}',
        'tipo': 'solicitud',
      };

      await apiService.post(context, '/api/notificaciones', notificacionData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Solicitud enviada al gerente para revisión',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esGerente = _rolUsuario == 'gerente';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Añadir Producto'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  title: '📝 Información del Producto',
                  children: [
                    _buildTextField(
                      controller: _codigoProductoController,
                      label: 'Código del Producto',
                      enabled: !_generarCodigoProductoAutomatico,
                      validator: (v) {
                        if (!_generarCodigoProductoAutomatico && (v == null || v.isEmpty)) {
                          return 'Ingresa el código o genera uno automáticamente';
                        }
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _generarCodigoProductoAutomatico,
                          onChanged: (value) {
                            setState(() {
                              _generarCodigoProductoAutomatico = value ?? false;
                              if (_generarCodigoProductoAutomatico) {
                                _codigoProductoController.text = _generarCodigoProducto();
                              } else {
                                _codigoProductoController.clear();
                              }
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Generar código automáticamente',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre del Producto',
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(),
                    if (_tipoDocumento == 'Sin documento') ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _codigoDocumentoController,
                        label: 'Código de Documento (Generado automáticamente)',
                        readOnly: true,
                      ),
                    ],
                    if (_mostrarBotonPDF) ...[
                      const SizedBox(height: 16),
                      _buildPdfButton(),
                    ],
                    const SizedBox(height: 16),
                    
                    // DROPDOWN DINÁMICO PARA TIPO 
                    _buildTipoDropdown(),
                    
                    const SizedBox(height: 16),
                    
                    // DROPDOWN DINÁMICO PARA MARCA
                    _buildMarcaDropdown(),
                    
                    const SizedBox(height: 16),
                    _buildTextField(controller: _colorController, label: 'Color'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cantidadController,
                      label: 'Cantidad',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _ubicacionController,
                      label: 'Ubicación',
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: '💰 Precios',
                  children: [
                    DropdownButtonFormField<String>(
                      value: _monedaCompra,
                      decoration: InputDecoration(
                        labelText: 'Moneda de Compra',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Soles', child: Text('Soles')),
                        DropdownMenuItem(value: 'Dólar', child: Text('Dólar')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _monedaCompra = v!;
                          _calcularUtilidadMargen();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _precioCompraController,
                      label: 'Precio de Compra',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_monedaCompra == 'Dólar') ...[
                      _buildTextField(
                        controller: _precioDolarController,
                        label: 'Tipo de Cambio',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      controller: _precioVentaController,
                      label: 'Precio de Venta',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _utilidadController,
                      label: 'Utilidad',
                      readOnly: true,
                      fillColor: Colors.grey[100],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _margenController,
                      label: 'Margen (%)',
                      readOnly: true,
                      fillColor: Colors.grey[100],
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (esGerente)
                  ElevatedButton.icon(
                    onPressed: _registrarProducto,
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Producto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _registrarProducto,
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _enviarSolicitudRevision,
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Revisar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _tipoDocumento,
      decoration: InputDecoration(
        labelText: 'Tipo de Documento',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const [
        DropdownMenuItem(value: 'Sin documento', child: Text('Sin documento')),
        DropdownMenuItem(value: 'Factura', child: Text('Factura')),
        DropdownMenuItem(value: 'Boleta', child: Text('Boleta')),
        DropdownMenuItem(value: 'Guía de remisión', child: Text('Guía de remisión')),
      ],
      onChanged: _onDocumentoChanged,
    );
  }

  Widget _buildPdfButton() {
    return ElevatedButton.icon(
      onPressed: _seleccionarPDF,
      icon: const Icon(Icons.picture_as_pdf),
      label: Text(_archivoPDF != null ? 'PDF seleccionado ✓' : 'Seleccionar PDF del Documento'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _archivoPDF != null ? Colors.green : Colors.redAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // DROPDOWN DINÁMICO PARA TIPOS
  Widget _buildTipoDropdown() {
    if (_cargandoCategorias) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tiposDisponibles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No hay tipos disponibles',
            style: TextStyle(color: Colors.orange),
          ),
          TextButton.icon(
            onPressed: _cargarCategorias,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      value: _tipoSeleccionadoId,
      decoration: InputDecoration(
        labelText: 'Tipo',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _tiposDisponibles.map((tipo) {
        return DropdownMenuItem<int>(
          value: tipo.id,
          child: Text(tipo.nombre),
        );
      }).toList(),
      onChanged: (value) => setState(() => _tipoSeleccionadoId = value),
      validator: (value) => value == null ? 'Selecciona un tipo' : null,
    );
  }

  // DROPDOWN DINÁMICO PARA MARCAS
  Widget _buildMarcaDropdown() {
    if (_cargandoCategorias) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_marcasDisponibles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No hay marcas disponibles',
            style: TextStyle(color: Colors.orange),
          ),
          TextButton.icon(
            onPressed: _cargarCategorias,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      value: _marcaSeleccionadaId,
      decoration: InputDecoration(
        labelText: 'Marca',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _marcasDisponibles.map((marca) {
        return DropdownMenuItem<int>(
          value: marca.id,
          child: Text(marca.nombre),
        );
      }).toList(),
      onChanged: (value) => setState(() => _marcaSeleccionadaId = value),
      validator: (value) => value == null ? 'Selecciona una marca' : null,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? (fillColor ?? Colors.white) : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de Ingreso',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          "${_fechaIngreso.day}/${_fechaIngreso.month}/${_fechaIngreso.year}",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _precioDolarController.dispose();
    _codigoProductoController.dispose();
    _codigoDocumentoController.dispose();
    _utilidadController.dispose();
    _margenController.dispose();
    _colorController.dispose();
    _cantidadController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }
}