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

  factory ProfileCardModel.fromMap(Map<String, dynamic> data) {
    return ProfileCardModel(
      id: (data['id'] ?? '').toString(),
      ownerId: (data['ownerId'] ?? data['owner_id'] ?? '').toString(),
      displayName: (data['displayName'] ?? data['display_name'] ?? 'Bạn học')
          .toString(),
      username: (data['username'] ?? '').toString(),
      bio: (data['bio'] ?? '').toString(),
      favoriteSubject:
          (data['favoriteSubject'] ?? data['favorite_subject'] ?? '')
              .toString(),
      studyStreak:
          (data['studyStreak'] ?? data['study_streak'] as num?)?.toInt() ?? 0,
      weeklyHours:
          (data['weeklyHours'] ?? data['weekly_hours'] as num?)?.toDouble() ??
          0,
      totalClasses:
          (data['totalClasses'] ?? data['total_classes'] as num?)?.toInt() ?? 0,
      avatarUrl:
          data['avatarUrl']?.toString() ?? data['avatar_url']?.toString(),
      theme: (data['theme'] ?? 'liquidGlass').toString(),
      qrLink: data['qrLink']?.toString() ?? data['qr_link']?.toString(),
      createdAt: _readDate(data['createdAt'] ?? data['created_at']),
      updatedAt: _readDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
