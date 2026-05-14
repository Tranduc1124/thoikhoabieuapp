import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined, blocked }

class FriendRequestModel {
  const FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
    required this.toName,
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
  final String? fromAvatarUrl;
  final String? toAvatarUrl;
  final String message;
  final FriendRequestStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FriendRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FriendRequestModel(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      fromName: data['fromName'] as String? ?? 'Bạn học',
      toName: data['toName'] as String? ?? 'Bạn học',
      fromAvatarUrl: data['fromAvatarUrl'] as String?,
      toAvatarUrl: data['toAvatarUrl'] as String?,
      message: data['message'] as String? ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromName': fromName,
      'toName': toName,
      'fromAvatarUrl': fromAvatarUrl,
      'toAvatarUrl': toAvatarUrl,
      'message': message,
      'status': status.name,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
