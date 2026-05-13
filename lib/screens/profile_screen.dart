import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/schedule_model.dart';
import '../providers/auth_provider.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final schedules =
        ref.watch(schedulesProvider).valueOrNull ?? const <ScheduleModel>[];
    final stats = ref.watch(weeklyStatsProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Chưa có profile',
          message: 'Đăng nhập để đồng bộ hồ sơ lên cloud.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const SectionHeader(
                title: 'Hồ sơ học tập',
                subtitle: 'Profile, đồng bộ cloud và sao lưu dữ liệu',
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _changeAvatar,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundImage: user.avatarUrl == null
                            ? null
                            : (user.avatarUrl!.startsWith('http')
                                  ? NetworkImage(user.avatarUrl!)
                                  : null),
                        child: user.avatarUrl == null
                            ? const Icon(Icons.person_rounded, size: 42)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(user.email),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'Môn học',
                            value: '${schedules.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(
                            label: 'Giờ tuần',
                            value: stats?.totalHours.toStringAsFixed(1) ?? '0',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(label: 'Theme', value: user.themeMode),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Ngày tạo',
                      value:
                          user.createdAt
                              ?.toLocal()
                              .toString()
                              .split('.')
                              .first ??
                          '--',
                    ),
                    const Divider(height: 20),
                    _InfoRow(
                      label: 'Đồng bộ cuối',
                      value:
                          user.lastSyncedAt
                              ?.toLocal()
                              .toString()
                              .split('.')
                              .first ??
                          'Chưa rõ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _syncing ? null : _syncNow,
                icon: _syncing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_sync_rounded),
                label: const Text('Đồng bộ dữ liệu'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _exportBackup,
                icon: const Icon(Icons.backup_rounded),
                label: const Text('Sao lưu dữ liệu JSON'),
              ),
              const SizedBox(height: 10),
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
    final avatar = await service.pickAndUploadAvatar();
    if (avatar == null) return;
    await service.updateProfile(name: user.name, avatarUrl: avatar);
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await ref.read(widgetSyncActionsProvider).syncNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đồng bộ cloud/widget.')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _exportBackup() async {
    final service = ref.read(backupServiceProvider);
    if (service == null) return;
    final file = await service.exportUserDataToJson();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Backup Thời Khoá Biểu'),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.42),
      ),
      child: Column(
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
