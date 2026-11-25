import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';

/// Repositorio para la gestión CRUD de vehículos en Firestore (/vehicles/{vehicleId}).
class VehiclesRepository {
  VehiclesRepository._internal();
  static final VehiclesRepository _instance = VehiclesRepository._internal();
  factory VehiclesRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vehiclesRef =>
      _firestore.collection('vehicles');

  /// Stream reactivo de los vehículos pertenecientes al usuario autenticado (Plan Spark optimizado)
  Stream<List<Vehicle>> getMyVehiclesStream(String ownerId) {
    return _vehiclesRef
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Vehicle.fromDoc(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Consulta una sola vez la lista de vehículos del usuario
  Future<List<Vehicle>> getMyVehicles(String ownerId) async {
    final query = await _vehiclesRef.where('ownerId', isEqualTo: ownerId).get();
    final list = query.docs.map((doc) => Vehicle.fromDoc(doc)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Registra un nuevo vehículo para el usuario
  Future<Vehicle> addVehicle({
    required String ownerId,
    required String plate,
    required VehicleType vehicleType,
    required String brand,
    required String color,
  }) async {
    final docRef = _vehiclesRef.doc();
    final vehicle = Vehicle(
      id: docRef.id,
      ownerId: ownerId,
      plate: plate.toUpperCase().trim(),
      vehicleType: vehicleType,
      brand: brand.trim(),
      color: color.trim(),
      createdAt: DateTime.now(),
    );

    await docRef.set(vehicle.toMap());
    return vehicle;
  }

  /// Actualiza los datos de un vehículo existente
  Future<void> updateVehicle(Vehicle vehicle) async {
    await _vehiclesRef.doc(vehicle.id).update(vehicle.toMap());
  }

  /// Elimina un vehículo registrado
  Future<void> deleteVehicle(String vehicleId) async {
    await _vehiclesRef.doc(vehicleId).delete();
  }
}
