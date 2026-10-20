/// Perfil o tipo de usuario institucional que realiza la reserva.
enum UserType {
  estudiante,
  docente,
  trabajador;

  /// Etiqueta amigable para la interfaz.
  String get displayName {
    switch (this) {
      case UserType.estudiante:
        return 'Estudiante';
      case UserType.docente:
        return 'Docente';
      case UserType.trabajador:
        return 'Trabajador';
    }
  }
}
