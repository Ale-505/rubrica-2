import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/register_screen.dart';
import 'screens/vehicles_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización oficial de Firebase (Plan Spark gratuito)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ParkingUniApp());
}

/// Aplicación principal ParkingUni con autenticación, persistencia remota y tiempo real.
class ParkingUniApp extends StatelessWidget {
  const ParkingUniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkingUni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(initialIndex: 0),
        '/reservar': (context) => const MainNavigationScreen(initialIndex: 1),
        '/mis-reservas': (context) => const MainNavigationScreen(initialIndex: 2),
        '/mapa': (context) => const MainNavigationScreen(initialIndex: 3),
        '/vehiculos': (context) => const VehiclesScreen(),
      },
    );
  }
}
