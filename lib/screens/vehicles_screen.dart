import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../services/auth_service.dart';
import '../services/error_messages.dart';
import '../services/vehicles_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

/// Pantalla para la gestión y CRUD de los vehículos del usuario (/vehicles/{vehicleId}).
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _repository = VehiclesRepository();

  void _showAddVehicleModal({Vehicle? vehicleToEdit}) {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController(text: vehicleToEdit?.plate ?? '');
    final brandController = TextEditingController(text: vehicleToEdit?.brand ?? '');
    final colorController = TextEditingController(text: vehicleToEdit?.color ?? '');
    VehicleType selectedType = vehicleToEdit?.vehicleType ?? VehicleType.automovil;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            vehicleToEdit == null ? 'Registrar Vehículo' : 'Editar Vehículo',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tipo de vehículo
                      SegmentedButton<VehicleType>(
                        segments: const [
                          ButtonSegment(
                            value: VehicleType.automovil,
                            label: Text('Automóvil'),
                            icon: Icon(Icons.directions_car_rounded),
                          ),
                          ButtonSegment(
                            value: VehicleType.motocicleta,
                            label: Text('Motocicleta'),
                            icon: Icon(Icons.two_wheeler_rounded),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (val) {
                          setModalState(() {
                            selectedType = val.first;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // Placa
                      TextFormField(
                        controller: plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Placa del vehículo *',
                          hintText: selectedType.plateExample,
                          helperText: selectedType.plateHint,
                          prefixIcon: const Icon(Icons.credit_card_rounded),
                        ),
                        validator: (val) => Validators.validatePlate(val, selectedType),
                      ),
                      const SizedBox(height: 14),

                      // Marca
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(
                          labelText: 'Marca y Modelo *',
                          hintText: 'Ej: Mazda 3 / Yamaha FZ',
                          prefixIcon: Icon(Icons.commute_outlined),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Ingresa la marca del vehículo'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Color
                      TextFormField(
                        controller: colorController,
                        decoration: const InputDecoration(
                          labelText: 'Color del vehículo *',
                          hintText: 'Ej: Blanco / Negro',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Ingresa el color del vehículo'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Botón Guardar
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);
                                final uid = AuthService().currentUid;
                                if (uid == null) return;
                                final messenger = ScaffoldMessenger.of(context);

                                try {
                                  if (vehicleToEdit == null) {
                                    await _repository.addVehicle(
                                      ownerId: uid,
                                      plate: plateController.text,
                                      vehicleType: selectedType,
                                      brand: brandController.text,
                                      color: colorController.text,
                                    );
                                  } else {
                                    await _repository.updateVehicle(
                                      Vehicle(
                                        id: vehicleToEdit.id,
                                        ownerId: uid,
                                        plate: plateController.text,
                                        vehicleType: selectedType,
                                        brand: brandController.text,
                                        color: colorController.text,
                                        createdAt: vehicleToEdit.createdAt,
                                      ),
                                    );
                                  }

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        vehicleToEdit == null
                                            ? 'Vehículo registrado exitosamente en Firestore.'
                                            : 'Vehículo actualizado en Firestore.',
                                      ),
                                      backgroundColor: AppTheme.availableGreen,
                                    ),
                                  );
                                } on FirebaseException catch (e) {
                                  setModalState(() => isSaving = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        FirebaseErrorMessages.getFirestoreErrorMessage(e),
                                      ),
                                      backgroundColor: AppTheme.occupiedRed,
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppTheme.occupiedRed,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                vehicleToEdit == null
                                    ? 'Guardar vehículo'
                                    : 'Actualizar vehículo',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.occupiedRed),
              SizedBox(width: 8),
              Text('Eliminar vehículo'),
            ],
          ),
          content: Text(
            '¿Seguro que deseas eliminar el vehículo ${vehicle.plate} (${vehicle.brand})?\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.occupiedRed),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repository.deleteVehicle(vehicle.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehículo ${vehicle.plate} eliminado de Firestore.'),
                      backgroundColor: AppTheme.availableGreen,
                    ),
                  );
                } on FirebaseException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(FirebaseErrorMessages.getFirestoreErrorMessage(e)),
                      backgroundColor: AppTheme.occupiedRed,
                    ),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver tus vehículos.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.darkHeader,
        foregroundColor: Colors.white,
        onPressed: () => _showAddVehicleModal(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar vehículo'),
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: _repository.getMyVehiclesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.occupiedRed),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar vehículos: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.darkHeader.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No tienes vehículos registrados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registra tu automóvil o motocicleta para seleccionarlo rápidamente al reservar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddVehicleModal(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Registrar primer vehículo'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.darkHeader,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      vehicle.vehicleType.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 1.2),
                        ),
                        child: Text(
                          vehicle.plate,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vehicle.brand,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Color: ${vehicle.color} • ${vehicle.vehicleType.displayName}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showAddVehicleModal(vehicleToEdit: vehicle);
                      } else if (val == 'delete') {
                        _confirmDelete(vehicle);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppTheme.occupiedRed),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: AppTheme.occupiedRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
