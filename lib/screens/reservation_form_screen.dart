import 'package:flutter/material.dart';
import '../data/parking_repository.dart';
import '../models/user_type.dart';
import '../models/vehicle_type.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

/// Pantalla de registro de reserva de parqueadero.
/// Contiene un formulario validado con Form + `GlobalKey<FormState>` y captura
/// todos los datos requeridos bajo reglas estrictas de negocio.
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

  // Controladores de texto
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _plateController;

  // Estados del formulario
  UserType? _selectedUserType = UserType.estudiante;
  VehicleType _selectedVehicleType = VehicleType.automovil;
  late String _selectedZone;
  String? _selectedSpaceNumber;

  // Fechas y horarios
  late DateTime _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  // Switch y Checkbox
  bool _wantsReminder = true;
  bool _acceptTerms = false;
  bool _showTermsError = false;

  final ParkingRepository _repository = ParkingRepository();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _plateController = TextEditingController();

    _selectedZone = widget.initialZone ?? 'Zona A';
    _selectedSpaceNumber = widget.initialSpaceNumber;
    _selectedDate = DateTime.now();

    // Validar si el espacio preseleccionado es válido y está disponible
    _validateInitialSpace();
  }

  void _validateInitialSpace() {
    final available = _repository.getAvailableSpaces(_selectedZone);
    final exists = available.any((s) => s.number == _selectedSpaceNumber);
    if (!exists) {
      _selectedSpaceNumber = available.isNotEmpty ? available.first.number : null;
    }
  }

  @override
  void didUpdateWidget(covariant ReservationFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialZone != null && widget.initialZone != _selectedZone) {
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
    _plateController.dispose();
    super.dispose();
  }

  /// Limpia todos los campos del formulario y los restablece a valores por defecto
  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _plateController.clear();

    setState(() {
      _selectedUserType = UserType.estudiante;
      _selectedVehicleType = VehicleType.automovil;
      _selectedZone = 'Zona A';
      _validateInitialSpace();
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _wantsReminder = true;
      _acceptTerms = false;
      _showTermsError = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario restablecido a valores por defecto.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Procesa la confirmación de la reserva y valida reglas de negocio
  void _submitForm() {
    setState(() {
      _showTermsError = !_acceptTerms;
    });

    // 1. Validar campos del FormState
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor corrige los errores resaltados en el formulario.'),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
      return;
    }

    // 2. Validar horario
    final scheduleError = Validators.validateSchedule(_startTime, _endTime);
    if (scheduleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scheduleError),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
      return;
    }

    if (_selectedSpaceNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay espacios disponibles en la zona seleccionada.'),
          backgroundColor: AppTheme.occupiedRed,
        ),
      );
      return;
    }

    // 3. Crear reserva en el repositorio en memoria
    final result = _repository.createReservation(
      fullName: _nameController.text,
      email: _emailController.text,
      userType: _selectedUserType!,
      vehicleType: _selectedVehicleType,
      plate: _plateController.text,
      zone: _selectedZone,
      spaceNumber: _selectedSpaceNumber!,
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      wantsReminder: _wantsReminder,
    );

    if (result.success) {
      // Notificación verde de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: AppTheme.availableGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Callback o navegación a la pantalla 3 (Mis reservas)
      if (widget.onReservationSuccess != null) {
        widget.onReservationSuccess!();
      } else {
        Navigator.pushReplacementNamed(context, '/mapa');
      }
    } else {
      // Notificación roja de error en regla de negocio
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: AppTheme.occupiedRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Selector de fecha (DatePicker)
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.darkHeader,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Selector de hora (TimePicker)
  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.darkHeader,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Reserva'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _repository,
          builder: (context, _) {
            // Obtener espacios disponibles para la zona actualmente elegida
            final availableSpaces = _repository.getAvailableSpaces(_selectedZone);

            // Si el espacio seleccionado ya no está disponible, ajustar
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
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.darkHeader,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Completa todos los campos obligatorios. Dominio institucional requerido: ${Validators.institutionalDomain}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sección: Datos del Usuario
                    _buildSectionHeader('1. Información del Usuario'),
                    const SizedBox(height: 10),

                    // 1. Nombre completo (TextFormField)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo *',
                        hintText: 'Ej: Alejandro Escorcia',
                        prefixIcon: Icon(Icons.person_rounded, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 14),

                    // 2. Correo institucional (TextFormField con validador de dominio)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Correo institucional *',
                        hintText: 'usuario${Validators.institutionalDomain}',
                        prefixIcon: const Icon(Icons.email_rounded, size: 20),
                        helperText: 'Debe finalizar en ${Validators.institutionalDomain}',
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 14),

                    // 3. Tipo de usuario (DropdownButtonFormField)
                    DropdownButtonFormField<UserType>(
                      key: ValueKey('user-type-$_selectedUserType'),
                      initialValue: _selectedUserType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de usuario *',
                        prefixIcon: Icon(Icons.badge_rounded, size: 20),
                      ),
                      items: UserType.values.map((type) {
                        return DropdownMenuItem<UserType>(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (type) {
                        setState(() {
                          _selectedUserType = type;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Selecciona tu tipo de usuario' : null,
                    ),
                    const SizedBox(height: 20),

                    // Sección: Datos del Vehículo
                    _buildSectionHeader('2. Información del Vehículo'),
                    const SizedBox(height: 10),

                    // 4. Tipo de vehículo (SegmentedButton)
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
                      selected: {_selectedVehicleType},
                      onSelectionChanged: (Set<VehicleType> newSelection) {
                        setState(() {
                          _selectedVehicleType = newSelection.first;
                          // Revalidar placa con el nuevo formato si ya fue ingresada
                          if (_plateController.text.isNotEmpty) {
                            _formKey.currentState?.validate();
                          }
                        });
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Placa con mayúsculas automáticas (TextFormField)
                    TextFormField(
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Placa del vehículo *',
                        hintText: _selectedVehicleType.plateExample,
                        helperText: _selectedVehicleType.plateHint,
                        prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                      ),
                      validator: (val) =>
                          Validators.validatePlate(val, _selectedVehicleType),
                    ),
                    const SizedBox(height: 20),

                    // Sección: Ubicación en Parqueadero
                    _buildSectionHeader('3. Asignación de Espacio'),
                    const SizedBox(height: 10),

                    // 6. Zona y Espacio
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Zona (Zona A / Zona B)
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
                              helperText: _selectedZone == 'Zona A'
                                  ? 'Espacios 01-12'
                                  : 'Espacios 13-24',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Zona A',
                                child: Text('Zona A', overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'Zona B',
                                child: Text('Zona B', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (newZone) {
                              if (newZone != null) {
                                setState(() {
                                  _selectedZone = newZone;
                                  final av = _repository.getAvailableSpaces(newZone);
                                  _selectedSpaceNumber =
                                      av.isNotEmpty ? av.first.number : null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Espacio (Dropdown dinámico que SOLO lista espacios disponibles)
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('space-$_selectedZone-$_selectedSpaceNumber'),
                            initialValue: _selectedSpaceNumber,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Espacio *',
                              prefixIcon: const Icon(Icons.local_parking_rounded, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              helperText: availableSpaces.isEmpty
                                  ? 'Zona llena'
                                  : '${availableSpaces.length} libres',
                            ),
                            items: availableSpaces.map((space) {
                              return DropdownMenuItem<String>(
                                value: space.number,
                                child: Text(
                                  'Espacio ${space.number}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: availableSpaces.isEmpty
                                ? null
                                : (newSpace) {
                                    setState(() {
                                      _selectedSpaceNumber = newSpace;
                                    });
                                  },
                            validator: (val) => val == null
                                ? 'Selecciona un espacio'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sección: Fecha y Horario
                    _buildSectionHeader('4. Fecha y Horario de Reserva'),
                    const SizedBox(height: 10),

                    // 7. Selector de fecha (DatePicker)
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 8. Selectores de hora de inicio y fin (TimePicker)
                    Row(
                      children: [
                        // Hora de inicio
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
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Hora de fin
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
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sección: Opciones y Aceptación
                    _buildSectionHeader('5. Preferencias y Términos'),
                    const SizedBox(height: 10),

                    // 9. Switch: Recibir recordatorio
                    Card(
                      child: SwitchListTile(
                        value: _wantsReminder,
                        onChanged: (val) {
                          setState(() {
                            _wantsReminder = val;
                          });
                        },
                        title: const Text(
                          'Deseo recibir recordatorio',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: const Text(
                          'Te alertaremos minutos antes de tu horario asignado.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        activeTrackColor: AppTheme.darkHeader,
                        activeThumbColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 10. Checkbox: Aceptación de términos y condiciones (Obligatorio)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _showTermsError
                              ? AppTheme.occupiedRed
                              : AppTheme.borderLight,
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
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Declaro conocer las normas viales y de permanencia del campus.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            activeColor: AppTheme.darkHeader,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (_showTermsError)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(
                                'Debes aceptar los términos y condiciones para confirmar la reserva.',
                                style: TextStyle(
                                  color: AppTheme.occupiedRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones de acción: Confirmar reserva y Limpiar formulario
                    Row(
                      children: [
                        // Botón Limpiar formulario (OutlinedButton)
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: _clearForm,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Botón Confirmar reserva (ElevatedButton)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _submitForm,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Confirmar reserva'),
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
