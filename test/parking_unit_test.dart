import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parking_uni/models/app_user.dart';
import 'package:parking_uni/models/parking_space.dart';
import 'package:parking_uni/models/reservation.dart';
import 'package:parking_uni/models/space_status.dart';
import 'package:parking_uni/models/user_type.dart';
import 'package:parking_uni/models/vehicle.dart';
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

    test('Validador de correo institucional con dominio configurable', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail('usuario@gmail.com'), isNotNull);
      expect(Validators.validateEmail('invalido-email'), isNotNull);
      expect(
        Validators.validateEmail('a.escorcia@universidad.edu'),
        isNull,
      );
    });

    test('Validador de contraseñas de Firebase Auth', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword('123456'), isNull);

      expect(Validators.validatePasswordConfirm('123456', '123456'), isNull);
      expect(Validators.validatePasswordConfirm('123456', '654321'), isNotNull);
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

    test('Validador de hora no anterior si la fecha es hoy', () {
      final today = DateTime.now();
      final futureTime = TimeOfDay(
        hour: (today.hour + 2) % 24,
        minute: today.minute,
      );

      // Si aún hay horas en el día, probar hora futura y pasada
      if (today.hour < 22) {
        expect(Validators.validateStartTimeNotPast(today, futureTime), isNull);
      }
      if (today.hour > 1) {
        final pastTime = TimeOfDay(hour: today.hour - 1, minute: today.minute);
        expect(Validators.validateStartTimeNotPast(today, pastTime), isNotNull);
      }
    });

    test('Validador de términos y condiciones', () {
      expect(Validators.validateTerms(false), isNotNull);
      expect(Validators.validateTerms(null), isNotNull);
      expect(Validators.validateTerms(true), isNull);
    });
  });

  group('Firestore Models Serialization Suite (fromMap / toMap)', () {
    test('AppUser toMap y fromMap', () {
      final now = DateTime.now();
      final user = AppUser(
        id: 'uid123',
        name: 'Alejandro Escorcia',
        email: 'a.escorcia@universidad.edu',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['name'], 'Alejandro Escorcia');
      expect(map['email'], 'a.escorcia@universidad.edu');
      expect(map['createdAt'], isA<Timestamp>());

      final fromMapUser = AppUser.fromMap(map, 'uid123');
      expect(fromMapUser.id, 'uid123');
      expect(fromMapUser.name, 'Alejandro Escorcia');
      expect(fromMapUser.email, 'a.escorcia@universidad.edu');
    });

    test('Vehicle toMap y fromMap', () {
      final now = DateTime.now();
      final vehicle = Vehicle(
        id: 'veh001',
        ownerId: 'uid123',
        plate: 'ABC123',
        vehicleType: VehicleType.automovil,
        brand: 'Mazda 3',
        color: 'Rojo',
        createdAt: now,
      );

      final map = vehicle.toMap();
      expect(map['plate'], 'ABC123');
      expect(map['vehicleType'], 'automovil');
      expect(map['brand'], 'Mazda 3');

      final fromMapVehicle = Vehicle.fromMap(map, 'veh001');
      expect(fromMapVehicle.id, 'veh001');
      expect(fromMapVehicle.plate, 'ABC123');
      expect(fromMapVehicle.vehicleType, VehicleType.automovil);
    });

    test('ParkingSpace toMap y fromMap', () {
      final space = ParkingSpace(
        id: 'A-01',
        number: '01',
        zone: 'Zona A',
        status: SpaceStatus.disponible,
      );

      final map = space.toMap();
      expect(map['number'], '01');
      expect(map['zone'], 'Zona A');
      expect(map['status'], 'disponible');

      final fromMapSpace = ParkingSpace.fromMap(map, 'A-01');
      expect(fromMapSpace.id, 'A-01');
      expect(fromMapSpace.status, SpaceStatus.disponible);
      expect(fromMapSpace.isAvailable, isTrue);
    });

    test('Reservation toMap, fromMap y helpers', () {
      final date = DateTime(2026, 11, 25);
      final res = Reservation(
        id: 'res999',
        ownerId: 'uid123',
        ownerName: 'Alejandro Escorcia',
        ownerEmail: 'a.escorcia@universidad.edu',
        userType: UserType.estudiante,
        vehicleId: 'veh001',
        plate: 'ABC123',
        vehicleType: VehicleType.automovil,
        zone: 'Zona A',
        spaceId: 'A-01',
        spaceNumber: '01',
        date: date,
        startMinutes: 480, // 08:00
        endMinutes: 600,   // 10:00
        wantsReminder: true,
        status: ReservationStatus.activa,
      );

      expect(res.formattedDate, '25/11/2026');
      expect(res.formattedSchedule, '08:00 - 10:00');
      expect(res.isActive, isTrue);

      final map = res.toMap();
      expect(map['plate'], 'ABC123');
      expect(map['startMinutes'], 480);
      expect(map['endMinutes'], 600);
      expect(map['status'], 'activa');

      final fromMapRes = Reservation.fromMap(map, 'res999');
      expect(fromMapRes.id, 'res999');
      expect(fromMapRes.plate, 'ABC123');
      expect(fromMapRes.startTime.hour, 8);
      expect(fromMapRes.endTime.hour, 10);
      expect(fromMapRes.status, ReservationStatus.activa);
    });
  });
}
