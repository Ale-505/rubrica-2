import 'package:flutter/material.dart';
import '../models/parking_space.dart';
import '../models/reservation.dart';
import '../models/space_status.dart';
import '../models/user_type.dart';
import '../models/vehicle_type.dart';

/// Repositorio de datos en memoria para ParkingUni.
/// Implementa ChangeNotifier para que la interfaz reaccione en tiempo real
/// ante cualquier cambio de estado (reservas, cancelaciones y contadores).
class ParkingRepository extends ChangeNotifier {
  // Singleton para acceso global y persistencia durante la sesión de la app
  static final ParkingRepository _instance = ParkingRepository._internal();
  factory ParkingRepository() => _instance;

  ParkingRepository._internal() {
    _initializeSpaces();
    _initializeMockReservations();
  }

  final List<ParkingSpace> _spaces = [];
  final List<Reservation> _reservations = [];

  // Getters inmutables
  List<ParkingSpace> get spaces => List.unmodifiable(_spaces);
  List<Reservation> get reservations => List.unmodifiable(_reservations);

  // Contadores en tiempo real
  int get totalSpaces => _spaces.length;
  int get availableCount =>
      _spaces.where((s) => s.status == SpaceStatus.disponible).length;
  int get occupiedCount =>
      _spaces.where((s) => s.status == SpaceStatus.ocupado).length;
  int get reservedCount =>
      _spaces.where((s) => s.status == SpaceStatus.reservado).length;

  /// Inicializa los 24 espacios físicos en 2 zonas:
  /// - Zona A: 12 espacios (01 al 12)
  /// - Zona B: 12 espacios (13 al 24)
  void _initializeSpaces() {
    _spaces.clear();

    // Precarga de algunos espacios ocupados para realismo inicial
    final occupiedA = {'02', '04', '07', '10'};
    final occupiedB = {'14', '16', '19', '23'};

    // Zona A (01 - 12)
    for (int i = 1; i <= 12; i++) {
      final numStr = i.toString().padLeft(2, '0');
      final isOcc = occupiedA.contains(numStr);
      _spaces.add(
        ParkingSpace(
          id: 'A-$numStr',
          number: numStr,
          zone: 'Zona A',
          status: isOcc ? SpaceStatus.ocupado : SpaceStatus.disponible,
          occupiedByPlate: isOcc ? 'ABC${100 + i}' : null,
        ),
      );
    }

    // Zona B (13 - 24)
    for (int i = 13; i <= 24; i++) {
      final numStr = i.toString().padLeft(2, '0');
      final isOcc = occupiedB.contains(numStr);
      _spaces.add(
        ParkingSpace(
          id: 'B-$numStr',
          number: numStr,
          zone: 'Zona B',
          status: isOcc ? SpaceStatus.ocupado : SpaceStatus.disponible,
          occupiedByPlate: isOcc ? 'XYZ${100 + i}' : null,
        ),
      );
    }
  }

  /// Inicializa reservas previas para mostrar datos en historial
  void _initializeMockReservations() {
    _reservations.clear();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Reserva histórica completada
    _reservations.add(
      Reservation(
        id: 'RES-0982',
        fullName: 'Alejandro Escorcia',
        email: 'a.escorcia@universidad.edu',
        userType: UserType.estudiante,
        vehicleType: VehicleType.automovil,
        plate: 'UJM456',
        zone: 'Zona A',
        spaceId: 'A-03',
        spaceNumber: '03',
        date: yesterday,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        wantsReminder: true,
        status: ReservationStatus.completada,
        createdAt: yesterday.subtract(const Duration(hours: 2)),
      ),
    );
  }

  /// Obtiene los espacios según la zona seleccionada ('Zona A' o 'Zona B')
  List<ParkingSpace> getSpacesByZone(String zone) {
    return _spaces.where((s) => s.zone == zone).toList();
  }

  /// Obtiene únicamente los espacios disponibles para una zona
  List<ParkingSpace> getAvailableSpaces(String zone) {
    return _spaces
        .where((s) => s.zone == zone && s.status == SpaceStatus.disponible)
        .toList();
  }

