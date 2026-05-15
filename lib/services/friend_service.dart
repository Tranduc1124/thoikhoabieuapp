import '../api/api.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';

class FriendService {
  const FriendService({required this.userId});

  final String userId;

  Future<List<FriendModel>> listFriends() async {
    final data = await Api.call('friend.list');
    final items = (data['friends'] as List? ?? const []);
    return items
        .whereType<Map>()
        .map(
          (item) => FriendModel.fromMap(
            Map<String, dynamic>.from(item),
            currentUserId: userId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<FriendRequestModel>> listIncomingRequests() async {
    final data = await Api.call('friend.requests');
    final items = (data['requests'] as List? ?? const []);
    return items
        .whereType<Map>()
        .map(
          (item) => FriendRequestModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<List<AppUser>> searchUsers(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];
    final data = await Api.call('friend.search', data: {'query': normalized});
    final items = (data['users'] as List? ?? const []);
    return items
        .whereType<Map>()
        .map((item) => AppUser.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> sendFriendRequest({
    required AppUser fromUser,
    required AppUser toUser,
    String message = '',
  }) async {
    await Api.call(
      'friend.request',
      data: {'toUserId': toUser.id, 'message': message},
    );
  }

  Future<void> acceptRequest({
    required FriendRequestModel request,
    required AppUser currentUser,
    required List<ScheduleModel> schedules,
  }) async {
    await Api.call(
      'friend.accept',
      data: {
        'requestId': request.id,
        'sharedSubjects': schedules
            .map((item) => item.subjectName)
            .toSet()
            .toList(growable: false),
      },
    );
  }

  Future<void> rejectRequest(String requestId) async {
    await Api.call('friend.reject', data: {'requestId': requestId});
  }

  Future<void> removeFriend(String friendId) async {
    await Api.call('friend.remove', data: {'friendId': friendId});
  }

  String buildProfileShareLink(String username) {
    final handle = username.startsWith('@') ? username.substring(1) : username;
    return 'thoikhoabieu://friend/$handle';
  }
}
