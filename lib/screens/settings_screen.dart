import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final themeMode = user?.themeMode ?? 'system';
    final auth = ref.watch(authControllerProvider).valueOrNull;

    return AppNavigationShell(
      currentIndex: 4,
      child: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            children: [
              const SectionHeader(
                title: 'Cài đặt',
                subtitle: 'Cá nhân hoá giao diện, thông báo và dữ liệu',
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: user?.avatarUrl == null
                        ? null
                        : NetworkImage(user!.avatarUrl!),
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.person_rounded)
                        : null,
                  ),
                  title: Text(user?.name ?? auth?.email ?? 'Tài khoản'),
                  subtitle: Text(
                    user?.email ?? auth?.email ?? 'Đã đồng bộ Firebase',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'Giao diện',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
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
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Thông báo',
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Bật thông báo',
                      subtitle: 'Nhắc trước 5, 10, 15 hoặc 30 phút',
                      trailing: Switch(
                        value: true,
                        onChanged: (_) =>
                            NotificationService.requestPermissions(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Dữ liệu',
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.cloud_done_outlined,
                      title: 'Sao lưu dữ liệu',
                      subtitle: 'Firestore tự đồng bộ và cache offline',
                      trailing: const Icon(Icons.check_circle_rounded),
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.palette_outlined,
                      title: 'Màu chủ đề',
                      subtitle: 'Bảng màu pastel dịu mắt',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Tài khoản',
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Quản lý tài khoản',
                      subtitle: auth?.email ?? 'Email / Google / Apple',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Đăng xuất'),
                    ),
                  ],
                ),
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
          color: colorScheme.surface.withValues(alpha: 0.42),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.12),
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
