import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Representa el estado actual de un espacio de estacionamiento.
enum SpaceStatus {
  disponible,
  ocupado,
  reservado;

  /// Nombre amigable para mostrar en la interfaz de usuario.
  String get displayName {
    switch (this) {
      case SpaceStatus.disponible:
        return 'Disponible';
      case SpaceStatus.ocupado:
        return 'Ocupado';
      case SpaceStatus.reservado:
        return 'Reservado';
    }
  }

  /// Color principal asociado al estado.
  Color get color {
    switch (this) {
      case SpaceStatus.disponible:
        return AppTheme.availableGreen;
      case SpaceStatus.ocupado:
        return AppTheme.occupiedRed;
      case SpaceStatus.reservado:
        return AppTheme.reservedAmber;
    }
  }

  /// Color de fondo suave para chips y tarjetas.
  Color get lightBackgroundColor {
    switch (this) {
      case SpaceStatus.disponible:
        return AppTheme.availableGreenLight;
      case SpaceStatus.ocupado:
        return AppTheme.occupiedRedLight;
      case SpaceStatus.reservado:
        return AppTheme.reservedAmberLight;
    }
  }

  /// Ícono representativo del estado.
  IconData get icon {
    switch (this) {
      case SpaceStatus.disponible:
        return Icons.check_circle_outline;
      case SpaceStatus.ocupado:
        return Icons.block;
      case SpaceStatus.reservado:
        return Icons.access_time_filled;
    }
  }
}
