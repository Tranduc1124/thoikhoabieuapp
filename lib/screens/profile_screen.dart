import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _syncing = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final schedules =
        ref.watch(schedulesProvider).valueOrNull ?? const <ScheduleModel>[];
    final stats = ref.watch(weeklyStatsProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Chưa có profile',
          message: 'Đăng nhập để đồng bộ hồ sơ và dữ liệu học tập lên cloud.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/friends'),
            icon: const Icon(Icons.people_alt_rounded),
          ),
        ],
      ),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _ProfileHeroCard(
                user: user,
                schedules: schedules,
                weeklyHours: stats?.totalHours ?? 0,
                authPhotoUrl: auth?.photoURL,
                onEdit: _editProfile,
                onAvatarTap: _changeAvatar,
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    _InfoRow(label: 'Email', value: user.email),
                    const Divider(height: 22),
                    _InfoRow(label: 'Username', value: user.username),
                    const Divider(height: 22),
                    _InfoRow(
                      label: 'Yêu thích',
                      value: user.favoriteSubject.isEmpty
                          ? 'Chưa đặt'
                          : user.favoriteSubject,
                    ),
                    const Divider(height: 22),
                    _InfoRow(
                      label: 'Tạo tài khoản',
                      value:
                          user.createdAt
                              ?.toLocal()
                              .toString()
                              .split('.')
                              .first ??
                          '--',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Cloud & Social',
                subtitle:
                    'Đồng bộ profile, tạo profile card và quản lý các tuỳ chọn riêng tư.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _syncing ? null : _syncNow,
                      icon: _syncing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_sync_rounded),
                      label: const Text('Đồng bộ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _createProfileCard,
                      icon: const Icon(Icons.badge_rounded),
                      label: const Text('Profile Card'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.backup_rounded),
                      label: const Text('Backup JSON'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/friends'),
                      icon: const Icon(Icons.people_alt_rounded),
                      label: const Text('Friends'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    final service = ref.read(profileServiceProvider);
    final user = ref.read(appUserProvider).valueOrNull;
    if (service == null || user == null) return;
    try {
      final result = await service.pickAndUploadAvatar();
      if (!mounted) return;
      if (result.warningMessage != null) {
        AppFeedbackService.info(context, result.warningMessage!);
      }
      if (result.avatarUrl == null) return;
      await service.updateProfile(
        name: user.name,
        username: user.username,
        bio: user.bio,
        favoriteSubject: user.favoriteSubject,
        avatarUrl: result.avatarUrl,
        profileTheme: user.profileTheme,
        isProfilePublic: user.isProfilePublic,
        allowFriendsToViewTimetable: user.allowFriendsToViewTimetable,
        hideStatistics: user.hideStatistics,
        hideStreak: user.hideStreak,
      );
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã cập nhật ảnh đại diện');
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    }
  }

  Future<void> _editProfile() async {
    final service = ref.read(profileServiceProvider);
    final user = ref.read(appUserProvider).valueOrNull;
    if (service == null || user == null) return;
    final nameController = TextEditingController(text: user.name);
    final usernameController = TextEditingController(text: user.username);
    final bioController = TextEditingController(text: user.bio);
    final favoriteController = TextEditingController(
      text: user.favoriteSubject,
    );
    bool isPublic = user.isProfilePublic;
    bool allowTimetable = user.allowFriendsToViewTimetable;
    bool hideStats = user.hideStatistics;
    bool hideStreak = user.hideStreak;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Chỉnh sửa profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: favoriteController,
                      decoration: const InputDecoration(
                        labelText: 'Môn học yêu thích',
                      ),
                    ),
                    SwitchListTile(
                      value: isPublic,
                      onChanged: (value) =>
                          setStateDialog(() => isPublic = value),
                      title: const Text('Profile công khai'),
                    ),
                    SwitchListTile(
                      value: allowTimetable,
                      onChanged: (value) =>
                          setStateDialog(() => allowTimetable = value),
                      title: const Text('Cho bạn bè xem thời khóa biểu'),
                    ),
                    SwitchListTile(
                      value: hideStats,
                      onChanged: (value) =>
                          setStateDialog(() => hideStats = value),
                      title: const Text('Ẩn thống kê'),
                    ),
                    SwitchListTile(
                      value: hideStreak,
                      onChanged: (value) =>
                          setStateDialog(() => hideStreak = value),
                      title: const Text('Ẩn streak'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            await service.updateProfile(
                              name: nameController.text.trim(),
                              username: usernameController.text.trim(),
                              bio: bioController.text.trim(),
                              favoriteSubject: favoriteController.text.trim(),
                              profileTheme: user.profileTheme,
                              isProfilePublic: isPublic,
                              allowFriendsToViewTimetable: allowTimetable,
                              hideStatistics: hideStats,
                              hideStreak: hideStreak,
                            );
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            AppFeedbackService.success(
                              this.context,
                              'Đã cập nhật hồ sơ',
                            );
                          } catch (error) {
                            if (!mounted) return;
                            AppFeedbackService.error(this.context, error);
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await ref.read(widgetSyncActionsProvider).syncNow();
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã đồng bộ dữ liệu');
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _exportBackup() async {
    final service = ref.read(backupServiceProvider);
    if (service == null) return;
    final file = await service.exportUserDataToJson();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Backup Thời Khóa Biểu'),
    );
  }

  Future<void> _createProfileCard() async {
    final service = ref.read(profileServiceProvider);
    final user = ref.read(appUserProvider).valueOrNull;
    final schedules =
        ref.read(schedulesProvider).valueOrNull ?? const <ScheduleModel>[];
    final stats = ref.read(weeklyStatsProvider).valueOrNull;
    if (service == null || user == null) return;
    try {
      final card = await service.createProfileCard(
        user: user,
        schedules: schedules,
        weeklyHours: stats?.totalHours ?? 0,
      );
      if (!mounted) return;
      context.push('/profile-card', extra: card);
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    }
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.schedules,
    required this.weeklyHours,
    required this.authPhotoUrl,
    required this.onEdit,
    required this.onAvatarTap,
  });

  final AppUser user;
  final List<ScheduleModel> schedules;
  final double weeklyHours;
  final String? authPhotoUrl;
  final VoidCallback onEdit;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 36,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'profile-avatar-${user.id}',
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: AppAvatar(
                    name: user.name,
                    primaryUrl: user.avatarUrl,
                    secondaryUrl: authPhotoUrl,
                    radius: 38,
                    iconSize: 32,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(user.username),
                    if (user.bio.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.bio,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Streak',
                  value: user.hideStreak ? 'Ẩn' : '${user.studyStreak} ngày',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Giờ tuần',
                  value: user.hideStatistics
                      ? 'Ẩn'
                      : weeklyHours.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(label: 'Buổi học', value: '${schedules.length}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).colorScheme.tileSurface,
        border: Border.all(
          color: Theme.of(context).colorScheme.glassStrokeSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
