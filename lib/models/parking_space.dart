import 'space_status.dart';

/// Modelo que representa un espacio físico de parqueadero.
class ParkingSpace {
  final String id; // Ejemplo: 'A-01' o 'B-13'
  final String number; // Ejemplo: '01' o '13'
  final String zone; // 'Zona A' o 'Zona B'
  SpaceStatus status;
  String? currentReservationId;
  String? occupiedByPlate;

  ParkingSpace({
    required this.id,
    required this.number,
    required this.zone,
    this.status = SpaceStatus.disponible,
    this.currentReservationId,
    this.occupiedByPlate,
  });

  /// Indica si el espacio está disponible para reservar.
  bool get isAvailable => status == SpaceStatus.disponible;

  /// Retorna una copia con campos modificados si es necesario.
  ParkingSpace copyWith({
    String? id,
    String? number,
    String? zone,
    SpaceStatus? status,
    String? currentReservationId,
    String? occupiedByPlate,
  }) {
    return ParkingSpace(
      id: id ?? this.id,
      number: number ?? this.number,
      zone: zone ?? this.zone,
      status: status ?? this.status,
      currentReservationId: currentReservationId ?? this.currentReservationId,
      occupiedByPlate: occupiedByPlate ?? this.occupiedByPlate,
    );
  }
}
