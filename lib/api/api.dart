import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../services/app_feedback_service.dart';
import '../services/api_error_translator.dart';

class Api {
  Api._();

  static const baseUrl = 'http://minhduc.huutien.store/api.php';
  static const appKey = 'thoikhoabieuapp_public_key';
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth.token';
  static const _sessionKey = 'auth.session';

  static final Uri _uri = Uri.parse(baseUrl);

  static AuthSession? _session;

  static AuthSession? get currentSession => _session;
  static String? get token => _session?.token;
  static bool get isAuthenticated => token != null && token!.isNotEmpty;

  static Future<void> initialize() async {
    final sessionRaw = await _storage.read(key: _sessionKey);
    if (sessionRaw?.isNotEmpty == true) {
      try {
        _session = AuthSession.fromMap(
          jsonDecode(sessionRaw!) as Map<String, dynamic>,
        );
      } catch (_) {
        await clearSession();
      }
      return;
    }

    final token = await _storage.read(key: _tokenKey);
    if (token?.isNotEmpty == true) {
      _session = AuthSession(
        uid: '',
        email: '',
        displayName: 'Sinh viên',
        token: token!,
      );
    }
  }

  static Future<void> clearSession() async {
    _session = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _sessionKey);
  }

  static Future<void> applyAuthPayload(Map<String, dynamic> data) async {
    final token = (data['token'] ?? '').toString();
    final user = Map<String, dynamic>.from(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    _session = AuthSession.fromMap({...user, 'token': token});
    await _storage.write(key: _tokenKey, value: _session!.token);
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(_session!.toMap()),
    );
  }

  static Future<Map<String, dynamic>> call(
    String action, {
    Map<String, dynamic>? data,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 18),
    int retryCount = 1,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        final response = await http
            .post(
              _uri,
              headers: _headers(authenticated: authenticated),
              body: jsonEncode({
                'action': action,
                'data': data ?? const <String, dynamic>{},
              }),
            )
            .timeout(timeout);
        return _parseResponse(response);
      } on TimeoutException catch (error) {
        if (attempt >= retryCount) rethrow;
        attempt++;
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
        if (error.message == null) {}
      } on SocketException {
        if (attempt >= retryCount) rethrow;
        attempt++;
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
  }

  static Future<Map<String, dynamic>> upload(
    String action, {
    required File file,
    String fileField = 'file',
    Map<String, dynamic>? data,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final request = http.MultipartRequest('POST', _uri)
      ..headers.addAll(_headers(authenticated: authenticated, json: false))
      ..fields['action'] = action
      ..fields['data'] = jsonEncode(data ?? const <String, dynamic>{})
      ..files.add(await http.MultipartFile.fromPath(fileField, file.path));

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  static Map<String, String> _headers({
    required bool authenticated,
    bool json = true,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-App-Key': appKey,
    };
    if (json) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (authenticated && token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token!}';
    }
    return headers;
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const AppUserMessageException(
        'Máy chủ trả về dữ liệu không hợp lệ.',
      );
    }

    if (response.statusCode == 401) {
      unawaited(clearSession());
    }

    final success = payload['success'] == true;
    if (!success) {
      final code = (payload['code'] ?? '').toString();
      final message = (payload['message'] ?? '').toString();
      throw AppUserMessageException(
        ApiErrorTranslator.readable('$code $message'),
      );
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'result': data};
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return call(
      'auth.login',
      authenticated: false,
      data: {'email': email, 'password': password},
    );
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return call(
      'auth.register',
      authenticated: false,
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  static Future<Map<String, dynamic>> logout() => call('auth.logout');
  static Future<Map<String, dynamic>> me() => call('auth.me');
  static Future<Map<String, dynamic>> currentUser() => call('profile.get');
  static Future<Map<String, dynamic>> profileGet() => call('profile.get');
  static Future<Map<String, dynamic>> profileUpdate(
    Map<String, dynamic> data,
  ) => call('profile.update', data: data);
  static Future<Map<String, dynamic>> uploadAvatar(File file) =>
      upload('profile.uploadAvatar', file: file, fileField: 'avatar');
  static Future<Map<String, dynamic>> scheduleList() => call('schedule.list');
  static Future<Map<String, dynamic>> scheduleToday() => call('schedule.today');
  static Future<Map<String, dynamic>> scheduleWeek() => call('schedule.week');
  static Future<Map<String, dynamic>> scheduleCreate(
    Map<String, dynamic> data,
  ) => call('schedule.create', data: data);
  static Future<Map<String, dynamic>> scheduleUpdate(
    Map<String, dynamic> data,
  ) => call('schedule.update', data: data);
  static Future<Map<String, dynamic>> scheduleDelete(String id) =>
      call('schedule.delete', data: {'id': id});
  static Future<Map<String, dynamic>> taskList() => call('task.list');
  static Future<Map<String, dynamic>> taskCreate(Map<String, dynamic> data) =>
      call('task.create', data: data);
  static Future<Map<String, dynamic>> taskUpdate(Map<String, dynamic> data) =>
      call('task.update', data: data);
  static Future<Map<String, dynamic>> taskDelete(String id) =>
      call('task.delete', data: {'id': id});
  static Future<Map<String, dynamic>> examList() => call('exam.list');
  static Future<Map<String, dynamic>> examCreate(Map<String, dynamic> data) =>
      call('exam.create', data: data);
  static Future<Map<String, dynamic>> examUpdate(Map<String, dynamic> data) =>
      call('exam.update', data: data);
  static Future<Map<String, dynamic>> examDelete(String id) =>
      call('exam.delete', data: {'id': id});
  static Future<Map<String, dynamic>> studyLogList(Map<String, dynamic> data) =>
      call('studyLog.list', data: data);
  static Future<Map<String, dynamic>> studyLogCreate(
    Map<String, dynamic> data,
  ) => call('studyLog.create', data: data);
  static Future<Map<String, dynamic>> studyLogUpdate(
    Map<String, dynamic> data,
  ) => call('studyLog.update', data: data);
  static Future<Map<String, dynamic>> settingsGet() => call('settings.get');
  static Future<Map<String, dynamic>> settingsUpdate(
    Map<String, dynamic> data,
  ) => call('settings.update', data: data);
  static Future<Map<String, dynamic>> shareCreate(Map<String, dynamic> data) =>
      call('share.create', data: data);
  static Future<Map<String, dynamic>> shareGet(String shareId) =>
      call('share.get', authenticated: false, data: {'shareId': shareId});
  static Future<Map<String, dynamic>> shareDelete(String shareId) =>
      call('share.delete', data: {'shareId': shareId});
  static Future<Map<String, dynamic>> shareImport(Map<String, dynamic> data) =>
      call('share.import', data: data);
  static Future<Map<String, dynamic>> shareMyLinks() => call('share.myLinks');
  static Future<Map<String, dynamic>> friendList() => call('friend.list');
  static Future<Map<String, dynamic>> friendSearch(String query) =>
      call('friend.search', data: {'query': query});
  static Future<Map<String, dynamic>> friendRequest(
    Map<String, dynamic> data,
  ) => call('friend.request', data: data);
  static Future<Map<String, dynamic>> friendAccept(Map<String, dynamic> data) =>
      call('friend.accept', data: data);
  static Future<Map<String, dynamic>> friendReject(String requestId) =>
      call('friend.reject', data: {'requestId': requestId});
  static Future<Map<String, dynamic>> friendRemove(String friendId) =>
      call('friend.remove', data: {'friendId': friendId});
  static Future<Map<String, dynamic>> locationList() => call('location.list');
  static Future<Map<String, dynamic>> locationCreate(
    Map<String, dynamic> data,
  ) => call('location.create', data: data);
  static Future<Map<String, dynamic>> locationUpdate(
    Map<String, dynamic> data,
  ) => call('location.update', data: data);
  static Future<Map<String, dynamic>> locationDelete(String id) =>
      call('location.delete', data: {'id': id});
  static Future<Map<String, dynamic>> backupExport() => call('backup.export');
  static Future<Map<String, dynamic>> backupImport(Map<String, dynamic> data) =>
      call('backup.import', data: data);
  static Future<Map<String, dynamic>> widgetSettings(
    Map<String, dynamic> data,
  ) => call('widget.settings', data: data);
  static Future<Map<String, dynamic>> widgetSync() => call('widget.sync');
  static Future<Map<String, dynamic>> dynamicIslandSettings(
    Map<String, dynamic> data,
  ) => call('dynamicIsland.settings', data: data);
  static Future<Map<String, dynamic>> dynamicIslandSync() =>
      call('dynamicIsland.sync');
  static Future<Map<String, dynamic>> notificationSettings(
    Map<String, dynamic> data,
  ) => call('notification.settings', data: data);
  static Future<Map<String, dynamic>> notificationSync() =>
      call('notification.sync');
}
