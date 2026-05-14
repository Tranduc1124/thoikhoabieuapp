import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory FriendModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    final userIds = (data['userIds'] as List? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);
    final profiles = (data['profiles'] as Map<String, dynamic>? ?? const {});
    final friendId = userIds.firstWhere(
      (item) => item != currentUserId,
      orElse: () => currentUserId,
    );
    final friendProfile =
        profiles[friendId] as Map<String, dynamic>? ?? const {};
    return FriendModel(
      id: doc.id,
      userIds: userIds,
      friendId: friendId,
      friendName: friendProfile['name'] as String? ?? 'Bạn học',
      friendAvatarUrl: friendProfile['avatarUrl'] as String?,
      friendUsername: friendProfile['username'] as String?,
      sharedSubjects: (data['sharedSubjects'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      weeklyHours: (friendProfile['weeklyHours'] as num?)?.toDouble() ?? 0,
      studyStreak: (friendProfile['studyStreak'] as num?)?.toInt() ?? 0,
      online: friendProfile['online'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