  /// Busca un espacio por su ID único (ej: 'A-01')
  ParkingSpace? getSpaceById(String id) {
    try {
      return _spaces.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Verifica si una placa tiene conflicto de horario con otra reserva activa
  bool hasPlateTimeConflict({
    required String plate,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    final cleanedPlate = plate.trim().toUpperCase();
    final targetStart = startTime.hour * 60 + startTime.minute;
    final targetEnd = endTime.hour * 60 + endTime.minute;

    for (final res in _reservations) {
      if (res.status != ReservationStatus.activa) continue;
      if (res.plate.toUpperCase() != cleanedPlate) continue;

      // Verificar si es la misma fecha
      final sameDate = res.date.year == date.year &&
          res.date.month == date.month &&
          res.date.day == date.day;

      if (sameDate) {
        final existingStart = res.startTime.hour * 60 + res.startTime.minute;
        final existingEnd = res.endTime.hour * 60 + res.endTime.minute;

        // Comprueba solapamiento de intervalos
        final overlaps = !(targetEnd <= existingStart || targetStart >= existingEnd);
        if (overlaps) {
          return true;
        }
      }
    }
    return false;
  }

  /// Crea una nueva reserva y actualiza el espacio en tiempo real
  ({bool success, String message, Reservation? reservation}) createReservation({
    required String fullName,
    required String email,
    required UserType userType,
    required VehicleType vehicleType,
    required String plate,
    required String zone,
    required String spaceNumber,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool wantsReminder,
  }) {
    final spaceId = '${zone == "Zona A" ? "A" : "B"}-$spaceNumber';
    final space = getSpaceById(spaceId);

    // 1. Validar existencia del espacio
    if (space == null) {
      return (
        success: false,
        message: 'El espacio seleccionado no existe.',
        reservation: null,
      );
    }

    // 2. Validar que el espacio esté disponible
    if (space.status != SpaceStatus.disponible) {
      return (
        success: false,
        message:
            'El espacio $spaceNumber ya no se encuentra disponible (${space.status.displayName.toLowerCase()}).',
        reservation: null,
      );
    }

    // 3. Validar solapamiento de la misma placa
    final hasConflict = hasPlateTimeConflict(
      plate: plate,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );

    if (hasConflict) {
      return (
        success: false,
        message:
            'El vehículo con placa $plate ya cuenta con una reserva activa que se cruza con este horario.',
        reservation: null,
      );
    }

    // Generar ID único para la reserva
    final newId = 'RES-${1000 + _reservations.length + 1}';

    final reservation = Reservation(
      id: newId,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      userType: userType,
      vehicleType: vehicleType,
      plate: plate.trim().toUpperCase(),
      zone: zone,
      spaceId: spaceId,
      spaceNumber: spaceNumber,
      date: date,
      startTime: startTime,
      endTime: endTime,
      wantsReminder: wantsReminder,
      status: ReservationStatus.activa,
    );

    // Modificar estado en memoria
    space.status = SpaceStatus.reservado;
    space.currentReservationId = newId;

    // Agregar al inicio del listado de reservas
    _reservations.insert(0, reservation);

    // Notificar a todos los escuchas (UI)
    notifyListeners();

    return (
      success: true,
      message: '¡Reserva del espacio $spaceNumber confirmada exitosamente!',
      reservation: reservation,
    );
  }

  /// Cancela una reserva activa y libera de inmediato el espacio asociado
  bool cancelReservation(String reservationId) {
    try {
      final res = _reservations.firstWhere((r) => r.id == reservationId);
      if (res.status != ReservationStatus.activa) return false;

      // Cambiar estado de reserva
      res.status = ReservationStatus.cancelada;

      // Liberar el espacio asociado
      final space = getSpaceById(res.spaceId);
      if (space != null) {
        space.status = SpaceStatus.disponible;
        space.currentReservationId = null;
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reinicia todos los datos a su estado original (útil para pruebas)
  void resetData() {
    _initializeSpaces();
    _initializeMockReservations();
    notifyListeners();
  }
}
