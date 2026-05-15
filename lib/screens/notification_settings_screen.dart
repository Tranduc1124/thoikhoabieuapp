import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_settings_model.dart';
import '../providers/pro_feature_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final _customController = TextEditingController();
  int? _customMinutes;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: settings.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingSkeleton(itemCount: 3),
            ),
            error: (error, _) => EmptyState(
              title: 'Không tải được cài đặt',
              message: error.toString(),
              action: FilledButton.tonalIcon(
                onPressed: () => ref.invalidate(notificationSettingsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
            data: (value) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const SectionHeader(
                  title: 'Nhắc lịch học',
                  subtitle: 'Tự cập nhật khi thêm, sửa hoặc xóa lịch học.',
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      _SwitchRow(
                        title: 'Bật thông báo toàn app',
                        subtitle: _permissionText(value.permissionStatus),
                        icon: Icons.notifications_active_outlined,
                        value: value.enabled,
                        onChanged: (enabled) => _save(
                          value.copyWith(enabled: enabled),
                          requestPermission: enabled,
                        ),
                      ),
                      const Divider(height: 18),
                      _SwitchRow(
                        title: 'Nhắc trước môn học tiếp theo',
                        subtitle: 'Gửi thông báo trước giờ học đã chọn.',
                        icon: Icons.school_rounded,
                        value: value.nextClassReminderEnabled,
                        onChanged: (enabled) => _save(
                          value.copyWith(nextClassReminderEnabled: enabled),
                        ),
                      ),
                      const Divider(height: 18),
                      _SwitchRow(
                        title: 'Âm báo',
                        subtitle: 'Phát âm thanh khi nhắc lịch học.',
                        icon: Icons.volume_up_rounded,
                        value: value.soundEnabled,
                        onChanged: (enabled) =>
                            _save(value.copyWith(soundEnabled: enabled)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian nhắc trước',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final minute in const [5, 10, 15, 30, 60])
                            ChoiceChip(
                              selected: value.reminderMinutesBefore == minute,
                              label: Text(_reminderLabel(minute)),
                              onSelected: (_) => _save(
                                value.copyWith(reminderMinutesBefore: minute),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Tùy chỉnh phút',
                          suffixIcon: IconButton(
                            onPressed: () {
                              final parsed = int.tryParse(
                                _customController.text,
                              );
                              if (parsed == null || parsed <= 0) return;
                              setState(() => _customMinutes = parsed);
                              _save(
                                value.copyWith(reminderMinutesBefore: parsed),
                              );
                            },
                            icon: const Icon(Icons.check_rounded),
                          ),
                        ),
                      ),
                      if (_customMinutes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Đang dùng tùy chỉnh: ${_reminderLabel(_customMinutes!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug thông báo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(notificationSettingsActionsProvider)
                                    .sendTestNotification();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đã hẹn thông báo test sau 10 giây.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.bolt_rounded),
                              label: const Text('Test 10 giây'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(notificationSettingsActionsProvider)
                                    .rescheduleAll();
                                final count = await ref
                                    .read(notificationSettingsActionsProvider)
                                    .logPendingNotifications();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã lên lịch lại. Pending: $count',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Lên lịch lại'),
                            ),
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
                      _SwitchRow(
                        title: 'Nhắc bài tập/deadline',
                        subtitle: 'Đã sẵn sàng để nối vào màn bài tập.',
                        icon: Icons.assignment_rounded,
                        value: value.homeworkReminderEnabled,
                        onChanged: (enabled) => _save(
                          value.copyWith(homeworkReminderEnabled: enabled),
                        ),
                      ),
                      const Divider(height: 18),
                      _SwitchRow(
                        title: 'Nhắc ôn thi',
                        subtitle: 'Đã sẵn sàng để nối vào lịch ôn thi.',
                        icon: Icons.event_available_rounded,
                        value: value.examReminderEnabled,
                        onChanged: (enabled) =>
                            _save(value.copyWith(examReminderEnabled: enabled)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(
    NotificationSettingsModel settings, {
    bool requestPermission = false,
  }) async {
    final actions = ref.read(notificationSettingsActionsProvider);
    if (requestPermission) {
      await actions.requestPermissionAndSave(settings);
    } else {
      await actions.save(settings);
    }
  }

  String _reminderLabel(int minute) {
    return minute == 60 ? '1 giờ' : '$minute phút';
  }

  String _permissionText(String status) {
    return switch (status) {
      'granted' => 'Đã bật thông báo',
      'denied' => 'Chưa cấp quyền. Vào iOS Settings để bật lại.',
      _ => 'Sẽ hỏi quyền khi bạn bật thông báo.',
    };
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
