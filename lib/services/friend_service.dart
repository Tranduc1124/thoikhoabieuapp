import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';

class FriendService {
  const FriendService({required this.userId});

  final String userId;
  String get _friendsCacheKey => 'friends.$userId.list';
  String get _requestsCacheKey => 'friends.$userId.requests';

  Future<List<FriendModel>> listFriends() async {
    try {
      final data = await Api.call('friend.list');
      final items = (data['friends'] as List? ?? const []);
      await _cacheList(_friendsCacheKey, items);
      return _parseFriends(items);
    } catch (_) {
      return _parseFriends(await _loadCachedList(_friendsCacheKey));
    }
  }

  Future<List<FriendRequestModel>> listIncomingRequests() async {
    try {
      final data = await Api.call('friend.requests');
      final items = (data['requests'] as List? ?? const []);
      await _cacheList(_requestsCacheKey, items);
      return _parseRequests(items);
    } catch (_) {
      return _parseRequests(await _loadCachedList(_requestsCacheKey));
    }
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

  List<FriendModel> _parseFriends(List<Object?> items) {
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

  List<FriendRequestModel> _parseRequests(List<Object?> items) {
    return items
        .whereType<Map>()
        .map(
          (item) => FriendRequestModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> _cacheList(String key, List<Object?> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<List<Object?>> _loadCachedList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded;
  }
}
