import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../models/app_settings_model.dart';
import '../models/classroom_location_model.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/notification_settings_model.dart';
import '../models/profile_card_model.dart';
import '../models/share_schedule_model.dart';
import '../models/user_model.dart';
import '../services/app_feedback_service.dart';
import '../services/app_settings_service.dart';
import '../services/backup_service.dart';
import '../services/classroom_location_service.dart';
import '../services/friend_service.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import '../services/profile_service.dart';
import '../services/share_service.dart';
import '../services/widget_sync_service.dart';
import 'auth_provider.dart';
import 'schedule_provider.dart';

final appSettingsServiceProvider = Provider<AppSettingsService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.uid.isEmpty) return null;
  return AppSettingsService(userId: user.uid);
});

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettingsModel>(
      AppSettingsController.new,
    );

final appSettingsSnapshotProvider = StateProvider<AppSettingsModel?>(
  (ref) => null,
);

final activeThemeModeProvider = StateProvider<String>(
  (ref) => ref.watch(appSettingsSnapshotProvider)?.themeMode ?? 'auto',
);

class AppSettingsController extends AsyncNotifier<AppSettingsModel> {
  int _revision = 0;

  @override
  Future<AppSettingsModel> build() async {
    final service = ref.watch(appSettingsServiceProvider);
    final snapshot = ref.read(appSettingsSnapshotProvider);
    if (service == null) return snapshot ?? const AppSettingsModel();
    final cached = await service.loadCached();
    ref.read(appSettingsSnapshotProvider.notifier).state = cached;
    unawaited(_refreshRemote(service, _revision));
    return cached;
  }

  Future<void> _refreshRemote(AppSettingsService service, int revision) async {
    try {
      final remote = await service.loadRemote();
      if (revision != _revision) return;
      ref.read(appSettingsSnapshotProvider.notifier).state = remote;
      state = AsyncData(remote);
    } catch (_) {}
  }

  Future<void> setThemeMode(String themeMode) async {
    final service = ref.read(appSettingsServiceProvider);
    final current =
        state.valueOrNull ??
        ref.read(appSettingsSnapshotProvider) ??
        await service?.loadCached() ??
        const AppSettingsModel();
    final next = current.copyWith(themeMode: themeMode);
    _revision++;
    _debug('settings theme selected: $themeMode');
    ref.read(activeThemeModeProvider.notifier).state = themeMode;
    ref.read(appSettingsSnapshotProvider.notifier).state = next;
    state = AsyncData(next);
    if (service == null) return;
    await service.cache(next);
    try {
      await service.sync(next);
    } catch (error) {
      throw AppUserMessageException(
        'Đã đổi giao diện trên máy. Đồng bộ sẽ thử lại sau.',
        debugMessage: 'sync theme failed: $error',
        type: AppFeedbackType.warning,
      );
    }
  }

  Future<void> setDynamicIslandEnabled(bool enabled) async {
    final service = ref.read(appSettingsServiceProvider);
    final current =
        state.valueOrNull ??
        ref.read(appSettingsSnapshotProvider) ??
        await service?.loadCached() ??
        const AppSettingsModel();
    final next = current.copyWith(
      dynamicIslandEnabled: enabled,
      liveActivitiesEnabled: enabled,
    );
    _revision++;
    _debug('dynamic island selected value: $enabled');
    ref.read(appSettingsSnapshotProvider.notifier).state = next;
    state = AsyncData(next);
    if (service == null) return;
    await service.cache(next);
    try {
      await service.sync(next);
    } catch (error) {
      throw AppUserMessageException(
        'Không đồng bộ được Dynamic Island. Vui lòng thử lại.',
        debugMessage: 'sync dynamic island failed: $error',
        type: AppFeedbackType.warning,
      );
    }
  }

  void _debug(String message) {
    if (kDebugMode) {
      debugPrint('[AppSettingsController] $message');
    }
  }
}

final liveActivitySupportProvider = FutureProvider<bool>((ref) {
  return LiveActivityService.isLiveActivitySupported();
});

final liveActivitySystemEnabledProvider = FutureProvider<bool>((ref) {
  return LiveActivityService.areLiveActivitiesEnabled();
});

final liveActivityActionsProvider = Provider<LiveActivityActions>((ref) {
  return LiveActivityActions(ref);
});

class LiveActivityActions {
  const LiveActivityActions(this.ref);

  final Ref ref;

  Future<void> setEnabled(bool enabled) async {
    try {
      await ref
          .read(appSettingsProvider.notifier)
          .setDynamicIslandEnabled(enabled);
    } finally {
      await refresh();
    }
  }

  Future<void> refresh() async {
    final settings =
        ref.read(appSettingsProvider).valueOrNull ?? const AppSettingsModel();
    final schedules = ref.read(schedulesProvider).valueOrNull ?? const [];
    await LiveActivityService.refreshLiveActivityForToday(
      schedules: schedules,
      enabled: settings.dynamicIslandEnabled && settings.liveActivitiesEnabled,
    );
  }
}

final notificationSettingsServiceProvider =
    Provider<NotificationSettingsService?>((ref) {
      final user = ref.watch(authControllerProvider).valueOrNull;
      if (user == null || user.uid.isEmpty) return null;
      return NotificationSettingsService(userId: user.uid);
    });

final notificationSettingsProvider = FutureProvider<NotificationSettingsModel>((
  ref,
) async {
  final service = ref.watch(notificationSettingsServiceProvider);
  if (service == null) return const NotificationSettingsModel();
  return service.load();
});

