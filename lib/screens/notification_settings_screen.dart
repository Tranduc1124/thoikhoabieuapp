import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_settings_model.dart';
import '../providers/pro_feature_providers.dart';
import '../services/app_feedback_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';
import '../widgets/syncing_state_card.dart';

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
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: SyncingStateCard(
                title: 'Đang mở cài đặt thông báo',
                message: 'Nhắc lịch và quyền thông báo đang được kiểm tra.',
              ),
            ),
            error: (error, _) => EmptyState(
              title: 'Không tải được cài đặt',
              message: AppFeedbackService.messageFor(error),
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
                  title: 'Đừng bỏ lỡ tiết học quan trọng',
                  subtitle:
                      'Tự động cập nhật nhắc nhở khi bạn thêm, sửa hoặc xoá lịch học.',
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      _SwitchRow(
                        title: 'Bật thông báo',
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
                        subtitle: 'Gửi lời nhắc trước giờ học bạn đã chọn.',
                        icon: Icons.school_rounded,
                        value: value.nextClassReminderEnabled,
                        onChanged: (enabled) => _save(
                          value.copyWith(nextClassReminderEnabled: enabled),
                        ),
                      ),
                      const Divider(height: 18),
                      _SwitchRow(
                        title: 'Âm báo',
                        subtitle: 'Phát âm thanh khi có lời nhắc mới.',
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
                          labelText: 'Tùy chỉnh số phút',
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
                          'Đang dùng: ${_reminderLabel(_customMinutes!)}',
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
                        'Kiểm tra nhanh',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _NotificationActionButton(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(notificationSettingsActionsProvider)
                                    .sendTestNotification();
                                if (!context.mounted) return;
                                AppFeedbackService.success(
                                  context,
                                  'Đã tạo thông báo thử trong giây lát.',
                                );
                              },
                              icon: const Icon(Icons.bolt_rounded),
                              label: const Text('Thử ngay'),
                            ),
                          ),
                          _NotificationActionButton(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(notificationSettingsActionsProvider)
                                    .rescheduleAll();
                                if (!context.mounted) return;
                                AppFeedbackService.success(
                                  context,
                                  'Đã cập nhật lại lời nhắc.',
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Làm mới nhắc nhở'),
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
                        title: 'Nhắc bài tập',
                        subtitle:
                            'Luôn sẵn sàng cho những việc cần hoàn thành.',
                        icon: Icons.assignment_rounded,
                        value: value.homeworkReminderEnabled,
                        onChanged: (enabled) => _save(
                          value.copyWith(homeworkReminderEnabled: enabled),
                        ),
                      ),
                      const Divider(height: 18),
                      _SwitchRow(
                        title: 'Nhắc ôn thi',
                        subtitle:
                            'Giữ nhịp học đều đặn trước các kỳ thi quan trọng.',
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
      'granted' => 'Thông báo đang được bật.',
      'denied' =>
        'Bạn chưa cho phép thông báo. Hãy bật lại trong cài đặt thiết bị.',
      _ => 'Ứng dụng sẽ xin quyền khi bạn bật thông báo.',
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

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = width - 40 - 36;
    final itemWidth = contentWidth >= 390
        ? (contentWidth - 10) / 2
        : contentWidth;
    return SizedBox(width: itemWidth, child: child);
  }
}
