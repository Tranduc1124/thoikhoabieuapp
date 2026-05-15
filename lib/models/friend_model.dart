class FriendModel {
  const FriendModel({
    required this.id,
    required this.userIds,
    required this.friendId,
    required this.friendName,
    this.friendAvatarUrl,
    this.friendUsername,
    this.sharedSubjects = const [],
    this.weeklyHours = 0,
    this.studyStreak = 0,
    this.online = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final List<String> userIds;
  final String friendId;
  final String friendName;
  final String? friendAvatarUrl;
  final String? friendUsername;
  final List<String> sharedSubjects;
  final double weeklyHours;
  final int studyStreak;
  final bool online;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FriendModel.fromMap(
    Map<String, dynamic> data, {
    required String currentUserId,
  }) {
    final userIds =
        (data['userIds'] as List? ?? data['user_ids'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false);
    final profiles = (data['profiles'] as Map<String, dynamic>? ?? const {});
    final friendId =
        (data['friendId'] ?? data['friend_id'])?.toString() ??
        userIds.firstWhere(
          (item) => item != currentUserId,
          orElse: () => currentUserId,
        );
    final friendProfile =
        profiles[friendId] as Map<String, dynamic>? ??
        (data['profile'] as Map<String, dynamic>? ?? const {});
    return FriendModel(
      id: (data['id'] ?? '').toString(),
      userIds: userIds,
      friendId: friendId,
      friendName: (data['friendName'] ?? friendProfile['name'] ?? 'Bạn học')
          .toString(),
      friendAvatarUrl:
          data['friendAvatarUrl']?.toString() ??
          friendProfile['avatarUrl']?.toString(),
      friendUsername:
          data['friendUsername']?.toString() ??
          friendProfile['username']?.toString(),
      sharedSubjects:
          (data['sharedSubjects'] as List? ??
                  data['shared_subjects'] as List? ??
                  const [])
              .map((item) => item.toString())
              .toList(growable: false),
      weeklyHours:
          (data['weeklyHours'] ?? friendProfile['weeklyHours'] as num?)
              ?.toDouble() ??
          0,
      studyStreak:
          (data['studyStreak'] ?? friendProfile['studyStreak'] as num?)
              ?.toInt() ??
          0,
      online:
          data['online'] as bool? ?? friendProfile['online'] as bool? ?? false,
      createdAt: _readDate(data['createdAt'] ?? data['created_at']),
      updatedAt: _readDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
