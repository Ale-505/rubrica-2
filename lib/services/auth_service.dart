import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// Servicio de autenticación con Firebase Auth y sincronización del perfil en Firestore.
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream reactivo de cambios en el estado de autenticación (sesión activa o nula)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// UID del usuario autenticado actual (o null)
  String? get currentUid => _auth.currentUser?.uid;

  /// Obtiene los datos del documento de perfil /users/{uid}
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  /// Stream del perfil del usuario actual para reflejar cambios de nombre en vivo
  Stream<AppUser?> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  /// Inicia sesión con correo institucional y contraseña
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
  }

  /// Registra una nueva cuenta y crea el documento en /users/{uid}
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password.trim(),
    );

    final user = credential.user;
    if (user != null) {
      // Actualizar nombre visible en Auth
      await user.updateDisplayName(cleanName);

      // Crear documento del usuario en Firestore (users/{uid})
      final appUser = AppUser(
        id: user.uid,
        name: cleanName,
        email: cleanEmail,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap());
    }

    return credential;
  }

  /// Envía correo de restablecimiento de contraseña
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  /// Cierra la sesión activa
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
