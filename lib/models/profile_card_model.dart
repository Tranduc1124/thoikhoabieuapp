import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCardModel {
  const ProfileCardModel({
    required this.id,
    required this.ownerId,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.favoriteSubject,
    required this.studyStreak,
    required this.weeklyHours,
    required this.totalClasses,
    this.avatarUrl,
    this.theme = 'liquidGlass',
    this.qrLink,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String displayName;
  final String username;
  final String bio;
  final String favoriteSubject;
  final int studyStreak;
  final double weeklyHours;
  final int totalClasses;
  final String? avatarUrl;
  final String theme;
  final String? qrLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfileCardModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ProfileCardModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Bạn học',
      username: data['username'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      favoriteSubject: data['favoriteSubject'] as String? ?? '',
      studyStreak: (data['studyStreak'] as num?)?.toInt() ?? 0,
      weeklyHours: (data['weeklyHours'] as num?)?.toDouble() ?? 0,
      totalClasses: (data['totalClasses'] as num?)?.toInt() ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
      theme: data['theme'] as String? ?? 'liquidGlass',
      qrLink: data['qrLink'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'favoriteSubject': favoriteSubject,
      'studyStreak': studyStreak,
      'weeklyHours': weeklyHours,
      'totalClasses': totalClasses,
      'avatarUrl': avatarUrl,
      'theme': theme,
      'qrLink': qrLink,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
