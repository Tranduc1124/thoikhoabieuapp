enum FriendRequestStatus { pending, accepted, declined, blocked }

class FriendRequestModel {
  const FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
    required this.toName,
    this.fromUid,
    this.toUid,
    this.fromIdProfile = 0,
    this.toIdProfile = 0,
    this.fromAvatarUrl,
    this.toAvatarUrl,
    this.message = '',
    this.status = FriendRequestStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromName;
  final String toName;
  final String? fromUid;
  final String? toUid;
  final int fromIdProfile;
  final int toIdProfile;
  final String? fromAvatarUrl;
  final String? toAvatarUrl;
  final String message;
  final FriendRequestStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FriendRequestModel.fromMap(Map<String, dynamic> data) {
    return FriendRequestModel(
      id: (data['id'] ?? '').toString(),
      fromUserId: (data['fromUserId'] ?? data['from_user_id'] ?? '').toString(),
      toUserId: (data['toUserId'] ?? data['to_user_id'] ?? '').toString(),
      fromName: (data['fromName'] ?? data['from_name'] ?? 'Bạn học').toString(),
      toName: (data['toName'] ?? data['to_name'] ?? 'Bạn học').toString(),
      fromUid: data['fromUid']?.toString() ?? data['from_uid']?.toString(),
      toUid: data['toUid']?.toString() ?? data['to_uid']?.toString(),
      fromIdProfile:
          (data['fromIdProfile'] ?? data['from_id_profile'] as num?)?.toInt() ??
          0,
      toIdProfile:
          (data['toIdProfile'] ?? data['to_id_profile'] as num?)?.toInt() ?? 0,
      fromAvatarUrl:
          data['fromAvatarUrl']?.toString() ??
          data['from_avatar_url']?.toString(),
      toAvatarUrl:
          data['toAvatarUrl']?.toString() ?? data['to_avatar_url']?.toString(),
      message: (data['message'] ?? '').toString(),
      status: FriendRequestStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: _readDate(data['createdAt'] ?? data['created_at']),
      updatedAt: _readDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromName': fromName,
      'toName': toName,
      'fromUid': fromUid,
      'toUid': toUid,
      'fromIdProfile': fromIdProfile,
      'toIdProfile': toIdProfile,
      'fromAvatarUrl': fromAvatarUrl,
      'toAvatarUrl': toAvatarUrl,
      'message': message,
      'status': status.name,
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
