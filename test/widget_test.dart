import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parking_uni/models/parking_space.dart';
import 'package:parking_uni/models/reservation.dart';
import 'package:parking_uni/models/space_status.dart';
import 'package:parking_uni/models/user_type.dart';
import 'package:parking_uni/models/vehicle_type.dart';
import 'package:parking_uni/theme/app_theme.dart';
import 'package:parking_uni/widgets/parking_space_tile.dart';
import 'package:parking_uni/widgets/reservation_card.dart';
import 'package:parking_uni/widgets/stat_card.dart';
import 'package:parking_uni/widgets/status_legend.dart';

void main() {
  testWidgets('ParkingSpaceTile renderiza espacio disponible correctamente', (tester) async {
    final space = ParkingSpace(
      id: 'A-01',
      number: '01',
      zone: 'Zona A',
      status: SpaceStatus.disponible,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ParkingSpaceTile(
            space: space,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('01'), findsOneWidget);
    expect(find.text('Libre'), findsOneWidget);
  });

  testWidgets('StatCard renderiza contadores y títulos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: StatCard(
            title: 'Disponibles',
            count: 16,
            icon: Icons.check_circle_rounded,
            color: AppTheme.availableGreen,
            backgroundColor: AppTheme.availableGreenLight,
          ),
        ),
      ),
    );

    expect(find.text('16'), findsOneWidget);
    expect(find.text('Disponibles'), findsOneWidget);
  });

  testWidgets('StatusLegend muestra los 3 estados del parqueadero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: StatusLegend(),
        ),
      ),
    );

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Ocupado'), findsOneWidget);
    expect(find.text('Reservado'), findsOneWidget);
  });

  testWidgets('ReservationCard muestra detalles de la reserva', (tester) async {
    final reservation = Reservation(
      id: 'res-test',
      ownerId: 'uid123',
      ownerName: 'Alejandro Escorcia',
      ownerEmail: 'a.escorcia@universidad.edu',
      userType: UserType.estudiante,
      vehicleId: 'veh-test',
      plate: 'ABC123',
      vehicleType: VehicleType.automovil,
      zone: 'Zona A',
      spaceId: 'A-05',
      spaceNumber: '05',
      date: DateTime(2026, 11, 22),
      startMinutes: 480,
      endMinutes: 600,
      wantsReminder: true,
      status: ReservationStatus.activa,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ReservationCard(
            reservation: reservation,
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('Espacio 05'), findsOneWidget);
    expect(find.text('Zona A'), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('Cancelar reserva'), findsOneWidget);
  });
}
