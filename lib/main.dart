import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/map_results_screen.dart';
import 'screens/reservation_form_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParkingUniApp());
}

/// Aplicación principal ParkingUni para la gestión de parqueadero universitario.
class ParkingUniApp extends StatelessWidget {
  const ParkingUniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkingUni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Rutas nombradas del proyecto
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/home': (context) => const HomeScreen(),
        '/reservar': (context) => const ReservationFormScreen(),
        '/mapa': (context) => const MapResultsScreen(),
      },
    );
  }
}
