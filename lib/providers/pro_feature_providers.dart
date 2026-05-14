import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings_model.dart';
import '../models/notification_settings_model.dart';
import '../models/share_schedule_model.dart';
import '../services/app_settings_service.dart';
import '../services/backup_service.dart';
import '../services/firebase_error_translator.dart';
import '../services/firebase_service.dart';
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
  if (user == null) return null;
  return AppSettingsService(userId: user.uid);
});

final appSettingsProvider = StreamProvider<AppSettingsModel>((ref) {
  final service = ref.watch(appSettingsServiceProvider);
  if (service == null) return Stream.value(const AppSettingsModel());
  return service.watch();
});

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
    final service = ref.read(appSettingsServiceProvider);
    if (service == null) return;
    final current =
        ref.read(appSettingsProvider).valueOrNull ?? const AppSettingsModel();
    final settings = current.copyWith(
      dynamicIslandEnabled: enabled,
      liveActivitiesEnabled: enabled,
    );
    await service.save(settings);
    await refresh();
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
      if (user == null) return null;
      return NotificationSettingsService(userId: user.uid);
    });

final notificationSettingsProvider = StreamProvider<NotificationSettingsModel>((
  ref,
) {
  final service = ref.watch(notificationSettingsServiceProvider);
  if (service == null) return Stream.value(const NotificationSettingsModel());
  return service.watch();
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
  if (user == null) return null;
  return ProfileService(userId: user.uid);
});

final backupServiceProvider = Provider<BackupService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return null;
  return BackupService(userId: user.uid);
});

final shareServiceProvider = Provider<ShareService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final appUser = ref.watch(appUserProvider).valueOrNull;
  if (user == null) return null;
  return ShareService(
    userId: user.uid,
    ownerName: appUser?.name ?? user.displayName ?? 'Sinh viên',
  );
});

final mySharesProvider = StreamProvider<List<ShareScheduleModel>>((ref) {
  final service = ref.watch(shareServiceProvider);
  if (service == null) return Stream.value(const []);
  return service.watchMyShares();
});

final publicShareProvider = FutureProvider.family<ShareScheduleModel?, String>((
  ref,
  shareId,
) async {
  final service = ref.watch(shareServiceProvider);
  if (service != null) return service.getPublicShare(shareId);
  if (FirebaseService.isAvailable) {
    try {
      final doc = await FirebaseService.publicShares()
          .doc(shareId.trim())
          .get();
      if (!doc.exists) return null;
      final share = ShareScheduleModel.fromFirestore(doc);
      if (share.isActive) {
        await doc.reference.update({'viewCount': FieldValue.increment(1)});
      }
      return share;
    } catch (error) {
      throw Exception(FirebaseErrorTranslator.firestore(error));
    }
  }
  return null;
});

final widgetSyncActionsProvider = Provider<WidgetSyncActions>((ref) {
  return WidgetSyncActions(ref);
});

class WidgetSyncActions {
  const WidgetSyncActions(this.ref);

  final Ref ref;

  Future<void> syncNow() async {
    final schedules = ref.read(schedulesProvider).valueOrNull ?? const [];
    final theme = ref.read(appUserProvider).valueOrNull?.themeMode ?? 'system';
    await WidgetSyncService.syncSchedules(
      schedules: schedules,
      themeMode: theme,
    );
  }
}
