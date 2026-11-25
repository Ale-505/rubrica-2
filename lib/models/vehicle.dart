import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_type.dart';

/// Modelo de vehículo registrado en Firestore (/vehicles/{vehicleId}).
class Vehicle {
  final String id;
  final String ownerId;
  final String plate;
  final VehicleType vehicleType;
  final String brand;
  final String color;
  final DateTime createdAt;

  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.plate,
    required this.vehicleType,
    required this.brand,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'plate': plate.toUpperCase().trim(),
      'vehicleType': vehicleType.name,
      'brand': brand.trim(),
      'color': color.trim(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final typeStr = (map['vehicleType'] as String?)?.toLowerCase() ?? 'automovil';
    final type = typeStr == 'motocicleta'
        ? VehicleType.motocicleta
        : VehicleType.automovil;

    return Vehicle(
      id: id,
      ownerId: (map['ownerId'] as String?) ?? '',
      plate: ((map['plate'] as String?) ?? '').toUpperCase().trim(),
      vehicleType: type,
      brand: (map['brand'] as String?) ?? '',
      color: (map['color'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory Vehicle.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Vehicle.fromMap(data, doc.id);
  }

  /// Título descriptivo para dropdowns y listados
  String get displayTitle => '$plate - $brand ($color)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
