import 'package:flutter/material.dart';
import 'map_screen.dart';

/// Pantalla adaptadora de compatibilidad que redirige a MapScreen.
class MapResultsScreen extends StatelessWidget {
  final int initialTabIndex;
  final Function(String zone, String spaceNumber)? onReserveSpace;
  final VoidCallback? onGoToReservationForm;

  const MapResultsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onReserveSpace,
    this.onGoToReservationForm,
  });

  @override
  Widget build(BuildContext context) {
    return MapScreen(
      onReserveSpace: onReserveSpace,
    );
  }
}
