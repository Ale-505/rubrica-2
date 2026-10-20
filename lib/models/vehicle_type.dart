import 'package:flutter/material.dart';

/// Tipo de vehículo admitido en el parqueadero.
enum VehicleType {
  automovil,
  motocicleta;

  /// Nombre amigable del vehículo.
  String get displayName {
    switch (this) {
      case VehicleType.automovil:
        return 'Automóvil';
      case VehicleType.motocicleta:
        return 'Motocicleta';
    }
  }

  /// Ejemplo de placa con formato colombiano.
  String get plateExample {
    switch (this) {
      case VehicleType.automovil:
        return 'ABC123';
      case VehicleType.motocicleta:
        return 'ABC12D';
    }
  }

  /// Descripción del formato requerido para la placa.
  String get plateHint {
    switch (this) {
      case VehicleType.automovil:
        return 'Ej: ABC123 (3 letras y 3 números)';
      case VehicleType.motocicleta:
        return 'Ej: ABC12D (3 letras, 2 números y 1 letra)';
    }
  }

  /// Ícono representativo del vehículo.
  IconData get icon {
    switch (this) {
      case VehicleType.automovil:
        return Icons.directions_car_rounded;
      case VehicleType.motocicleta:
        return Icons.two_wheeler_rounded;
    }
  }
}