final notificationSettingsActionsProvider =
    Provider<NotificationSettingsActions>((ref) {
      return NotificationSettingsActions(ref);
    });

class NotificationSettingsActions {
  const NotificationSettingsActions(this.ref);

  final Ref ref;

  Future<void> save(NotificationSettingsModel settings) async {
    final service = ref.read(notificationSettingsServiceProvider);
    if (service == null) return;
    await service.save(settings);
    ref.invalidate(notificationSettingsProvider);
    final schedules = ref.read(schedulesProvider).valueOrNull ?? const [];
    await NotificationService.rescheduleAllClassNotifications(
      schedules,
      settings: settings,
    );
  }

  Future<void> requestPermissionAndSave(
    NotificationSettingsModel settings,
  ) async {
    final granted = await NotificationService.requestPermissions();
    await save(
      settings.copyWith(permissionStatus: granted ? 'granted' : 'denied'),
    );
  }

  Future<void> sendTestNotification() {
    return NotificationService.scheduleTestNotification();
  }

  Future<int> logPendingNotifications() async {
    final pending = await NotificationService.pendingNotificationRequests();
    return pending.length;
  }

  Future<void> rescheduleAll() async {
    final settings =
        ref.read(notificationSettingsProvider).valueOrNull ??
        const NotificationSettingsModel();
    final schedules = ref.read(schedulesProvider).valueOrNull ?? const [];
    await NotificationService.rescheduleAllClassNotifications(
      schedules,
      settings: settings,
    );
  }
}

final profileServiceProvider = Provider<ProfileService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.uid.isEmpty) return null;
  return ProfileService(userId: user.uid);
});

final backupServiceProvider = Provider<BackupService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.uid.isEmpty) return null;
  return BackupService(userId: user.uid);
});

final friendServiceProvider = Provider<FriendService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.uid.isEmpty) return null;
  return FriendService(userId: user.uid);
});

final classroomLocationServiceProvider = Provider<ClassroomLocationService?>((
  ref,
) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.uid.isEmpty) return null;
  return ClassroomLocationService(userId: user.uid);
});

final shareServiceProvider = Provider<ShareService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final appUser = ref.watch(appUserProvider).valueOrNull;
  if (user == null || user.uid.isEmpty) return null;
  return ShareService(
    userId: user.uid,
    ownerName: appUser?.displayName ?? user.displayName,
    profilePhoto: appUser?.avatarUrl ?? user.photoURL,
  );
});

final mySharesProvider = FutureProvider<List<ShareScheduleModel>>((ref) async {
  final service = ref.watch(shareServiceProvider);
  if (service == null) return const [];
  return service.listMyShares();
});

final friendsProvider = FutureProvider<List<FriendModel>>((ref) async {
  final service = ref.watch(friendServiceProvider);
  if (service == null) return const [];
  return service.listFriends();
});

final incomingFriendRequestsProvider = FutureProvider<List<FriendRequestModel>>(
  (ref) async {
    final service = ref.watch(friendServiceProvider);
    if (service == null) return const [];
    return service.listIncomingRequests();
  },
);

final friendSearchQueryProvider = StateProvider<String>((ref) => '');

final friendSearchProvider = FutureProvider<List<AppUser>>((ref) async {
  final service = ref.watch(friendServiceProvider);
  final query = ref.watch(friendSearchQueryProvider).trim();
  if (service == null || query.isEmpty) return const [];
  return service.searchUsers(query);
});

final classroomLocationsProvider = FutureProvider<List<ClassroomLocationModel>>(
  (ref) async {
    final service = ref.watch(classroomLocationServiceProvider);
    if (service == null) return const [];
    return service.listLocations();
  },
);

final profileCardsProvider = FutureProvider<List<ProfileCardModel>>((
  ref,
) async {
  final data = await Api.call('profileCard.list');
  final items = (data['cards'] as List? ?? const []);
  return items
      .whereType<Map>()
      .map((item) => ProfileCardModel.fromMap(Map<String, dynamic>.from(item)))
      .toList(growable: false);
});

final publicProfileCardProvider =
    FutureProvider.family<ProfileCardModel?, String>((ref, cardId) async {
      final data = await Api.call(
        'profileCard.get',
        authenticated: false,
        data: {'cardId': cardId.trim()},
      );
      final card = data['card'];
      if (card is! Map) return null;
      return ProfileCardModel.fromMap(Map<String, dynamic>.from(card));
    });

final publicShareProvider = FutureProvider.family<ShareScheduleModel?, String>((
  ref,
  shareId,
) async {
  final service = ref.watch(shareServiceProvider);
  if (service != null) return service.getPublicShare(shareId);
  final data = await Api.call(
    'share.get',
    authenticated: false,
    data: {'shareId': shareId.trim()},
  );
  final share = data['share'];
  if (share is! Map) return null;
  return ShareScheduleModel.fromMap(Map<String, dynamic>.from(share));
});

final widgetSyncActionsProvider = Provider<WidgetSyncActions>((ref) {
  return WidgetSyncActions(ref);
});

class WidgetSyncActions {
  const WidgetSyncActions(this.ref);

  final Ref ref;

  Future<void> syncNow() async {
    final schedules = ref.read(schedulesProvider).valueOrNull ?? const [];
    final theme =
        ref.read(appSettingsProvider).valueOrNull?.themeMode ?? 'system';
    await WidgetSyncService.syncSchedules(
      schedules: schedules,
      themeMode: theme,
    );
    await Api.call('widget.sync');
  }
}
