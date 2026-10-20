import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parking_uni/data/parking_repository.dart';
import 'package:parking_uni/models/space_status.dart';
import 'package:parking_uni/models/user_type.dart';
import 'package:parking_uni/models/vehicle_type.dart';
import 'package:parking_uni/utils/validators.dart';

void main() {
  group('Validators Test Suite', () {
    test('Validador de nombre completo', () {
      expect(Validators.validateFullName(null), isNotNull);
      expect(Validators.validateFullName(''), isNotNull);
      expect(Validators.validateFullName('Al'), isNotNull);
      expect(Validators.validateFullName('Alejandro Escorcia'), isNull);
    });

    test('Validador de correo institucional', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail('usuario@gmail.com'), isNotNull);
      expect(Validators.validateEmail('invalido-email'), isNotNull);
      expect(
        Validators.validateEmail('a.escorcia@universidad.edu'),
        isNull,
      );
    });

    test('Validador de placa para automóvil y motocicleta colombiana', () {
      // Automóvil: 3 letras y 3 números (ej: ABC123)
      expect(Validators.validatePlate('ABC123', VehicleType.automovil), isNull);
      expect(Validators.validatePlate('ABC12D', VehicleType.automovil), isNotNull);
      expect(Validators.validatePlate('AB123', VehicleType.automovil), isNotNull);

      // Motocicleta: 3 letras, 2 números y 1 letra (ej: ABC12D)
      expect(Validators.validatePlate('ABC12D', VehicleType.motocicleta), isNull);
      expect(Validators.validatePlate('ABC123', VehicleType.motocicleta), isNotNull);
      expect(Validators.validatePlate('123ABC', VehicleType.motocicleta), isNotNull);
    });

    test('Validador de horario (hora fin debe ser posterior a hora inicio)', () {
      const start = TimeOfDay(hour: 8, minute: 0);
      const endValid = TimeOfDay(hour: 10, minute: 0);
      const endInvalid = TimeOfDay(hour: 7, minute: 30);
      const endEqual = TimeOfDay(hour: 8, minute: 0);

      expect(Validators.validateSchedule(start, endValid), isNull);
      expect(Validators.validateSchedule(start, endInvalid), isNotNull);
      expect(Validators.validateSchedule(start, endEqual), isNotNull);
    });

    test('Validador de fecha no anterior a hoy', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      expect(Validators.validateDate(today), isNull);
      expect(Validators.validateDate(tomorrow), isNull);
      expect(Validators.validateDate(yesterday), isNotNull);
    });
  });

  group('ParkingRepository Business Rules Test Suite', () {
    late ParkingRepository repository;

    setUp(() {
      repository = ParkingRepository();
      repository.resetData();
    });

    test('Inicializa 24 espacios divididos equitativamente en 2 zonas', () {
      expect(repository.totalSpaces, 24);
      final spacesA = repository.getSpacesByZone('Zona A');
      final spacesB = repository.getSpacesByZone('Zona B');
      expect(spacesA.length, 12);
      expect(spacesB.length, 12);
      expect(repository.availableCount + repository.occupiedCount + repository.reservedCount, 24);
    });

    test('Creación de reserva exitosa y cambio de estado a reservado', () {
      final initialAvailable = repository.availableCount;
      final initialReserved = repository.reservedCount;

      // Buscar primer espacio disponible en Zona A
      final availableSpace = repository.getAvailableSpaces('Zona A').first;

      final result = repository.createReservation(
        fullName: 'Estudiante Prueba',
        email: 'prueba@universidad.edu',
        userType: UserType.estudiante,
        vehicleType: VehicleType.automovil,
        plate: 'ZZZ999',
        zone: 'Zona A',
        spaceNumber: availableSpace.number,
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        wantsReminder: true,
      );

      expect(result.success, isTrue);
      expect(result.reservation, isNotNull);

      // El espacio ahora debe estar reservado
      final space = repository.getSpaceById(availableSpace.id);
      expect(space?.status, SpaceStatus.reservado);
      expect(repository.availableCount, initialAvailable - 1);
      expect(repository.reservedCount, initialReserved + 1);
    });

    test('Evita doble reserva de la misma placa en horarios solapados', () {
      final availableSpaces = repository.getAvailableSpaces('Zona A');
      final space1 = availableSpaces[0];
      final space2 = availableSpaces[1];

      // Primera reserva exitosa
      final res1 = repository.createReservation(
        fullName: 'Alejandro Escorcia',
        email: 'a.escorcia@universidad.edu',
        userType: UserType.estudiante,
        vehicleType: VehicleType.automovil,
        plate: 'ABC999',
        zone: 'Zona A',
        spaceNumber: space1.number,
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        wantsReminder: true,
      );
      expect(res1.success, isTrue);

      // Intento de segunda reserva en horario que se cruza (11:00 a 13:00) con la misma placa
      final resConflict = repository.createReservation(
        fullName: 'Alejandro Escorcia',
        email: 'a.escorcia@universidad.edu',
        userType: UserType.estudiante,
        vehicleType: VehicleType.automovil,
        plate: 'ABC999',
        zone: 'Zona A',
        spaceNumber: space2.number,
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        wantsReminder: true,
      );

      expect(resConflict.success, isFalse);
      expect(resConflict.message, contains('ya cuenta con una reserva activa'));
    });

    test('Cancelación de reserva libera el espacio de inmediato', () {
      final availableSpace = repository.getAvailableSpaces('Zona B').first;

      final res = repository.createReservation(
        fullName: 'Docente Prueba',
        email: 'docente@universidad.edu',
        userType: UserType.docente,
        vehicleType: VehicleType.automovil,
        plate: 'DOC123',
        zone: 'Zona B',
        spaceNumber: availableSpace.number,
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        wantsReminder: false,
      );

      final resId = res.reservation!.id;
      final spaceBefore = repository.getSpaceById(availableSpace.id);
      expect(spaceBefore?.status, SpaceStatus.reservado);

      // Cancelar reserva
      final cancelSuccess = repository.cancelReservation(resId);
      expect(cancelSuccess, isTrue);

      // Espacio liberado vuelve a disponible
      final spaceAfter = repository.getSpaceById(availableSpace.id);
      expect(spaceAfter?.status, SpaceStatus.disponible);
    });
  });
}
