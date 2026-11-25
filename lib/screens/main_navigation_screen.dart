import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'my_reservations_screen.dart';
import 'reservation_form_screen.dart';
import 'vehicles_screen.dart';

/// Contenedor de navegación principal de ParkingUni con barra inferior Material 3.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  String? _preselectedZone;
  String? _preselectedSpaceNumber;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToTab(int index, {String? zone, String? spaceNumber}) {
    setState(() {
      _currentIndex = index;
      if (zone != null) _preselectedZone = zone;
      if (spaceNumber != null) _preselectedSpaceNumber = spaceNumber;
    });
  }

  void _openVehiclesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VehiclesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Pestaña 0: Inicio
          HomeScreen(
            onNavigateTab: (targetTab) => _navigateToTab(targetTab),
            onOpenVehicles: _openVehiclesScreen,
          ),

          // Pestaña 1: Reservar (Formulario)
          ReservationFormScreen(
            key: ValueKey('form-$_preselectedZone-$_preselectedSpaceNumber'),
            initialZone: _preselectedZone,
            initialSpaceNumber: _preselectedSpaceNumber,
            onReservationSuccess: () {
              _navigateToTab(2); // Redirigir a Mis reservas
            },
          ),

          // Pestaña 2: Mis reservas (Consulta)
          MyReservationsScreen(
            onGoToNewReservation: () => _navigateToTab(1),
          ),

          // Pestaña 3: Mapa en vivo
          MapScreen(
            onReserveSpace: (zone, spaceNumber) {
              _navigateToTab(1, zone: zone, spaceNumber: spaceNumber);
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
              if (index != 1) {
                _preselectedZone = null;
                _preselectedSpaceNumber = null;
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
              selectedIcon: Icon(Icons.bookmark_add_rounded, color: AppTheme.darkHeader),
              label: 'Reservar',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded, color: AppTheme.darkHeader),
              label: 'Mis reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: AppTheme.darkHeader),
              label: 'Mapa en vivo',
            ),
          ],
        ),
      ),
    );
  }
}
