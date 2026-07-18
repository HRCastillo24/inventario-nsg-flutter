import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/category_service.dart';
import 'providers/auth_provider.dart';

// Pantallas
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/anadir_producto_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/bajo_stock_screen.dart';
import 'screens/ventas_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/movimientos_screen.dart';
import 'screens/notificaciones_screen.dart';
import 'screens/gestionar_ventas_screen.dart';
import 'screens/anadir_usuario_screen.dart';
import 'screens/categorias_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CARGAR ESPAÑOL ANTES DE QUE LA APP ARRANQUE
  await initializeDateFormatting('es_ES', null);

  // Limpia token al iniciar la app solo durante desarrollo
  const storage = FlutterSecureStorage();
  await storage.delete(key: 'jwt_token');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const baseUrl = 'https://nsglatinoamerica.duckdns.org';

    final authService = AuthService(baseUrl: baseUrl);
    final apiService = ApiService(baseUrl: baseUrl);
    final categoryService = CategoryService(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        Provider<ApiService>.value(value: apiService),
        Provider<CategoryService>.value(value: categoryService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NSG Inventario',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/anadir_producto': (_) => const AnadirProductoScreen(),
          '/inventario': (_) => const InventarioScreen(),
          '/bajo_stock': (_) => const BajoStockScreen(),
          '/ventas': (_) => const RegistrarVentaScreen(),
          '/reportes': (_) => const ReportesScreen(),
          '/movimientos': (_) => const MovimientosScreen(),
          '/notificaciones': (_) => const NotificacionesScreen(),
          '/gestionar_ventas': (context) => const GestionarVentasScreen(),
          '/anadir_usuario': (context) => AnadirUsuarioScreen(), 
          '/categorias': (context) => CategoriasScreen(
            categoryService: Provider.of<CategoryService>(context, listen: false),
          ),
        },
      ),
    );
  }
}