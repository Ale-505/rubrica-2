import 'package:firebase_auth/firebase_auth.dart';

/// Centralizador de mensajes de error de Firebase en español amigable para el usuario.
class FirebaseErrorMessages {
  FirebaseErrorMessages._();

  /// Traduce excepciones de FirebaseAuthException a mensajes claros en español.
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'El correo ya está registrado por otra cuenta.';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato de correo institucional no es válido.';
      case 'network-request-failed':
        return 'Sin conexión con el servidor. Verifica tu acceso a internet.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta nuevamente más tarde.';
      case 'user-disabled':
        return 'Esta cuenta de usuario ha sido deshabilitada por el administrador.';
      case 'operation-not-allowed':
        return 'La autenticación con correo y contraseña no está habilitada en Firebase Console.';
      default:
        return e.message ?? 'Ocurrió un error de autenticación. Intenta de nuevo.';
    }
  }

  /// Traduce excepciones de Cloud Firestore a mensajes claros en español.
  static String getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para realizar esta acción.';
      case 'unavailable':
        return 'Sin conexión con el servidor. Modo sin conexión activo.';
      case 'not-found':
        return 'El elemento solicitado no existe en la base de datos.';
      case 'already-exists':
        return 'El registro ya existe en el sistema.';
      case 'deadline-exceeded':
        return 'Tiempo de espera agotado al conectar con el servidor.';
      default:
        return e.message ?? 'Ocurrió un error al procesar los datos en el servidor.';
    }
  }
}
