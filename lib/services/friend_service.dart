import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class FriendService {
  const FriendService({required this.userId});

  final String userId;

  Stream<List<FriendModel>> watchFriends() {
    return FirebaseService.friends()
        .where('userIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FriendModel.fromFirestore(doc, currentUserId: userId),
              )
              .toList(growable: false),
        );
  }

  Stream<List<FriendRequestModel>> watchIncomingRequests() {
    return FirebaseService.friendRequests()
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(FriendRequestModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<List<AppUser>> searchUsers(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    final snapshot = await FirebaseService.users().limit(25).get();
    return snapshot.docs
        .where((doc) => doc.id != userId)
        .map(AppUser.fromFirestore)
        .where(
          (user) =>
              user.name.toLowerCase().contains(normalized) ||
              user.username.toLowerCase().contains(normalized) ||
              user.email.toLowerCase().contains(normalized),
        )
        .take(12)
        .toList(growable: false);
  }

  Future<void> sendFriendRequest({
    required AppUser fromUser,
    required AppUser toUser,
    String message = '',
  }) async {
    final docId = '${fromUser.id}_${toUser.id}';
    await FirebaseService.friendRequests().doc(docId).set({
      'fromUserId': fromUser.id,
      'toUserId': toUser.id,
      'fromName': fromUser.name,
      'toName': toUser.name,
      'fromAvatarUrl': fromUser.avatarUrl,
      'toAvatarUrl': toUser.avatarUrl,
      'message': message,
      'status': FriendRequestStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptRequest({
    required FriendRequestModel request,
    required AppUser currentUser,
    required List<ScheduleModel> schedules,
  }) async {
    final friendSnapshot = await FirebaseService.userDoc(
      request.fromUserId,
    ).get();
    final friendUser = AppUser.fromFirestore(friendSnapshot);
    final sharedSubjects = schedules
        .map((item) => item.subjectName)
        .toSet()
        .toList(growable: false);
    final friendDocId = _friendDocId(currentUser.id, request.fromUserId);
    await FirebaseService.friends().doc(friendDocId).set({
      'userIds': [currentUser.id, request.fromUserId]..sort(),
      'sharedSubjects': sharedSubjects,
      'profiles': {
        currentUser.id: {
          'name': currentUser.name,
          'avatarUrl': currentUser.avatarUrl,
          'username': currentUser.username,
          'weeklyHours': 0,
          'studyStreak': currentUser.studyStreak,
          'online': true,
        },
        request.fromUserId: {
          'name': friendUser.name,
          'avatarUrl': friendUser.avatarUrl,
          'username': friendUser.username,
          'weeklyHours': 0,
          'studyStreak': friendUser.studyStreak,
          'online': false,
        },
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseService.friendRequests().doc(request.id).set({
      'status': FriendRequestStatus.accepted.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFriend(String friendId) async {
    final docId = _friendDocId(userId, friendId);
    await FirebaseService.friends().doc(docId).delete();
  }

  String buildProfileShareLink(String username) {
    final handle = username.startsWith('@') ? username.substring(1) : username;
    return 'thoikhoabieu://friend/$handle';
  }

  String _friendDocId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }
}
