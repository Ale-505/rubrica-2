import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de usuario en Firestore (/users/{uid}).
class AppUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return AppUser(
      id: id,
      name: (map['name'] as String?)?.trim() ?? 'Usuario',
      email: (map['email'] as String?)?.trim() ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser.fromMap(data, doc.id);
  }
}
