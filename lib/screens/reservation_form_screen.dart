import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/parking_space.dart';
import '../models/user_type.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../services/auth_service.dart';
import '../services/error_messages.dart';
import '../services/reservations_repository.dart';
import '../services/spaces_repository.dart';
import '../services/vehicles_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

/// Pantalla 3 (Obligatoria): Formulario de registro de reserva conectado a Cloud Firestore.
class ReservationFormScreen extends StatefulWidget {
  final String? initialZone;
  final String? initialSpaceNumber;
  final VoidCallback? onReservationSuccess;

  const ReservationFormScreen({
    super.key,
    this.initialZone,
    this.initialSpaceNumber,
    this.onReservationSuccess,
  });

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _spacesRepo = SpacesRepository();
  final _reservationsRepo = ReservationsRepository();
  final _vehiclesRepo = VehiclesRepository();

  // Controladores
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Estados del formulario
  UserType _selectedUserType = UserType.estudiante;
  Vehicle? _selectedVehicle;
  late String _selectedZone;
  String? _selectedSpaceNumber;

  late DateTime _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  bool _wantsReminder = true;
  bool _acceptTerms = false;
  bool _showTermsError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedZone = widget.initialZone ?? 'Zona A';
    _selectedSpaceNumber = widget.initialSpaceNumber;
    _selectedDate = DateTime.now();

