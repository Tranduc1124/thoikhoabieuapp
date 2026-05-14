import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings_model.dart';
import '../models/classroom_location_model.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/notification_settings_model.dart';
import '../models/profile_card_model.dart';
import '../models/share_schedule_model.dart';
import '../models/user_model.dart';
import '../services/app_settings_service.dart';
import '../services/backup_service.dart';
import '../services/classroom_location_service.dart';
import '../services/deep_link_service.dart';
import '../services/firebase_error_translator.dart';
import '../services/firebase_service.dart';
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

final friendServiceProvider = Provider<FriendService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return null;
  return FriendService(userId: user.uid);
});

final classroomLocationServiceProvider = Provider<ClassroomLocationService?>((
  ref,
) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return null;
  return ClassroomLocationService(userId: user.uid);
});

final shareServiceProvider = Provider<ShareService?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final appUser = ref.watch(appUserProvider).valueOrNull;
  if (user == null) return null;
  return ShareService(
    userId: user.uid,
    ownerName: appUser?.name ?? user.displayName ?? 'Sinh viên',
    profilePhoto: appUser?.avatarUrl ?? user.photoURL,
  );
});

final mySharesProvider = StreamProvider<List<ShareScheduleModel>>((ref) {
  final service = ref.watch(shareServiceProvider);
  if (service == null) return Stream.value(const []);
  return service.watchMyShares();
});

final friendsProvider = StreamProvider<List<FriendModel>>((ref) {
  final service = ref.watch(friendServiceProvider);
  if (service == null) return Stream.value(const []);
  return service.watchFriends();
});

final incomingFriendRequestsProvider = StreamProvider<List<FriendRequestModel>>(
  (ref) {
    final service = ref.watch(friendServiceProvider);
    if (service == null) return Stream.value(const []);
    return service.watchIncomingRequests();
  },
);

final friendSearchQueryProvider = StateProvider<String>((ref) => '');

final friendSearchProvider = FutureProvider<List<AppUser>>((ref) async {
  final service = ref.watch(friendServiceProvider);
  final query = ref.watch(friendSearchQueryProvider).trim();
  if (service == null || query.isEmpty) return const [];
  return service.searchUsers(query);
});

final classroomLocationsProvider = StreamProvider<List<ClassroomLocationModel>>(
  (ref) {
    final service = ref.watch(classroomLocationServiceProvider);
    if (service == null) return Stream.value(const []);
    return service.watchLocations();
  },
);

final profileCardsProvider = StreamProvider<List<ProfileCardModel>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return FirebaseService.profileCards()
      .where('ownerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(ProfileCardModel.fromFirestore)
            .toList(growable: false),
      );
});

final publicProfileCardProvider =
    FutureProvider.family<ProfileCardModel?, String>((ref, cardId) async {
      final doc = await FirebaseService.profileCards().doc(cardId.trim()).get();
      if (!doc.exists) return null;
      return ProfileCardModel.fromFirestore(doc);
    });

final publicShareProvider = FutureProvider.family<ShareScheduleModel?, String>((
  ref,
  shareId,
) async {
  final service = ref.watch(shareServiceProvider);
  if (service != null) return service.getPublicShare(shareId);
  if (FirebaseService.isAvailable) {
    try {
      final normalized =
          DeepLinkService.extractShareId(shareId) ?? shareId.trim();
      final doc = await FirebaseService.publicShares().doc(normalized).get();
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
