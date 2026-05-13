import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../widgets/app_navigation_shell.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final themeMode = user?.themeMode ?? 'system';
    final auth = ref.watch(authControllerProvider).valueOrNull;

    return AppNavigationShell(
      currentIndex: 4,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            Text(
              'Cài đặt',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: CircleAvatar(
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
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giao diện',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: true,
                    onChanged: (_) => NotificationService.requestPermissions(),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Bật thông báo'),
                    subtitle: const Text('Nhắc trước 5, 10, 15 hoặc 30 phút'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Màu chủ đề'),
                    subtitle: const Text(
                      'Đang dùng bảng màu xanh iOS hiện đại',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: const Text('Sao lưu dữ liệu'),
                    subtitle: const Text(
                      'Firestore tự đồng bộ và cache offline',
                    ),
                    trailing: const Icon(Icons.check_circle_rounded),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Quản lý tài khoản'),
                    subtitle: Text(auth?.email ?? 'Email / Google / Apple'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
