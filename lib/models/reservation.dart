import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_type.dart';
import 'vehicle_type.dart';

/// Estado de una reserva de parqueadero.
enum ReservationStatus {
  activa,
  completada,
  cancelada;

  String get displayName {
    switch (this) {
      case ReservationStatus.activa:
        return 'Activa';
      case ReservationStatus.completada:
        return 'Completada';
      case ReservationStatus.cancelada:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case ReservationStatus.activa:
        return const Color(0xFF16A34A); // Verde
      case ReservationStatus.completada:
        return const Color(0xFF2563EB); // Azul
      case ReservationStatus.cancelada:
        return const Color(0xFFDC2626); // Rojo
    }
  }

  Color get lightColor {
    switch (this) {
      case ReservationStatus.activa:
        return const Color(0xFFDCFCE7);
      case ReservationStatus.completada:
        return const Color(0xFFDBEAFE);
      case ReservationStatus.cancelada:
        return const Color(0xFFFEE2E2);
    }
  }
}

/// Modelo que encapsula los datos completos de una reserva persistida en Firestore.
class Reservation {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final UserType userType;
  final String vehicleId;
  final String plate;
  final VehicleType vehicleType;
  final String zone;
  final String spaceId;
  final String spaceNumber;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final bool wantsReminder;
  ReservationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reservation({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.userType,
    required this.vehicleId,
    required this.plate,
    required this.vehicleType,
    required this.zone,
    required this.spaceId,
    required this.spaceNumber,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.wantsReminder,
    this.status = ReservationStatus.activa,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Alias para mantener compatibilidad con pantallas anteriores
  String get fullName => ownerName;
  String get email => ownerEmail;

  TimeOfDay get startTime => TimeOfDay(
        hour: startMinutes ~/ 60,
        minute: startMinutes % 60,
      );

  TimeOfDay get endTime => TimeOfDay(
        hour: endMinutes ~/ 60,
        minute: endMinutes % 60,
      );

  bool get isActive => status == ReservationStatus.activa;

  /// Retorna la fecha formateada en formato DD/MM/AAAA.
  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  /// Retorna el rango horario en formato HH:MM - HH:MM.
  String get formattedSchedule {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'userType': userType.name,
      'vehicleId': vehicleId,
      'plate': plate.toUpperCase().trim(),
      'vehicleType': vehicleType.name,
      'zone': zone,
      'spaceId': spaceId,
      'spaceNumber': spaceNumber,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'wantsReminder': wantsReminder,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final userTypeStr = (map['userType'] as String?)?.toLowerCase() ?? 'estudiante';
    final uType = UserType.values.firstWhere(
      (e) => e.name == userTypeStr,
      orElse: () => UserType.estudiante,
    );

    final vehicleTypeStr = (map['vehicleType'] as String?)?.toLowerCase() ?? 'automovil';
    final vType = vehicleTypeStr == 'motocicleta'
        ? VehicleType.motocicleta
        : VehicleType.automovil;

    final statusStr = (map['status'] as String?)?.toLowerCase() ?? 'activa';
    ReservationStatus rStatus;
    switch (statusStr) {
      case 'completada':
        rStatus = ReservationStatus.completada;
        break;
      case 'cancelada':
        rStatus = ReservationStatus.cancelada;
        break;
      case 'activa':
      default:
        rStatus = ReservationStatus.activa;
        break;
    }

    return Reservation(
      id: id,
      ownerId: (map['ownerId'] as String?) ?? '',
      ownerName: (map['ownerName'] as String?) ?? 'Usuario',
      ownerEmail: (map['ownerEmail'] as String?) ?? '',
      userType: uType,
      vehicleId: (map['vehicleId'] as String?) ?? '',
      plate: ((map['plate'] as String?) ?? '').toUpperCase().trim(),
      vehicleType: vType,
      zone: (map['zone'] as String?) ?? 'Zona A',
      spaceId: (map['spaceId'] as String?) ?? 'A-01',
      spaceNumber: (map['spaceNumber'] as String?) ?? '01',
      date: parseDate(map['date']),
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 480, // 08:00
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 600, // 10:00
      wantsReminder: (map['wantsReminder'] as bool?) ?? false,
      status: rStatus,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory Reservation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Reservation.fromMap(data, doc.id);
  }

  Reservation copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    UserType? userType,
    String? vehicleId,
    String? plate,
    VehicleType? vehicleType,
    String? zone,
    String? spaceId,
    String? spaceNumber,
    DateTime? date,
    int? startMinutes,
    int? endMinutes,
    bool? wantsReminder,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      userType: userType ?? this.userType,
      vehicleId: vehicleId ?? this.vehicleId,
      plate: plate ?? this.plate,
      vehicleType: vehicleType ?? this.vehicleType,
      zone: zone ?? this.zone,
      spaceId: spaceId ?? this.spaceId,
      spaceNumber: spaceNumber ?? this.spaceNumber,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      wantsReminder: wantsReminder ?? this.wantsReminder,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
