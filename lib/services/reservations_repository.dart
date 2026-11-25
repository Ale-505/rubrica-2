import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/user_type.dart';
import '../models/vehicle_type.dart';

/// Repositorio de reservas con persistencia en Firestore y transacciones atómicas
/// para asegurar consistencia entre reservas y el estado físico de los espacios.
class ReservationsRepository {
  ReservationsRepository._internal();
  static final ReservationsRepository _instance = ReservationsRepository._internal();
  factory ReservationsRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reservationsRef =>
      _firestore.collection('reservations');

  CollectionReference<Map<String, dynamic>> get _spacesRef =>
      _firestore.collection('parking_spaces');

  /// Stream en tiempo real de las reservas del usuario autenticado
  Stream<List<Reservation>> getMyReservationsStream(String ownerId) {
    return _reservationsRef
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => Reservation.fromDoc(doc)).toList();
      // Ordenar por fecha y hora de creación descendente
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream para el detalle de una reserva específica
  Stream<Reservation?> getReservationStream(String reservationId) {
    return _reservationsRef.doc(reservationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Reservation.fromDoc(doc);
    });
  }

  /// Verifica si la placa tiene conflicto con otra reserva 'activa' el mismo día y horario
  Future<bool> hasPlateConflict({
    required String plate,
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
    String? excludeReservationId,
  }) async {
    final cleanPlate = plate.toUpperCase().trim();
    final query = await _reservationsRef
        .where('plate', isEqualTo: cleanPlate)
        .where('status', isEqualTo: 'activa')
        .get();

    for (final doc in query.docs) {
      if (excludeReservationId != null && doc.id == excludeReservationId) {
        continue;
      }
      final res = Reservation.fromDoc(doc);
      final sameDay = res.date.year == date.year &&
          res.date.month == date.month &&
          res.date.day == date.day;

      if (sameDay) {
        final overlaps =
            !(endMinutes <= res.startMinutes || startMinutes >= res.endMinutes);
        if (overlaps) {
          return true;
        }
      }
    }
    return false;
  }

  /// Crea una reserva de forma ATÓMICA verificando que el espacio siga disponible
  Future<Reservation> createReservationAtomic({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    required UserType userType,
    required String vehicleId,
    required String plate,
    required VehicleType vehicleType,
    required String zone,
    required String spaceNumber,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool wantsReminder,
  }) async {
    final spaceId = '${zone == 'Zona A' ? 'A' : 'B'}-$spaceNumber';
    final spaceRef = _spacesRef.doc(spaceId);
    final resRef = _reservationsRef.doc();

    final startMin = startTime.hour * 60 + startTime.minute;
    final endMin = endTime.hour * 60 + endTime.minute;

    // Comprobar conflicto de placa
    final conflict = await hasPlateConflict(
      plate: plate,
      date: date,
      startMinutes: startMin,
      endMinutes: endMin,
    );
    if (conflict) {
      throw Exception(
        'El vehículo con placa $plate ya cuenta con una reserva activa en ese horario.',
      );
    }

    final newReservation = Reservation(
      id: resRef.id,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      userType: userType,
      vehicleId: vehicleId,
      plate: plate.toUpperCase().trim(),
      vehicleType: vehicleType,
      zone: zone,
      spaceId: spaceId,
      spaceNumber: spaceNumber,
      date: date,
      startMinutes: startMin,
      endMinutes: endMin,
      wantsReminder: wantsReminder,
      status: ReservationStatus.activa,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      final spaceSnap = await transaction.get(spaceRef);
      if (!spaceSnap.exists) {
        throw Exception('El espacio $spaceNumber no existe.');
      }

      final status = (spaceSnap.data()?['status'] as String?)?.toLowerCase();
      if (status != 'disponible') {
        throw Exception(
          'El espacio $spaceNumber ya fue tomado por otro usuario o no está disponible.',
        );
      }

      // 1. Guardar la reserva
      transaction.set(resRef, newReservation.toMap());

      // 2. Actualizar el espacio a reservado
      transaction.update(spaceRef, {
        'status': 'reservado',
        'currentReservationId': resRef.id,
        'occupiedByPlate': plate.toUpperCase().trim(),
      });
    });

    return newReservation;
  }

  /// Cancela una reserva activa de forma ATÓMICA y libera el espacio
  Future<void> cancelReservationAtomic(String reservationId) async {
    final resRef = _reservationsRef.doc(reservationId);

    await _firestore.runTransaction((transaction) async {
      final resSnap = await transaction.get(resRef);
      if (!resSnap.exists) {
        throw Exception('La reserva no existe.');
      }

      final res = Reservation.fromDoc(resSnap);
      if (res.status != ReservationStatus.activa) {
        return; // Ya estaba cancelada o completada
      }

      final spaceRef = _spacesRef.doc(res.spaceId);
      final spaceSnap = await transaction.get(spaceRef);

      // Cambiar estado de la reserva
      transaction.update(resRef, {
        'status': 'cancelada',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Liberar el espacio si correspondía a esta reserva
      if (spaceSnap.exists) {
        final currentResId = spaceSnap.data()?['currentReservationId'] as String?;
        if (currentResId == reservationId) {
          transaction.update(spaceRef, {
            'status': 'disponible',
            'currentReservationId': null,
            'occupiedByPlate': null,
          });
        }
      }
    });
  }

  /// Modifica una reserva existente de forma ATÓMICA (incluyendo posible cambio de espacio)
  Future<void> updateReservationAtomic({
    required Reservation updatedReservation,
    required String previousSpaceId,
  }) async {
    final resRef = _reservationsRef.doc(updatedReservation.id);
    final isSpaceChanged = updatedReservation.spaceId != previousSpaceId;

    // Verificar conflicto de horario con otra reserva
    final conflict = await hasPlateConflict(
      plate: updatedReservation.plate,
      date: updatedReservation.date,
      startMinutes: updatedReservation.startMinutes,
      endMinutes: updatedReservation.endMinutes,
      excludeReservationId: updatedReservation.id,
    );
    if (conflict) {
      throw Exception(
        'El vehículo con placa ${updatedReservation.plate} ya cuenta con otra reserva activa en este horario.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final resSnap = await transaction.get(resRef);
      if (!resSnap.exists) {
        throw Exception('La reserva no existe.');
      }

      if (isSpaceChanged && updatedReservation.isActive) {
        // 1. Verificar y reservar nuevo espacio
        final newSpaceRef = _spacesRef.doc(updatedReservation.spaceId);
        final newSpaceSnap = await transaction.get(newSpaceRef);
        if (!newSpaceSnap.exists) {
          throw Exception('El nuevo espacio no existe.');
        }
        final newStatus = (newSpaceSnap.data()?['status'] as String?)?.toLowerCase();
        if (newStatus != 'disponible') {
          throw Exception(
            'El espacio ${updatedReservation.spaceNumber} no está disponible.',
          );
        }

        // 2. Liberar espacio anterior
        final oldSpaceRef = _spacesRef.doc(previousSpaceId);
        final oldSpaceSnap = await transaction.get(oldSpaceRef);
        if (oldSpaceSnap.exists) {
          transaction.update(oldSpaceRef, {
            'status': 'disponible',
            'currentReservationId': null,
            'occupiedByPlate': null,
          });
        }

        // 3. Ocupar nuevo espacio
        transaction.update(newSpaceRef, {
          'status': 'reservado',
          'currentReservationId': updatedReservation.id,
          'occupiedByPlate': updatedReservation.plate,
        });
      }

      // Actualizar reserva
      final data = updatedReservation.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      transaction.update(resRef, data);
    });
  }

  /// Elimina una reserva de forma ATÓMICA y libera el espacio si estaba activa
  Future<void> deleteReservationAtomic(String reservationId) async {
    final resRef = _reservationsRef.doc(reservationId);

    await _firestore.runTransaction((transaction) async {
      final resSnap = await transaction.get(resRef);
      if (!resSnap.exists) return;

      final res = Reservation.fromDoc(resSnap);
      if (res.status == ReservationStatus.activa) {
        final spaceRef = _spacesRef.doc(res.spaceId);
        final spaceSnap = await transaction.get(spaceRef);
        if (spaceSnap.exists) {
          final curId = spaceSnap.data()?['currentReservationId'] as String?;
          if (curId == reservationId) {
            transaction.update(spaceRef, {
              'status': 'disponible',
              'currentReservationId': null,
              'occupiedByPlate': null,
            });
          }
        }
      }

      transaction.delete(resRef);
    });
  }
}
