import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../services/category_service.dart';

class CategoriasScreen extends StatefulWidget {
  final CategoryService categoryService;

  const CategoriasScreen({Key? key, required this.categoryService}) : super(key: key);

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Categoria> _tipos = [];
  List<Categoria> _marcas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarCategorias();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tipos = await widget.categoryService.obtenerTipos(context);
      final marcas = await widget.categoryService.obtenerMarcas(context);

      tipos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      marcas.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      setState(() {
        _tipos = tipos;
        _marcas = marcas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar categorías: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  bool _existeCategoria(String nombre, String tipoCategoria) {
    final listaBuscar = tipoCategoria == 'tipo' ? _tipos : _marcas;
    return listaBuscar.any((cat) => 
      cat.nombre.trim().toLowerCase() == nombre.trim().toLowerCase()
    );
  }

  void _mostrarDialogoNuevaCategoria(String tipoCategoria) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tipoCategoria == 'tipo' ? Colors.blue.shade50 : const Color(0xFFE1BEE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tipoCategoria == 'tipo' ? Icons.category : Icons.branding_watermark,
                color: tipoCategoria == 'tipo' ? Colors.blue : const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              tipoCategoria == 'tipo' ? 'Nuevo Tipo' : 'Nueva Marca',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nombre *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  hintText: tipoCategoria == 'tipo' ? 'Ej: Laptop, Mouse, Monitor' : 'Ej: Dell, HP, Logitech',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              const Text(
                'Descripción (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  hintText: 'Descripción de la categoría',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre es obligatorio'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (_existeCategoria(nombre, tipoCategoria)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ya existe ${tipoCategoria == "tipo" ? "un tipo" : "una marca"} con el nombre "$nombre"'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Cerrar el diálogo ANTES de iniciar operaciones
              Navigator.pop(dialogContext);

              // Guardar referencia al context principal y ScaffoldMessenger
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => WillPopScope(
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
                            Text('Creando categoría...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );

              try {
                print('🔄 Creando categoría: $nombre ($tipoCategoria)');
                
                // Crear categoría
                await widget.categoryService.crearCategoria(
                  context,
                  nombre,
                  tipoCategoria,
                  descripcion: descripcionController.text.trim().isEmpty 
                    ? null 
                    : descripcionController.text.trim(),
                );

                print('✅ Categoría creada, recargando lista...');

                await _cargarCategorias();

                print('✅ Lista recargada, mostrando resultado');

                // Cerrar loading
                navigator.pop();

                // Mostrar éxito
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${tipoCategoria == "tipo" ? "Tipo" : "Marca"} "$nombre" creado exitosamente',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                print('❌ Error al crear: $e');
                
                // Cerrar loading
                navigator.pop();
                
                // Mostrar error
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Error: ${e.toString()}'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tipoCategoria == 'tipo' 
                ? Colors.blue 
                : const Color(0xFFCE93D8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Crear',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(Categoria categoria) {
    final esTipo = categoria.tipo == 'tipo';
    final color = esTipo ? Colors.blue : const Color(0xFF9C27B0);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  esTipo ? Icons.category : Icons.branding_watermark,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (categoria.descripcion != null && categoria.descripcion!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          categoria.descripcion!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            esTipo ? 'TIPO' : 'MARCA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          'ID: ${categoria.id}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'eliminar') {
                    _confirmarEliminar(categoria);
                  } else if (value == 'editar') {
                    _mostrarDialogoEditar(categoria);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(Categoria categoria) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar "${categoria.nombre}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cerrar diálogo de confirmación
              Navigator.pop(dialogContext);
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => WillPopScope(
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
                            Text('Eliminando categoría...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );

              try {
                await widget.categoryService.eliminarCategoria(context, categoria.id);
                await _cargarCategorias();
                
                navigator.pop();

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('"${categoria.nombre}" eliminado exitosamente'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                navigator.pop();
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Error: ${e.toString()}'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(Categoria categoria) {
    final nombreController = TextEditingController(text: categoria.nombre);
    final descripcionController = TextEditingController(text: categoria.descripcion ?? '');
    final esTipo = categoria.tipo == 'tipo';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: esTipo ? Colors.blue.shade50 : const Color(0xFFE1BEE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                esTipo ? Icons.category : Icons.branding_watermark,
                color: esTipo ? Colors.blue : const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Editar ${esTipo ? "Tipo" : "Marca"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nombre *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  hintText: esTipo ? 'Ej: Laptop, Mouse, Monitor' : 'Ej: Dell, HP, Logitech',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              const Text(
                'Descripción (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  hintText: 'Descripción de la categoría',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre es obligatorio'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (nombre.toLowerCase() != categoria.nombre.toLowerCase()) {
                if (_existeCategoria(nombre, categoria.tipo)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ya existe ${esTipo ? "un tipo" : "una marca"} con el nombre "$nombre"'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
              }

              Navigator.pop(dialogContext);

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => WillPopScope(
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
                            Text('Actualizando categoría...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );

              try {
                await widget.categoryService.actualizarCategoria(
                  context,
                  categoria.id,
                  nombre,
                  categoria.tipo,
                  descripcion: descripcionController.text.trim().isEmpty 
                    ? null 
                    : descripcionController.text.trim(),
                );

                await _cargarCategorias();

                navigator.pop();

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('"$nombre" actualizado exitosamente'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                navigator.pop();
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Error: ${e.toString()}'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: esTipo ? Colors.blue : const Color(0xFFCE93D8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Actualizar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaVacia(String tipo) {
    final esTipo = tipo == 'tipo';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esTipo ? Icons.category_outlined : Icons.branding_watermark_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              esTipo ? 'No hay tipos registrados' : 'No hay marcas registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón + para crear uno nuevo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaCategorias(List<Categoria> categorias, String tipo) {
    if (categorias.isEmpty) {
      return _buildListaVacia(tipo);
    }

    return RefreshIndicator(
      onRefresh: _cargarCategorias,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: categorias.length,
        itemBuilder: (context, index) => _buildCategoriaCard(categorias[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Categorías',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category),
                  const SizedBox(width: 8),
                  Text('Tipos (${_tipos.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.branding_watermark),
                  const SizedBox(width: 8),
                  Text('Marcas (${_marcas.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarCategorias,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListaCategorias(_tipos, 'tipo'),
                    _buildListaCategorias(_marcas, 'marca'),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final tipoCategoria = _tabController.index == 0 ? 'tipo' : 'marca';
          _mostrarDialogoNuevaCategoria(tipoCategoria);
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Nuevo Tipo' : 'Nueva Marca'),
        backgroundColor: _tabController.index == 0 
          ? Colors.blue 
          : const Color(0xFF9C27B0),
      ),
    );
  }
}