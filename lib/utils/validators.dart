import 'package:flutter/material.dart';
import '../models/vehicle_type.dart';

/// Funciones utilitarias para la validación de campos de formularios en ParkingUni.
class Validators {
  Validators._();

  /// Dominio institucional requerido para el correo universitario.
  /// Modificar esta constante si la universidad cambia de dominio.
  static const String institutionalDomain = '@universidad.edu';

  /// Valida el nombre completo (obligatorio y mínimo 3 caracteres).
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu nombre completo';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe contener al menos 3 caracteres';
    }
    return null;
  }

  /// Valida el correo institucional (obligatorio y debe finalizar en [institutionalDomain]).
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo institucional';
    }
    final email = value.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un formato de correo electrónico válido';
    }
    if (!email.endsWith(institutionalDomain.toLowerCase())) {
      return 'El correo debe terminar en $institutionalDomain';
    }
    return null;
  }

  /// Valida la contraseña (mínimo 6 caracteres según estándar Firebase).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Valida la confirmación de contraseña.
  static String? validatePasswordConfirm(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != originalPassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Valida la placa según el formato oficial colombiano y tipo de vehículo:
  /// - Automóvil: 3 letras y 3 números (ej: ABC123)
  /// - Motocicleta: 3 letras, 2 números y 1 letra (ej: ABC12D)
  static String? validatePlate(String? value, VehicleType vehicleType) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa la placa del vehículo';
    }
    final cleaned = value.trim().toUpperCase();

    if (vehicleType == VehicleType.automovil) {
      final carRegex = RegExp(r'^[A-Z]{3}[0-9]{3}$');
      if (!carRegex.hasMatch(cleaned)) {
        return 'Placa de automóvil inválida. Formato: 3 letras y 3 números (ej: ABC123)';
      }
    } else {
      final bikeRegex = RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]$');
      if (!bikeRegex.hasMatch(cleaned)) {
        return 'Placa de moto inválida. Formato: 3 letras, 2 números y 1 letra (ej: ABC12D)';
      }
    }
    return null;
  }

  /// Valida que la fecha seleccionada no sea anterior a hoy.
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Por favor selecciona la fecha de reserva';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected.isBefore(today)) {
      return 'La fecha de reserva no puede ser anterior a hoy';
    }
    return null;
  }

  /// Valida que la hora de fin sea posterior a la hora de inicio.
  static String? validateSchedule(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) {
      return 'Debes seleccionar la hora de inicio y de fin';
    }
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes <= startMinutes) {
      return 'La hora de fin debe ser posterior a la hora de inicio';
    }
    return null;
  }

  /// Valida que si la fecha es hoy, la hora de inicio no sea anterior a la hora actual.
  static String? validateStartTimeNotPast(DateTime? date, TimeOfDay? start) {
    if (date == null || start == null) return null;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      final currentMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      if (startMinutes < currentMinutes) {
        return 'La hora de inicio no puede ser anterior a la hora actual';
      }
    }
    return null;
  }

  /// Valida la aceptación obligatoria de términos y condiciones.
  static String? validateTerms(bool? accepted) {
    if (accepted != true) {
      return 'Debes aceptar los términos y condiciones para continuar';
    }
    return null;
  }
}
