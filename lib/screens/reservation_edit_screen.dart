import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/parking_space.dart';
import '../models/reservation.dart';
import '../models/vehicle.dart';
import '../services/error_messages.dart';
import '../services/reservations_repository.dart';
import '../services/spaces_repository.dart';
import '../services/vehicles_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

/// Pantalla 5 (Obligatoria): Formulario para modificar una reserva existente en Firestore.
class ReservationEditScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationEditScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<ReservationEditScreen> createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends State<ReservationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reservationsRepo = ReservationsRepository();
  final _spacesRepo = SpacesRepository();
  final _vehiclesRepo = VehiclesRepository();

  late String _selectedZone;
  late String _selectedSpaceNumber;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _wantsReminder;

  Vehicle? _selectedVehicle;
  bool _isLoadingVehicles = true;
  List<Vehicle> _userVehicles = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final res = widget.reservation;
    _selectedZone = res.zone;
    _selectedSpaceNumber = res.spaceNumber;
    _selectedDate = res.date;
    _startTime = res.startTime;
    _endTime = res.endTime;
    _wantsReminder = res.wantsReminder;

    _loadUserVehicles();
  }

  Future<void> _loadUserVehicles() async {
    try {
      final list = await _vehiclesRepo.getMyVehicles(widget.reservation.ownerId);
      if (mounted) {
        setState(() {
          final matchIndex = list.indexWhere(
            (v) => v.id == widget.reservation.vehicleId || v.plate == widget.reservation.plate,
          );
          if (matchIndex != -1) {
            _userVehicles = list;
            _selectedVehicle = list[matchIndex];
          } else {
            final fallback = Vehicle(
              id: widget.reservation.vehicleId,
              ownerId: widget.reservation.ownerId,
              plate: widget.reservation.plate,
              vehicleType: widget.reservation.vehicleType,
              brand: 'Vehículo registrado',
              color: 'Asignado',
              createdAt: widget.reservation.createdAt,
            );
            _userVehicles = [fallback, ...list];
            _selectedVehicle = fallback;
          }
          _isLoadingVehicles = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handleSave() async {
    // 1. Validar fecha
    final dateError = Validators.validateDate(_selectedDate);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError), backgroundColor: AppTheme.occupiedRed),
      );
      return;
    }

    // 2. Validar hora fin posterior a inicio
    final scheduleError = Validators.validateSchedule(_startTime, _endTime);
    if (scheduleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scheduleError), backgroundColor: AppTheme.occupiedRed),
      );
      return;
    }

    // 3. Validar hora no anterior si la fecha es hoy (corrección solicitada)
    final timeNotPastError = Validators.validateStartTimeNotPast(_selectedDate, _startTime);
    if (timeNotPastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timeNotPastError), backgroundColor: AppTheme.occupiedRed),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final startMin = _startTime.hour * 60 + _startTime.minute;
      final endMin = _endTime.hour * 60 + _endTime.minute;
      final newSpaceId = '${_selectedZone == 'Zona A' ? 'A' : 'B'}-$_selectedSpaceNumber';

      final vehicle = _selectedVehicle ??
          Vehicle(
            id: widget.reservation.vehicleId,
            ownerId: widget.reservation.ownerId,
            plate: widget.reservation.plate,
            vehicleType: widget.reservation.vehicleType,
            brand: 'Vehículo',
            color: 'Estándar',
            createdAt: widget.reservation.createdAt,
          );

      final updated = widget.reservation.copyWith(
        vehicleId: vehicle.id,
        plate: vehicle.plate,
        vehicleType: vehicle.vehicleType,
        zone: _selectedZone,
        spaceId: newSpaceId,
        spaceNumber: _selectedSpaceNumber,
        date: _selectedDate,
        startMinutes: startMin,
        endMinutes: endMin,
        wantsReminder: _wantsReminder,
        updatedAt: DateTime.now(),
      );

      await _reservationsRepo.updateReservationAtomic(
        updatedReservation: updated,
        previousSpaceId: widget.reservation.spaceId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Reserva modificada y sincronizada en Firestore exitosamente!'),
          backgroundColor: AppTheme.availableGreen,
        ),
      );
      Navigator.pop(context); // Vuelve al detalle actualizado
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FirebaseErrorMessages.getFirestoreErrorMessage(e)),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modificar Reserva'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ParkingSpace>>(
          stream: _spacesRepo.getSpacesStream(),
          builder: (context, snapshot) {
            final allSpaces = snapshot.data ?? [];
            final zoneSpaces = allSpaces.where((s) => s.zone == _selectedZone).toList();

            // Espacios que se pueden elegir: los disponibles + el espacio actualmente reservado por esta misma reserva
            final eligibleSpaces = zoneSpaces.where((s) {
              return s.isAvailable ||
                  (s.number == widget.reservation.spaceNumber && s.zone == widget.reservation.zone);
            }).toList();

            final availableNumbers = eligibleSpaces.map((s) => s.number).toSet();
            if (!availableNumbers.contains(_selectedSpaceNumber) && eligibleSpaces.isNotEmpty) {
              _selectedSpaceNumber = eligibleSpaces.first.number;
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vehículo para la reserva',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            if (_isLoadingVehicles)
                              const Center(child: CircularProgressIndicator())
                            else if (_userVehicles.isEmpty)
                              Text(
                                'Placa actual: ${widget.reservation.plate} (${widget.reservation.vehicleType.displayName})',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              )
                            else
                              DropdownButtonFormField<Vehicle>(
                                key: ValueKey('veh-${_selectedVehicle?.id}'),
                                initialValue: _selectedVehicle,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Selecciona tu vehículo',
                                  prefixIcon: Icon(Icons.directions_car_rounded),
                                ),
                                items: _userVehicles.map((v) {
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                      '${v.plate} - ${v.brand} (${v.color})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() => _selectedVehicle = v);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Zona y Espacio
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Espacio de Parqueadero',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('zone-$_selectedZone'),
                                    initialValue: _selectedZone,
                                    decoration: const InputDecoration(labelText: 'Zona *'),
                                    items: const [
                                      DropdownMenuItem(value: 'Zona A', child: Text('Zona A')),
                                      DropdownMenuItem(value: 'Zona B', child: Text('Zona B')),
                                    ],
                                    onChanged: (newZ) {
                                      if (newZ != null) {
                                        setState(() {
                                          _selectedZone = newZ;
                                          final newEligible = allSpaces
                                              .where((s) => s.zone == newZ && s.isAvailable)
                                              .toList();
                                          if (newEligible.isNotEmpty) {
                                            _selectedSpaceNumber = newEligible.first.number;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('space-$_selectedZone-$_selectedSpaceNumber'),
                                    initialValue: availableNumbers.contains(_selectedSpaceNumber)
                                        ? _selectedSpaceNumber
                                        : (eligibleSpaces.isNotEmpty ? eligibleSpaces.first.number : null),
                                    decoration: InputDecoration(
                                      labelText: 'Espacio *',
                                      helperText: '${eligibleSpaces.length} opciones',
                                    ),
                                    items: eligibleSpaces.map((s) {
                                      final isCurrent = s.number == widget.reservation.spaceNumber &&
                                          s.zone == widget.reservation.zone;
                                      return DropdownMenuItem(
                                        value: s.number,
                                        child: Text(
                                          'Espacio ${s.number}${isCurrent ? ' (Actual)' : ''}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newSpaceNumber) {
                                      if (newSpaceNumber != null) {
                                        setState(() => _selectedSpaceNumber = newSpaceNumber);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fecha y Horario
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha y Horario',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de reserva *',
                                  prefixIcon: Icon(Icons.calendar_month_rounded),
                                ),
                                child: Text(
                                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _pickTime(isStart: true),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Hora inicio *'),
                                      child: Text(
                                        _formatTimeOfDay(_startTime),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _pickTime(isStart: false),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Hora fin *'),
                                      child: Text(
                                        _formatTimeOfDay(_endTime),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Switch recordatorio
                    Card(
                      child: SwitchListTile(
                        value: _wantsReminder,
                        onChanged: (val) => setState(() => _wantsReminder = val),
                        title: const Text(
                          'Deseo recibir recordatorio',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        activeTrackColor: AppTheme.darkHeader,
                        activeThumbColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar Cambios
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? 'Guardando en Firestore...' : 'Guardar modificaciones'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
