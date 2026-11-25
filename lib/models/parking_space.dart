import 'package:cloud_firestore/cloud_firestore.dart';
import 'space_status.dart';

/// Modelo que representa un espacio físico de parqueadero (/parking_spaces/{spaceId}).
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

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'zone': zone,
      'status': status.name,
      'currentReservationId': currentReservationId,
      'occupiedByPlate': occupiedByPlate,
    };
  }

  factory ParkingSpace.fromMap(Map<String, dynamic> map, String id) {
    final statusStr = (map['status'] as String?)?.toLowerCase() ?? 'disponible';
    SpaceStatus st;
    switch (statusStr) {
      case 'ocupado':
        st = SpaceStatus.ocupado;
        break;
      case 'reservado':
        st = SpaceStatus.reservado;
        break;
      case 'disponible':
      default:
        st = SpaceStatus.disponible;
        break;
    }

    final fallbackNumber = id.contains('-') ? id.split('-').last : id;
    final fallbackZone = id.startsWith('A') ? 'Zona A' : 'Zona B';

    return ParkingSpace(
      id: id,
      number: (map['number'] as String?) ?? fallbackNumber,
      zone: (map['zone'] as String?) ?? fallbackZone,
      status: st,
      currentReservationId: map['currentReservationId'] as String?,
      occupiedByPlate: map['occupiedByPlate'] as String?,
    );
  }

  factory ParkingSpace.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ParkingSpace.fromMap(data, doc.id);
  }

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