    _loadUserData();
  }

  void _loadUserData() {
    final user = AuthService().currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant ReservationFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialZone != null) {
      _selectedZone = widget.initialZone!;
    }
    if (widget.initialSpaceNumber != null) {
      _selectedSpaceNumber = widget.initialSpaceNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Limpia todos los campos del formulario tras reserva exitosa o al presionar Limpiar
  void _clearForm() {
    _formKey.currentState?.reset();
    _loadUserData();

    setState(() {
      _selectedUserType = UserType.estudiante;
      _selectedVehicle = null;
      _selectedZone = 'Zona A';
      _selectedSpaceNumber = null;
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _wantsReminder = true;
      _acceptTerms = false;
      _showTermsError = false;
    });
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

  void _showQuickAddVehicleDialog(String uid) {
    final formKey = GlobalKey<FormState>();
    final plateCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    VehicleType type = VehicleType.automovil;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar nuevo vehículo'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<VehicleType>(
                        segments: const [
                          ButtonSegment(
                            value: VehicleType.automovil,
                            label: Text('Automóvil'),
                            icon: Icon(Icons.directions_car_rounded),
                          ),
                          ButtonSegment(
                            value: VehicleType.motocicleta,
                            label: Text('Moto'),
                            icon: Icon(Icons.two_wheeler_rounded),
                          ),
                        ],
                        selected: {type},
                        onSelectionChanged: (val) => setDialogState(() => type = val.first),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: plateCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Placa *',
                          hintText: type.plateExample,
                          helperText: type.plateHint,
                        ),
                        validator: (val) => Validators.validatePlate(val, type),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: brandCtrl,
                        decoration: const InputDecoration(labelText: 'Marca / Modelo *'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: colorCtrl,
                        decoration: const InputDecoration(labelText: 'Color *'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final newV = await _vehiclesRepo.addVehicle(
                              ownerId: uid,
                              plate: plateCtrl.text,
                              vehicleType: type,
                              brand: brandCtrl.text,
                              color: colorCtrl.text,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            setState(() => _selectedVehicle = newV);
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.occupiedRed),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    setState(() => _showTermsError = !_acceptTerms);

    // Validación 1: FormState básico (Nombre, Correo)
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor corrige los errores resaltados en el formulario.'),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
      return;
    }

    // Validación 2: Fecha no anterior a hoy (Corrección solicitada: llamar Validators.validateDate)
    final dateError = Validators.validateDate(_selectedDate);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError), backgroundColor: AppTheme.occupiedRed),
      );
      return;
    }

    // Validación 3: Horario fin posterior a inicio
    final scheduleError = Validators.validateSchedule(_startTime, _endTime);
    if (scheduleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scheduleError), backgroundColor: AppTheme.occupiedRed),
      );
      return;
    }

    // Validación 4: Hora de inicio no anterior si es hoy (Corrección solicitada)
    final timeNotPastError = Validators.validateStartTimeNotPast(_selectedDate, _startTime);
    if (timeNotPastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timeNotPastError), backgroundColor: AppTheme.occupiedRed),
      );
      return;
    }

    // Validación 5: Vehículo seleccionado
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar o registrar un vehículo para la reserva.'),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
      return;
    }

    // Validación 6: Espacio disponible
    if (_selectedSpaceNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un espacio disponible en la zona elegida.'),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
      return;
    }

    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión expirada. Por favor inicia sesión nuevamente.'),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await _reservationsRepo.createReservationAtomic(
        ownerId: user.uid,
        ownerName: _nameController.text.trim(),
        ownerEmail: _emailController.text.trim(),
        userType: _selectedUserType,
        vehicleId: _selectedVehicle!.id,
        plate: _selectedVehicle!.plate,
        vehicleType: _selectedVehicle!.vehicleType,
        zone: _selectedZone,
        spaceNumber: _selectedSpaceNumber!,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        wantsReminder: _wantsReminder,
      );

      if (!mounted) return;

      // 1. Limpiar el formulario después de una reserva exitosa (Corrección solicitada)
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('¡Reserva confirmada en Firestore! Espacio ${res.spaceNumber} reservado.'),
              ),
            ],
          ),
          backgroundColor: AppTheme.availableGreen,
        ),
      );

      // Redirigir a listado de reservas
      if (widget.onReservationSuccess != null) {
        widget.onReservationSuccess!();
      }
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Reserva'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ParkingSpace>>(
          stream: _spacesRepo.getSpacesStream(),
          builder: (context, spaceSnapshot) {
            final allSpaces = spaceSnapshot.data ?? [];
            final availableSpaces = allSpaces
                .where((s) => s.zone == _selectedZone && s.isAvailable)
                .toList();

            if (_selectedSpaceNumber != null &&
                !availableSpaces.any((s) => s.number == _selectedSpaceNumber)) {
              _selectedSpaceNumber =
                  availableSpaces.isNotEmpty ? availableSpaces.first.number : null;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner informativo
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_done_rounded, color: AppTheme.availableGreen, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Reserva en tiempo real con Cloud Firestore. Dominio institucional: ${Validators.institutionalDomain}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sección 1: Datos de Usuario
                    _buildSectionHeader('1. Información del Usuario'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo *',
                        prefixIcon: Icon(Icons.person_rounded, size: 20),
                      ),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Correo institucional (Cuenta activa)',
                        prefixIcon: Icon(Icons.email_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserType>(
                      key: ValueKey('user-type-$_selectedUserType'),
                      initialValue: _selectedUserType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de usuario *',
                        prefixIcon: Icon(Icons.badge_rounded, size: 20),
                      ),
                      items: UserType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.displayName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUserType = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Sección 2: Selección de Vehículo
                    _buildSectionHeader('2. Vehículo Registrado'),
                    const SizedBox(height: 10),
                    if (uid != null)
                      StreamBuilder<List<Vehicle>>(
                        stream: _vehiclesRepo.getMyVehiclesStream(uid),
                        builder: (context, vSnap) {
                          final vehicles = vSnap.data ?? [];
                          if (_selectedVehicle == null && vehicles.isNotEmpty) {
                            _selectedVehicle = vehicles.first;
                          }

                          final currentV = vehicles.any((v) => v.id == _selectedVehicle?.id)
                              ? _selectedVehicle
                              : (vehicles.isNotEmpty ? vehicles.first : null);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (vehicles.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.reservedAmberLight.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.reservedAmber.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: AppTheme.reservedAmber, size: 20),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'No tienes vehículos registrados aún.',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _showQuickAddVehicleDialog(uid),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Registrar'),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<Vehicle>(
                                        key: ValueKey('veh-${currentV?.id}'),
                                        initialValue: currentV,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Vehículo *',
                                          prefixIcon: Icon(Icons.directions_car_rounded, size: 20),
                                        ),
                                        items: vehicles.map((v) {
                                          return DropdownMenuItem(
                                            value: v,
                                            child: Text(
                                              '${v.plate} - ${v.brand} (${v.color})',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (newV) {
                                          setState(() => _selectedVehicle = newV);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filledTonal(
                                      tooltip: 'Registrar otro vehículo',
                                      icon: const Icon(Icons.add_rounded),
                                      onPressed: () => _showQuickAddVehicleDialog(uid),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // Sección 3: Asignación de Espacio en tiempo real
                    _buildSectionHeader('3. Asignación de Espacio en Vivo'),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Zona
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('zone-$_selectedZone'),
                            initialValue: _selectedZone,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Zona *',
                              prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              helperText: _selectedZone == 'Zona A' ? 'Espacios 01-12' : 'Espacios 13-24',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Zona A', child: Text('Zona A')),
                              DropdownMenuItem(value: 'Zona B', child: Text('Zona B')),
                            ],
                            onChanged: (newZone) {
                              if (newZone != null) {
                                setState(() {
                                  _selectedZone = newZone;
                                  final av = allSpaces.where((s) => s.zone == newZone && s.isAvailable).toList();
                                  _selectedSpaceNumber = av.isNotEmpty ? av.first.number : null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Espacio disponible
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('space-$_selectedZone-$_selectedSpaceNumber'),
                            initialValue: availableSpaces.any((s) => s.number == _selectedSpaceNumber)
                                ? _selectedSpaceNumber
                                : (availableSpaces.isNotEmpty ? availableSpaces.first.number : null),
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Espacio *',
                              prefixIcon: const Icon(Icons.local_parking_rounded, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              helperText: availableSpaces.isEmpty
                                  ? 'Zona llena'
                                  : '${availableSpaces.length} disponibles',
                            ),
                            items: availableSpaces.map((space) {
                              return DropdownMenuItem<String>(
                                value: space.number,
                                child: Text('Espacio ${space.number}', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: availableSpaces.isEmpty
                                ? null
                                : (newSpace) {
                                    setState(() => _selectedSpaceNumber = newSpace);
                                  },
                            validator: (val) => val == null ? 'Selecciona un espacio' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sección 4: Fecha y Horario
                    _buildSectionHeader('4. Fecha y Horario de Reserva'),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de reserva *',
                          prefixIcon: Icon(Icons.calendar_month_rounded, size: 20),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(isStart: true),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Hora inicio *',
                                prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                              ),
                              child: Text(
                                _formatTimeOfDay(_startTime),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(isStart: false),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Hora fin *',
                                prefixIcon: Icon(Icons.timer_outlined, size: 20),
                              ),
                              child: Text(
                                _formatTimeOfDay(_endTime),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sección 5: Preferencias y Términos
                    _buildSectionHeader('5. Preferencias y Términos'),
                    const SizedBox(height: 10),
                    Card(
                      child: SwitchListTile(
                        value: _wantsReminder,
                        onChanged: (val) => setState(() => _wantsReminder = val),
                        title: const Text(
                          'Deseo recibir recordatorio',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Alerta antes del horario asignado.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        activeTrackColor: AppTheme.darkHeader,
                        activeThumbColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _showTermsError ? AppTheme.occupiedRed : AppTheme.borderLight,
                          width: _showTermsError ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            value: _acceptTerms,
                            onChanged: (val) {
                              setState(() {
                                _acceptTerms = val ?? false;
                                if (_acceptTerms) _showTermsError = false;
                              });
                            },
                            title: const Text(
                              'Acepto los términos y condiciones de uso del parqueadero *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Declaro conocer las normas viales y de permanencia del campus.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            activeColor: AppTheme.darkHeader,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (_showTermsError)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(
                                'Debes aceptar los términos y condiciones para confirmar la reserva.',
                                style: TextStyle(color: AppTheme.occupiedRed, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _clearForm,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitForm,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(_isSubmitting ? 'Confirmando...' : 'Confirmar reserva'),
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkHeader,
        letterSpacing: 0.2,
      ),
    );
  }
}
