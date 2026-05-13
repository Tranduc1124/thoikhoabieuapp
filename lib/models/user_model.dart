import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.themeMode = 'system',
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String themeMode;
  final DateTime? createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = (data['name'] as String?)?.trim();
    return AppUser(
      id: doc.id,
      name: name?.isNotEmpty == true ? name! : 'Sinh vien',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      themeMode: data['themeMode'] as String? ?? 'system',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'themeMode': themeMode,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
