import '../utils/safe_json.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.idUser = '',
    this.idProfile = 0,
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
  final String idUser;
  final int idProfile;
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

  String get emailPrefix {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    final index = trimmed.indexOf('@');
    return index <= 0 ? trimmed : trimmed.substring(0, index);
  }

  String get displayName {
    final candidates = [name, username, emailPrefix, 'Sinh viên'];
    for (final item in candidates) {
      if (item.trim().isNotEmpty) return item.trim();
    }
    return 'Sinh viên';
  }

  String get subtitleText {
    if (email.trim().isNotEmpty) return email.trim();
    if (idUser.trim().isNotEmpty) return '@${idUser.trim()}';
    if (username.trim().isNotEmpty) return '@${username.trim()}';
    return 'Sinh viên';
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    final safeData = JsonSafe.map(data);
    final resolvedId = JsonSafe.string(safeData['id']).trim().isNotEmpty
        ? safeData['id']
        : safeData['uid'];
    final id = JsonSafe.string(resolvedId);
    final name = JsonSafe.string(
      safeData['name'] ?? safeData['displayName'],
    ).trim();
    final username = JsonSafe.string(safeData['username']).trim();
    final idUser = JsonSafe.string(
      safeData['idUser'] ?? safeData['id_user'] ?? username,
    ).trim();
    final rawSocialLinks = JsonSafe.map(safeData['socialLinks']);
    return AppUser(
      id: id,
      name: name,
      email: JsonSafe.string(safeData['email']).trim(),
      idUser: idUser,
      idProfile: JsonSafe.integer(
        safeData['idProfile'] ?? safeData['id_profile'],
      ),
      username: idUser.isEmpty ? username : idUser,
      bio: JsonSafe.string(safeData['bio']),
      avatarUrl: JsonSafe.string(safeData['avatarUrl']).trim().isEmpty
          ? null
          : JsonSafe.string(safeData['avatarUrl']).trim(),
      themeMode: JsonSafe.string(safeData['themeMode'], fallback: 'system'),
      profileTheme: JsonSafe.string(
        safeData['profileTheme'],
        fallback: 'aurora',
      ),
      favoriteSubject: JsonSafe.string(safeData['favoriteSubject']),
      accentColor: _readColor(safeData['accentColor']),
      studyStreak: JsonSafe.integer(safeData['studyStreak']),
      isProfilePublic: JsonSafe.boolean(
        safeData['isProfilePublic'],
        fallback: true,
      ),
      allowFriendsToViewTimetable: JsonSafe.boolean(
        safeData['allowFriendsToViewTimetable'],
        fallback: true,
      ),
      hideStatistics: JsonSafe.boolean(safeData['hideStatistics']),
      hideStreak: JsonSafe.boolean(safeData['hideStreak']),
      socialLinks: rawSocialLinks.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      createdAt: _readDate(safeData['createdAt']),
      updatedAt: _readDate(safeData['updatedAt']),
      lastSyncedAt: _readDate(safeData['lastSyncedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idUser': idUser,
      'id_user': idUser,
      'idProfile': idProfile,
      'id_profile': idProfile,
      'name': name,
      'displayName': displayName,
      'email': email,
      'username': idUser.isEmpty ? username : idUser,
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
