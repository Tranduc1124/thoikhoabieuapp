import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api.dart';
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
import '../widgets/loading_skeleton.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _refreshing = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(appUserProvider);
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final schedules =
        ref.watch(schedulesProvider).valueOrNull ?? const <ScheduleModel>[];
    final stats = ref.watch(weeklyStatsProvider).valueOrNull;
    final hasToken = Api.isAuthenticated;

    if (userState.isLoading && hasToken) {
      return const Scaffold(body: _ProfileLoadingView());
    }

    if (userState.hasError) {
      return Scaffold(
        body: SoftGradientBackground(
          child: SafeArea(
            child: EmptyState(
              title: 'Không tải được hồ sơ',
              message: AppFeedbackService.messageFor(userState.error!),
              action: FilledButton.icon(
                onPressed: () => ref.read(appUserProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
          ),
        ),
      );
    }

    final user = userState.valueOrNull;
    if (!hasToken && user == null) {
      return const Scaffold(
        body: SoftGradientBackground(
          child: SafeArea(
            child: EmptyState(
              title: 'Chưa đăng nhập',
              message:
                  'Đăng nhập để lưu lại thông tin cá nhân và tiếp tục việc học của bạn.',
            ),
          ),
        ),
      );
    }

    if (hasToken && user == null) {
      return const Scaffold(body: _ProfileLoadingView());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
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
                user: user!,
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
                    _InfoRow(
                      label: 'ID người dùng',
                      value: user.idUser.isEmpty ? user.username : user.idUser,
                    ),
                    const Divider(height: 22),
                    _InfoRow(
                      label: 'ID hồ sơ',
                      value: user.idProfile > 0 ? '#${user.idProfile}' : '--',
                    ),
                    const Divider(height: 22),
                    _InfoRow(label: 'Tên hiển thị', value: user.displayName),
                    const Divider(height: 22),
                    _InfoRow(
                      label: 'Môn học yêu thích',
                      value: user.favoriteSubject.isEmpty
                          ? 'Chưa thiết lập'
                          : user.favoriteSubject,
                    ),
                    const Divider(height: 22),
                    _InfoRow(
                      label: 'Ngày tham gia',
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
                title: 'Cá nhân hoá trải nghiệm học tập của bạn',
                subtitle:
                    'Làm mới dữ liệu, chia sẻ hồ sơ và lưu lại thông tin quan trọng khi cần.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _refreshing ? null : _refreshNow,
                      icon: _refreshing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: const Text('Cập nhật dữ liệu'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _createProfileCard,
                      icon: const Icon(Icons.badge_rounded),
                      label: const Text('Thẻ hồ sơ'),
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
                      label: const Text('Tạo bản sao lưu'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/friends'),
                      icon: const Icon(Icons.people_alt_rounded),
                      label: const Text('Bạn bè'),
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
      await ref.read(appUserProvider.notifier).refresh();
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã cập nhật ảnh đại diện.');
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
    final usernameController = TextEditingController(
      text: user.idUser.isEmpty ? user.username : user.idUser,
    );
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
              title: const Text('Chỉnh sửa hồ sơ'),
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
                      decoration: const InputDecoration(
                        labelText: 'ID người dùng',
                        helperText: 'Bạn bè có thể tìm bạn bằng ID này',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Giới thiệu ngắn',
                      ),
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
                      title: const Text('Hiển thị hồ sơ công khai'),
                    ),
                    SwitchListTile(
                      value: allowTimetable,
                      onChanged: (value) =>
                          setStateDialog(() => allowTimetable = value),
                      title: const Text('Cho phép bạn bè xem lịch học'),
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
                      title: const Text('Ẩn chuỗi học tập'),
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
                              idUser: usernameController.text.trim(),
                              username: usernameController.text.trim(),
                              bio: bioController.text.trim(),
                              favoriteSubject: favoriteController.text.trim(),
                              profileTheme: user.profileTheme,
                              isProfilePublic: isPublic,
                              allowFriendsToViewTimetable: allowTimetable,
                              hideStatistics: hideStats,
                              hideStreak: hideStreak,
                            );
                            await ref.read(appUserProvider.notifier).refresh();
                            if (!context.mounted || !mounted) return;
                            Navigator.pop(context);
                            AppFeedbackService.success(
                              this.context,
                              'Đã cập nhật hồ sơ.',
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

  Future<void> _refreshNow() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(appUserProvider.notifier).refresh();
      await ref.read(widgetSyncActionsProvider).syncNow();
      if (!mounted) return;
      AppFeedbackService.success(context, 'Dữ liệu của bạn đã được cập nhật.');
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _exportBackup() async {
    final service = ref.read(backupServiceProvider);
    if (service == null) return;
    final file = await service.exportUserDataToJson();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Bản sao lưu Thời Khóa Biểu',
      ),
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

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return SoftGradientBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: const [
            SectionHeader(
              title: 'Đang đồng bộ hồ sơ…',
              subtitle:
                  'Thông tin cá nhân và dữ liệu học tập đang được chuẩn bị.',
            ),
            SizedBox(height: 16),
            LoadingSkeleton(variant: LoadingSkeletonVariant.profile),
          ],
        ),
      ),
    );
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
                    name: user.displayName,
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
                      user.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(user.subtitleText),
                    if (user.idUser.trim().isNotEmpty ||
                        user.idProfile > 0) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.idUser.trim().isNotEmpty)
                            _IdChip(label: '@${user.idUser.trim()}'),
                          if (user.idProfile > 0)
                            _IdChip(label: 'ID #${user.idProfile}'),
                        ],
                      ),
                    ],
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
                  label: 'Chuỗi học tập',
                  value: user.hideStreak
                      ? 'Đang ẩn'
                      : '${user.studyStreak} ngày',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Giờ mỗi tuần',
                  value: user.hideStatistics
                      ? 'Đang ẩn'
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

class _IdChip extends StatelessWidget {
  const _IdChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.primary.withValues(
          alpha: context.isDark ? 0.18 : 0.12,
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
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
