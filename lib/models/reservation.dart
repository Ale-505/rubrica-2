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

/// Modelo que encapsula los datos completos de una reserva en memoria.
class Reservation {
  final String id;
  final String fullName;
  final String email;
  final UserType userType;
  final VehicleType vehicleType;
  final String plate;
  final String zone;
  final String spaceId;
  final String spaceNumber;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool wantsReminder;
  ReservationStatus status;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.fullName,
    required this.email,
    required this.userType,
    required this.vehicleType,
    required this.plate,
    required this.zone,
    required this.spaceId,
    required this.spaceNumber,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.wantsReminder,
    this.status = ReservationStatus.activa,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
}
