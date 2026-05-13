import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.themeMode = 'system',
    this.accentColor = 0xFF6A8DFF,
    this.createdAt,
    this.updatedAt,
    this.lastSyncedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String themeMode;
  final int accentColor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = (data['name'] as String?)?.trim();
    return AppUser(
      id: doc.id,
      name: name?.isNotEmpty == true ? name! : 'Sinh vien',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      themeMode: data['themeMode'] as String? ?? 'system',
      accentColor: _readColor(data['accentColor']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastSyncedAt: (data['lastSyncedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'themeMode': themeMode,
      'accentColor': accentColor,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': lastSyncedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(lastSyncedAt!),
    };
  }

  static int _readColor(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0xFF6A8DFF;
    return 0xFF6A8DFF;
  }
}
