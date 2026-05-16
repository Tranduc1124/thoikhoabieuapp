import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/api_exception.dart';
import '../models/auth_session.dart';
import '../models/user_model.dart';
import '../services/app_feedback_service.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

final appUserProvider = AsyncNotifierProvider<AppUserController, AppUser?>(
  AppUserController.new,
);

class AppUserController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final session = await ref.watch(authControllerProvider.future);
    final hasToken = Api.isAuthenticated;
    _debug('auth token exists: ${hasToken ? 'true' : 'false'}');
    if (session == null && !hasToken) {
      return null;
    }
    return _loadUser();
  }

  Future<AppUser?> refresh() => _loadUser(updateState: true);

  Future<AppUser?> _loadUser({bool updateState = false}) async {
    if (!Api.isAuthenticated) {
      if (updateState) {
        state = const AsyncData(null);
      }
      return null;
    }

    Future<Map<String, dynamic>> profileCall() => Api.profileGet();

    try {
      final data = await profileCall();
      final userJson = Api.userPayloadFromData(data);
      _debug('profile.get response has user ${userJson != null}');
      if (userJson == null) {
        throw const AppUserMessageException(
          'Không thể tải hồ sơ của bạn lúc này.',
        );
      }
      final user = AppUser.fromMap(userJson);
      await Api.mergeUserIntoSession(user.toMap());
      await ref.read(authControllerProvider.notifier).syncSessionWithUser(user);
      _debug(
        'current user id/name/email: ${user.id} / ${user.displayName} / ${user.email}',
      );
      if (updateState) {
        state = AsyncData(user);
      }
      return user;
    } on ApiException catch (error) {
      _debug('API error code/message: ${error.code} / ${error.message}');
      if (error.code == 'token_expired' ||
          error.code == 'invalid_token' ||
          error.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).handleSessionExpired();
      }
      rethrow;
    }
  }

  void _debug(String message) {
    if (kDebugMode) {
      debugPrint('[AppUserController] $message');
    }
  }
}

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    await Api.initialize();
    return Api.currentSession;
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await Api.call(
        'auth.login',
        authenticated: false,
        data: {'email': email.trim(), 'password': password},
      );
      await Api.applyAuthPayload(data);
      ref.invalidate(appUserProvider);
      return Api.currentSession;
    });
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? idUser,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await Api.call(
        'auth.register',
        authenticated: false,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          if (idUser != null && idUser.trim().isNotEmpty)
            'idUser': idUser.trim(),
        },
      );
      await Api.applyAuthPayload(data);
      ref.invalidate(appUserProvider);
      return Api.currentSession;
    });
  }

  Future<void> signInWithGoogle() {
    throw const AppUserMessageException('Tính năng này sẽ sớm được hỗ trợ.');
  }

  Future<void> signInWithApple() {
    throw const AppUserMessageException('Tính năng này sẽ sớm được hỗ trợ.');
  }

  Future<void> resetPassword(String email) async {
    await Api.call(
      'auth.resetPassword',
      authenticated: false,
      data: {'email': email.trim()},
    );
  }

  Future<void> syncSessionWithUser(AppUser user) async {
    final current = Api.currentSession;
    if (current == null) return;
    final next = AuthSession(
      uid: user.id,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.avatarUrl,
      token: current.token,
    );
    final unchanged =
        current.uid == next.uid &&
        current.email == next.email &&
        current.displayName == next.displayName &&
        current.photoURL == next.photoURL;
    if (unchanged) return;
    await Api.mergeUserIntoSession(user.toMap());
    state = AsyncData(next);
  }

  Future<void> handleSessionExpired() async {
    await Api.clearSession();
    ref.invalidate(appUserProvider);
    state = const AsyncData(null);
  }

  Future<void> signOut() async {
    try {
      await Api.call('auth.logout');
    } catch (_) {}
    await Api.clearSession();
    ref.invalidate(appUserProvider);
    state = const AsyncData(null);
  }
}
