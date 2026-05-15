import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/pro_feature_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final themeMode = user?.themeMode ?? 'system';
    final notificationSettings = ref
        .watch(notificationSettingsProvider)
        .valueOrNull;
    final appSettings = ref.watch(appSettingsProvider).valueOrNull;
    final liveActivitySupported =
        ref.watch(liveActivitySupportProvider).valueOrNull ?? false;
    final liveActivitySystemEnabled =
        ref.watch(liveActivitySystemEnabledProvider).valueOrNull ?? true;

    return AppNavigationShell(
      currentIndex: 4,
      child: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            children: [
              const SectionHeader(
                title: 'Cài đặt',
                subtitle: 'Giao diện, thông báo, widget và đồng bộ dữ liệu.',
              ),
              GlassCard(
                onTap: () => context.push('/profile'),
                padding: const EdgeInsets.all(18),
                borderColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.22),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AppAvatar(
                    name: user?.name ?? auth?.displayName ?? 'Tài khoản',
                    primaryUrl: user?.avatarUrl,
                    secondaryUrl: auth?.photoURL,
                    radius: 29,
                  ),
                  title: Text(
                    user?.name ?? auth?.email ?? 'Tài khoản',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    user?.email ?? auth?.email ?? 'Đã đăng nhập qua API',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'Giao diện',
                child: SegmentedButton<String>(
                  key: ValueKey(themeMode),
                  segments: const [
                    ButtonSegment(
                      value: 'system',
                      icon: Icon(Icons.phone_iphone_rounded),
                      label: Text('Hệ thống'),
                    ),
                    ButtonSegment(
                      value: 'light',
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Sáng'),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Tối'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(authControllerProvider.notifier)
                        .updateThemeMode(selection.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Thông báo',
                child: _SettingTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Cài đặt thông báo',
                  subtitle:
                      'Nhắc trước ${notificationSettings?.reminderMinutesBefore ?? 15} phút, quyền truy cập và âm báo.',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/notifications'),
                ),
              ),
              if (liveActivitySupported) ...[
                const SizedBox(height: 14),
                _SettingsSection(
                  title: 'Dynamic Island',
                  child: _SettingTile(
                    icon: Icons.dynamic_feed_rounded,
                    title: 'Hiển thị lịch học trên Dynamic Island',
                    subtitle: liveActivitySystemEnabled
                        ? 'Xem môn đang học, môn tiếp theo và thời gian còn lại ngay trên Dynamic Island.'
                        : 'Live Activities đang tắt trong iOS Settings. Bật lại trong Settings > App > Live Activities.',
                    trailing: Switch(
                      value: appSettings?.dynamicIslandEnabled ?? false,
                      onChanged: liveActivitySystemEnabled
                          ? (value) => ref
                                .read(liveActivityActionsProvider)
                                .setEnabled(value)
                          : null,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Widget iPhone',
                child: _SettingTile(
                  icon: Icons.widgets_rounded,
                  title: 'Preview và sync widget',
                  subtitle:
                      'Xem nhanh small, medium và large widget cho màn hình chính.',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/widget-preview'),
                ),
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Chia sẻ',
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.ios_share_rounded,
                      title: 'Chia sẻ thời khóa biểu',
                      subtitle: 'Tạo ảnh, QR và public link chỉ xem.',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/share'),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.link_rounded,
                      title: 'Các link đã chia sẻ',
                      subtitle: 'Bật, tắt hoặc xóa public link.',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/shared-links'),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Nhập lịch được chia sẻ',
                      subtitle: 'Nhập link hoặc mã chia sẻ.',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/shared'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Đồng bộ và sao lưu',
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.cloud_done_outlined,
                      title: 'Profile và backup',
                      subtitle: 'Tên, avatar, trạng thái sync và export JSON.',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/profile'),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.sync_rounded,
                      title: 'Sync widget ngay',
                      subtitle: 'Cập nhật dữ liệu local cho iOS widget.',
                      trailing: const Icon(Icons.refresh_rounded),
                      onTap: () =>
                          ref.read(widgetSyncActionsProvider).syncNow(),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Backend diagnostics',
                      subtitle:
                          'Kiểm tra kết nối API, phiên đăng nhập và trạng thái backend.',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/backend-diagnostics'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.tileSurface,
          border: Border.all(color: colorScheme.glassStrokeSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.22),
                    colorScheme.tertiary.withValues(alpha: 0.14),
                  ],
                ),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}
