import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/study_log_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/schedule_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(todaySchedulesProvider);
    final logs =
        ref.watch(todayStudyLogsProvider).valueOrNull ??
        const <StudyLogModel>[];
    final logBySchedule = {for (final log in logs) log.scheduleId: log};

    return AppNavigationShell(
      currentIndex: 2,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/schedule/new'),
        child: const Icon(Icons.add_rounded),
      ),
      child: SafeArea(
        child: schedules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Không tải được lịch hôm nay',
            message: error.toString(),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                title: 'Hôm nay trống lịch',
                message:
                    'Bạn có thể thêm môn học hoặc tận dụng ngày này để ôn tập.',
                action: FilledButton.icon(
                  onPressed: () => context.push('/schedule/new'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm lịch học'),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
              children: [
                Text(
                  'Lịch hôm nay',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Theo dõi tiến độ từng buổi và ghi chú nhanh sau lớp.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                for (final schedule in items)
                  ScheduleCard(
                    schedule: schedule,
                    log: logBySchedule[schedule.id],
                    onStart: () async {
                      await ref.read(scheduleActionsProvider).start(schedule);
                      if (context.mounted) {
                        _showMessage(
                          context,
                          'Đã bắt đầu học ${schedule.subjectName}',
                        );
                      }
                    },
                    onComplete: () async {
                      final note = await _noteDialog(context);
                      if (note == null) return;
                      await ref
                          .read(scheduleActionsProvider)
                          .complete(schedule, note);
                      if (context.mounted) {
                        _showMessage(context, 'Đã đánh dấu hoàn thành.');
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String?> _noteDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi chú sau buổi học'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Bạn đã học gì, cần ôn lại phần nào?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
