import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../models/auth_session.dart';
import '../models/user_model.dart';
import '../services/app_feedback_service.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null || session.uid.isEmpty) return null;
  final data = await Api.call('profile.get');
  return AppUser.fromMap(Map<String, dynamic>.from(data['user'] as Map));
});

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

  Future<void> updateThemeMode(String themeMode) async {
    await Api.call('settings.update', data: {'themeMode': themeMode});
    ref.invalidate(appUserProvider);
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
