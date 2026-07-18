import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nsg_inventario/screens/anadir_producto_screen.dart';
import 'package:nsg_inventario/screens/visor_pdf_screen.dart';
import 'editar_producto_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/category_service.dart';
import '../models/categoria.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({Key? key}) : super(key: key);

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<dynamic> _inventario = [];
  List<dynamic> _inventarioFiltrado = [];
  bool _cargando = true;

  String _busqueda = "";
  int? _filtroTipoId;
  int? _filtroMarcaId;

  List<Categoria> _tiposDisponibles = [];
  List<Categoria> _marcasDisponibles = [];
  bool _cargandoCategorias = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarInventario();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargandoCategorias = true);
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final categoryService = CategoryService(apiService);

      final tipos = await categoryService.obtenerTipos(context);
      final marcas = await categoryService.obtenerMarcas(context);

      tipos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      marcas.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      setState(() {
        _tiposDisponibles = tipos;
        _marcasDisponibles = marcas;
        _cargandoCategorias = false;
      });

      print('✅ Tipos disponibles para filtrar:');
      for (var tipo in tipos) {
        print('   ID: ${tipo.id}, Nombre: ${tipo.nombre}');
      }
      
      print('✅ Marcas disponibles para filtrar:');
      for (var marca in marcas) {
        print('   ID: ${marca.id}, Nombre: ${marca.nombre}');
      }
    } catch (e) {
      setState(() => _cargandoCategorias = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error al cargar categorías: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _cargarInventario() async {
    setState(() => _cargando = true);
    try {
      final response = await http.get(
        Uri.parse("https://nsglatinoamerica.duckdns.org/api/productos"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📦 ========================================');
        print('📦 PRODUCTOS RECIBIDOS DEL BACKEND');
        print('📦 ========================================');
        print('📦 Total productos: ${data.length}');
        
        if (data.isNotEmpty) {
          print('📦 Ejemplo de producto (primero de la lista):');
          final primer = data[0];
          print('   - nombre_producto: ${primer['nombre_producto']}');
          print('   - tipo (ID): ${primer['tipo']} (${primer['tipo'].runtimeType})');
          print('   - marca (ID): ${primer['marca']} (${primer['marca'].runtimeType})');
          print('   - nombre_tipo: ${primer['nombre_tipo']}');
          print('   - nombre_marca: ${primer['nombre_marca']}');
        }
        print('📦 ========================================\n');
        
        setState(() {
          _inventario = data;
          _aplicarFiltros();
          _cargando = false;
        });
      } else {
        throw Exception("Error al cargar inventario");
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar inventario: $e")),
        );
      }
    }
  }

  Future<void> _eliminarProducto(int id, String nombre) async {
    if (!mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: Text("¿Deseas eliminar el producto '$nombre'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    bool dialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          dialogShown = true;
          return WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Eliminando producto..."),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("⚠️ Error al mostrar diálogo de carga: $e");
    }

    try {
      debugPrint("🗑️ Iniciando eliminación del producto ID: $id");

      final response = await http.delete(
        Uri.parse("https://nsglatinoamerica.duckdns.org/api/productos/$id"),
        headers: {
          "Content-Type": "application/json",
        },
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception("Tiempo de espera agotado. Verifica tu conexión.");
        },
      );

      debugPrint("📡 Status Code: ${response.statusCode}");
      debugPrint("📄 Response Body: ${response.body}");

      if (dialogShown && mounted) {
        try {
          navigator.pop();
        } catch (e) {
          debugPrint("⚠️ Error al cerrar diálogo: $e");
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          setState(() {
            _inventario.removeWhere((p) => p['id_producto'] == id);
            _aplicarFiltros();
          });

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text("Producto '$nombre' eliminado correctamente"),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        String mensajeError = "Error desconocido (${response.statusCode})";

        try {
          final errorData = json.decode(response.body);
          
          if (errorData['error'] == 'HAS_SALES') {
            mensajeError = "${errorData['detalle']}\n\n${errorData['info']}";
          } else {
            mensajeError = errorData['message'] ??
                errorData['error'] ??
                errorData['detalle'] ??
                mensajeError;
          }
        } catch (e) {
          if (response.body.isNotEmpty && response.body.length < 200) {
            mensajeError = response.body;
          }
        }

        throw Exception(mensajeError);
      }
    } catch (e) {
      debugPrint("❌ Error al eliminar producto: $e");

      if (dialogShown && mounted) {
        try {
          navigator.pop();
        } catch (navError) {
          debugPrint("⚠️ Error al cerrar diálogo: $navError");
        }
      }

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Error al eliminar: ${e.toString().replaceAll('Exception: ', '')}",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: "Reintentar",
              textColor: Colors.white,
              onPressed: () {
                if (mounted) _eliminarProducto(id, nombre);
              },
            ),
          ),
        );
      }
    }
  }

  // FILTROS
  void _aplicarFiltros() {
    print('\n🔍 ========================================');
    print('🔍 APLICANDO FILTROS');
    print('🔍 ========================================');
    print('🔍 Filtro Tipo ID seleccionado: $_filtroTipoId');
    print('🔍 Filtro Marca ID seleccionado: $_filtroMarcaId');
    print('🔍 Búsqueda: "$_busqueda"');
    
    setState(() {
      _inventarioFiltrado = _inventario.where((p) {
        final producto = p as Map<String, dynamic>;
        final nombre = (producto['nombre_producto'] ?? '').toString().toLowerCase();
        
        //  Obtener IDs del producto
        int? tipoIdProducto;
        int? marcaIdProducto;
        
        // Convertir a int de forma segura
        if (producto['tipo'] != null) {
          tipoIdProducto = producto['tipo'] is int 
              ? producto['tipo'] as int 
              : int.tryParse(producto['tipo'].toString());
        }
        
        if (producto['marca'] != null) {
          marcaIdProducto = producto['marca'] is int 
              ? producto['marca'] as int 
              : int.tryParse(producto['marca'].toString());
        }

        // Aplicar filtros
        final filtroNombre = _busqueda.isEmpty || nombre.contains(_busqueda.toLowerCase());
        final filtroTipoOk = _filtroTipoId == null || tipoIdProducto == _filtroTipoId;
        final filtroMarcaOk = _filtroMarcaId == null || marcaIdProducto == _filtroMarcaId;

        final pasa = filtroNombre && filtroTipoOk && filtroMarcaOk;
        
        if (_filtroTipoId != null || _filtroMarcaId != null) {
          print('   Producto: ${producto['nombre_producto']}');
          print('     - tipo ID: $tipoIdProducto');
          print('     - marca ID: $marcaIdProducto');
          print('     - ¿Pasa filtros? $pasa');
        }

        return pasa;
      }).toList();
      
      print('✅ Productos después de filtrar: ${_inventarioFiltrado.length}');
      print('🔍 ========================================\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final esGerente = authProvider.usuario?.rol == 'gerente';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Inventario", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _cargando || _cargandoCategorias
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Buscador
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Buscar producto...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        _busqueda = value;
                        _aplicarFiltros();
                      },
                    ),
                  ),
                  
                  // Filtros
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _filtroTipoId,
                            decoration: InputDecoration(
                              labelText: "Tipo",
                              labelStyle: const TextStyle(fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                              ),
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  "Todos",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              ..._tiposDisponibles.map((tipo) {
                                return DropdownMenuItem<int?>(
                                  value: tipo.id,
                                  child: Text(
                                    tipo.nombre,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              print('🔧 Usuario seleccionó tipo ID: $value');
                              setState(() {
                                _filtroTipoId = value;
                                _aplicarFiltros();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _filtroMarcaId,
                            decoration: InputDecoration(
                              labelText: "Marca",
                              labelStyle: const TextStyle(fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                              ),
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  "Todas",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              ..._marcasDisponibles.map((marca) {
                                return DropdownMenuItem<int?>(
                                  value: marca.id,
                                  child: Text(
                                    marca.nombre,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              print('🔧 Usuario seleccionó marca ID: $value');
                              setState(() {
                                _filtroMarcaId = value;
                                _aplicarFiltros();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Contador
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              "Productos encontrados:",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_inventarioFiltrado.length}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  //Lista
                  Expanded(child: _buildList(_inventarioFiltrado, esGerente)),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<dynamic> data, bool esGerente) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No hay productos disponibles",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              "Intenta cambiar los filtros",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _cargarCategorias();
        await _cargarInventario();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final producto = data[index] as Map<String, dynamic>;
          final id = producto['id_producto'];
          final nombre = producto['nombre_producto'] ?? 'Sin nombre';
          
          // USAR LOS NOMBRES DEL BACKEND
          final nombreTipo = producto['nombre_tipo'] ?? 'N/A';
          final nombreMarca = producto['nombre_marca'] ?? 'N/A';
          
          final cantidad = producto['cantidad'] ?? 0;

          final tieneDocumento = producto['documento_url'] != null &&
              producto['documento_url'].toString().isNotEmpty;

          Color badgeColor;
          if (cantidad == 0) {
            badgeColor = Colors.red;
          } else if (cantidad <= 5) {
            badgeColor = Colors.orange;
          } else {
            badgeColor = Colors.green;
          }

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.blueAccent,
                    size: 26,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$cantidad",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              nombreMarca,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              nombreTipo,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tieneDocumento)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          tooltip: "Ver documento",
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final urlDocumento = producto['documento_url'].toString();
                            final nombreArchivo = nombre.replaceAll(' ', '_').toLowerCase();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VisorPDFScreen(
                                  url: urlDocumento,
                                  nombreArchivo: nombreArchivo,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        tooltip: "Editar producto",
                        icon: const Icon(Icons.edit, color: Colors.orangeAccent, size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditarProductoScreen(producto: producto),
                            ),
                          ).then((value) {
                            if (value == true) _cargarInventario();
                          });
                        },
                      ),
                    ),
                    
                    if (esGerente)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          tooltip: "Eliminar producto",
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _eliminarProducto(id, nombre);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}