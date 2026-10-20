import 'package:flutter/material.dart';
import '../models/parking_space.dart';
import '../models/space_status.dart';

/// Componente visual reutilizable que representa una casilla individual de parqueadero.
/// Muestra el número del espacio, un ícono representativo, y el color de estado
/// (Verde: Disponible, Rojo: Ocupado, Ámbar: Reservado).
/// Diseñado para ajustarse responsivemente sin desbordamientos en pantallas móviles.
class ParkingSpaceTile extends StatelessWidget {
  final ParkingSpace space;
  final VoidCallback onTap;

  const ParkingSpaceTile({
    super.key,
    required this.space,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = space.status;
    final statusColor = status.color;
    final bgColor = status.lightBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: statusColor.withValues(alpha: 0.2),
        highlightColor: statusColor.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador visual superior con número
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      space.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Ícono central representativo
                  Icon(
                    _getSpaceIcon(status),
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(height: 2),
                  // Etiqueta de estado
                  Text(
                    _getShortStatusName(status),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSpaceIcon(SpaceStatus status) {
    switch (status) {
      case SpaceStatus.disponible:
        return Icons.local_parking_rounded;
      case SpaceStatus.ocupado:
        return Icons.directions_car_rounded;
      case SpaceStatus.reservado:
        return Icons.lock_clock_rounded;
    }
  }

  String _getShortStatusName(SpaceStatus status) {
    switch (status) {
      case SpaceStatus.disponible:
        return 'Libre';
      case SpaceStatus.ocupado:
        return 'Ocupado';
      case SpaceStatus.reservado:
        return 'Reservado';
    }
  }
}
