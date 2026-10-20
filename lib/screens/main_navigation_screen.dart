import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_results_screen.dart';
import 'reservation_form_screen.dart';

/// Contenedor principal de navegación de ParkingUni.
/// Provee una barra de navegación inferior (Material 3 NavigationBar) y coordina
/// el flujo entre Inicio, Formulario de Reserva y Mapa/Mis Reservas, manteniendo
/// la sincronización de estado y la preselección de espacios.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialZone;
  final String? initialSpaceNumber;
  final int initialMapTabIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialZone,
    this.initialSpaceNumber,
    this.initialMapTabIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  // Estado para preselección cuando el usuario viene desde el mapa
  String? _preselectedZone;
  String? _preselectedSpaceNumber;

  // Pestaña inicial para MapResultsScreen (0: Mapa, 1: Mis reservas)
  int _mapResultsInitialTab = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _preselectedZone = widget.initialZone;
    _preselectedSpaceNumber = widget.initialSpaceNumber;
    _mapResultsInitialTab = widget.initialMapTabIndex;
  }

  /// Navega directamente a una pestaña de la barra inferior
  void _navigateToTab(int index, {String? zone, String? spaceNumber, int mapTab = 0}) {
    setState(() {
      _currentIndex = index;
      if (zone != null) _preselectedZone = zone;
      if (spaceNumber != null) _preselectedSpaceNumber = spaceNumber;
      _mapResultsInitialTab = mapTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Pantalla 1: Inicio
          HomeScreen(
            onNavigateTab: (targetTab, {preselectedZone, preselectedSpaceNumber}) {
              _navigateToTab(
                targetTab,
                zone: preselectedZone,
                spaceNumber: preselectedSpaceNumber,
              );
            },
          ),

          // Pantalla 2: Formulario de Registro de Reserva
          ReservationFormScreen(
            key: ValueKey('$_preselectedZone-$_preselectedSpaceNumber'),
            initialZone: _preselectedZone,
            initialSpaceNumber: _preselectedSpaceNumber,
            onReservationSuccess: () {
              // Al confirmar, redirigir a Pantalla 3 en la pestaña de Mis reservas
              _navigateToTab(2, mapTab: 1);
            },
          ),

          // Pantalla 3: Consulta y Resultados (Mapa y Mis Reservas)
          MapResultsScreen(
            key: ValueKey('map-$_mapResultsInitialTab'),
            initialTabIndex: _mapResultsInitialTab,
            onReserveSpace: (zone, spaceNumber) {
              // Usuario tocó "Reservar este espacio" en el mapa
              _navigateToTab(1, zone: zone, spaceNumber: spaceNumber);
            },
            onGoToReservationForm: () {
              _navigateToTab(1);
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
              // Si el usuario cambia manualmente de pestaña, resetear preselecciones
              if (index != 1) {
                _preselectedZone = null;
                _preselectedSpaceNumber = null;
              }
              if (index == 2) {
                _mapResultsInitialTab = 0; // Por defecto abrir en Mapa
              }
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.darkHeader.withValues(alpha: 0.12),
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.darkHeader),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_add_outlined),
              selectedIcon:
                  Icon(Icons.bookmark_add_rounded, color: AppTheme.darkHeader),
              label: 'Reservar',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: AppTheme.darkHeader),
              label: 'Mapa / Reservas',
            ),
          ],
        ),
      ),
    );
  }
}
