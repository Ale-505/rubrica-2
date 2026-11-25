import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_space.dart';
import '../models/space_status.dart';

/// Repositorio de espacios físicos de parqueadero en Cloud Firestore (/parking_spaces/{spaceId}).
class SpacesRepository {
  SpacesRepository._internal();
  static final SpacesRepository _instance = SpacesRepository._internal();
  factory SpacesRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _spacesRef =>
      _firestore.collection('parking_spaces');

  /// Stream en tiempo real de todos los 24 espacios de parqueadero
  Stream<List<ParkingSpace>> getSpacesStream() {
    return _spacesRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((d) => ParkingSpace.fromDoc(d)).toList();
      // Ordenar por número ascendente (01..24)
      list.sort((a, b) => a.number.compareTo(b.number));
      return list;
    });
  }

  /// Obtiene un espacio por su ID único (ej: 'A-01')
  Future<ParkingSpace?> getSpace(String spaceId) async {
    final doc = await _spacesRef.doc(spaceId).get();
    if (!doc.exists) return null;
    return ParkingSpace.fromDoc(doc);
  }

  /// Inicializa los 24 espacios mediante WriteBatch si la colección está vacía.
  /// Por defecto crea los 24 espacios 100% DISPONIBLES (libres).
  /// Si withMockOccupied es true, deja 8 ocupados como datos de prueba de la rúbrica.
  Future<bool> initializeSpacesIfEmpty({bool withMockOccupied = false}) async {
    // Lectura de 1 solo documento para comprobar existencia (ahorro de cuota Spark)
    final existing = await _spacesRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return false; // Ya está inicializado
    }

    final batch = _firestore.batch();

    final occupiedA = withMockOccupied ? {'02', '04', '07', '10'} : <String>{};
    final occupiedB = withMockOccupied ? {'14', '16', '19', '23'} : <String>{};

    // Zona A (01 - 12)
    for (int i = 1; i <= 12; i++) {
      final numStr = i.toString().padLeft(2, '0');
      final isOcc = occupiedA.contains(numStr);
      final id = 'A-$numStr';
      final space = ParkingSpace(
        id: id,
        number: numStr,
        zone: 'Zona A',
        status: isOcc ? SpaceStatus.ocupado : SpaceStatus.disponible,
        occupiedByPlate: isOcc ? 'ABC${100 + i}' : null,
      );
      batch.set(_spacesRef.doc(id), space.toMap());
    }

    // Zona B (13 - 24)
    for (int i = 13; i <= 24; i++) {
      final numStr = i.toString().padLeft(2, '0');
      final isOcc = occupiedB.contains(numStr);
      final id = 'B-$numStr';
      final space = ParkingSpace(
        id: id,
        number: numStr,
        zone: 'Zona B',
        status: isOcc ? SpaceStatus.ocupado : SpaceStatus.disponible,
        occupiedByPlate: isOcc ? 'XYZ${100 + i}' : null,
      );
      batch.set(_spacesRef.doc(id), space.toMap());
    }

    await batch.commit();
    return true;
  }

  /// Restablece todos los 24 espacios a estado DISPONIBLE (100% libres).
  /// Útil si se habían creado espacios ocupados de prueba y se desean limpiar todos.
  Future<void> resetAllSpacesToAvailable() async {
    final batch = _firestore.batch();
    for (int i = 1; i <= 12; i++) {
      final numStr = i.toString().padLeft(2, '0');
      final id = 'A-$numStr';
      batch.update(_spacesRef.doc(id), {
        'status': 'disponible',
        'currentReservationId': null,
        'occupiedByPlate': null,
      });
    }
    for (int i = 13; i <= 24; i++) {
      final numStr = i.toString().padLeft(2, '0');
      final id = 'B-$numStr';
      batch.update(_spacesRef.doc(id), {
        'status': 'disponible',
        'currentReservationId': null,
        'occupiedByPlate': null,
      });
    }
    await batch.commit();
  }
}
