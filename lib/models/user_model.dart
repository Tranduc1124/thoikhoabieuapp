class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    this.bio = '',
    this.avatarUrl,
    this.themeMode = 'system',
    this.profileTheme = 'aurora',
    this.favoriteSubject = '',
    this.accentColor = 0xFF6A8DFF,
    this.studyStreak = 0,
    this.isProfilePublic = true,
    this.allowFriendsToViewTimetable = true,
    this.hideStatistics = false,
    this.hideStreak = false,
    this.socialLinks = const {},
    this.createdAt,
    this.updatedAt,
    this.lastSyncedAt,
  });

  final String id;
  final String name;
  final String email;
  final String username;
  final String bio;
  final String? avatarUrl;
  final String themeMode;
  final String profileTheme;
  final String favoriteSubject;
  final int accentColor;
  final int studyStreak;
  final bool isProfilePublic;
  final bool allowFriendsToViewTimetable;
  final bool hideStatistics;
  final bool hideStreak;
  final Map<String, String> socialLinks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;

  factory AppUser.fromMap(Map<String, dynamic> data) {
    final id = (data['id'] ?? data['uid'] ?? '').toString();
    final name = (data['name'] as String?)?.trim();
    final username = (data['username'] as String?)?.trim();
    final rawSocialLinks =
        data['socialLinks'] as Map<String, dynamic>? ?? const {};
    return AppUser(
      id: id,
      name: name?.isNotEmpty == true ? name! : 'Sinh viên',
      email: (data['email'] ?? '').toString(),
      username: username?.isNotEmpty == true
          ? username!
          : '@${id.padRight(6, '0').substring(0, 6)}',
      bio: (data['bio'] ?? '').toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      themeMode: (data['themeMode'] ?? 'system').toString(),
      profileTheme: (data['profileTheme'] ?? 'aurora').toString(),
      favoriteSubject: (data['favoriteSubject'] ?? '').toString(),
      accentColor: _readColor(data['accentColor']),
      studyStreak: (data['studyStreak'] as num?)?.toInt() ?? 0,
      isProfilePublic: data['isProfilePublic'] as bool? ?? true,
      allowFriendsToViewTimetable:
          data['allowFriendsToViewTimetable'] as bool? ?? true,
      hideStatistics: data['hideStatistics'] as bool? ?? false,
      hideStreak: data['hideStreak'] as bool? ?? false,
      socialLinks: rawSocialLinks.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      lastSyncedAt: _readDate(data['lastSyncedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'themeMode': themeMode,
      'profileTheme': profileTheme,
      'favoriteSubject': favoriteSubject,
      'accentColor': accentColor,
      'studyStreak': studyStreak,
      'isProfilePublic': isProfilePublic,
      'allowFriendsToViewTimetable': allowFriendsToViewTimetable,
      'hideStatistics': hideStatistics,
      'hideStreak': hideStreak,
      'socialLinks': socialLinks,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  static int _readColor(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0xFF6A8DFF;
    return 0xFF6A8DFF;
  }

  static DateTime? _readDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
