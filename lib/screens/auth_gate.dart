import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

/// Control de acceso en la raíz de la app mediante StreamBuilder sobre authStateChanges().
/// - Sin sesión activa: Muestra LoginScreen.
/// - Con sesión activa: Muestra MainNavigationScreen.
/// La sesión persiste automáticamente en el dispositivo móvil.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Estado de carga inicial de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.darkHeader,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'P',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ],
              ),
            ),
          );
        }

        // Usuario autenticado
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }

        // Sin sesión
        return const LoginScreen();
      },
    );
  }
}
