import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/study_log_model.dart';
import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_floating_button.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/schedule_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

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
      floatingActionButton: GlassFloatingButton(
        onPressed: () => context.push('/schedule/new'),
        icon: Icons.add_rounded,
      ),
      child: SoftGradientBackground(
        child: SafeArea(
          child: schedules.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingSkeleton(itemCount: 4),
            ),
            error: (error, _) => EmptyState(
              title: 'Không tải được lịch hôm nay',
              message: error.toString(),
              action: FilledButton.tonalIcon(
                onPressed: () => ref.invalidate(schedulesProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  title: 'Chưa có lịch học nào hôm nay',
                  message:
                      'Thêm môn học đầu tiên để bắt đầu hoặc dành ngày này cho việc ôn tập.',
                  action: FilledButton.icon(
                    onPressed: () => context.push('/schedule/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm lịch học'),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                children: [
                  const SectionHeader(
                    title: 'Lịch hôm nay',
                    subtitle:
                        'Theo dõi tiến độ từng buổi học và ghi chú nhanh sau giờ lên lớp',
                  ),
                  const SizedBox(height: 18),
                  for (var index = 0; index < items.length; index++)
                    ScheduleCard(
                      schedule: items[index],
                      log: logBySchedule[items[index].id],
                      index: index,
                      onDelete: () => ref
                          .read(scheduleActionsProvider)
                          .delete(items[index].id),
                      onStart: () async {
                        await ref
                            .read(scheduleActionsProvider)
                            .start(items[index]);
                        if (context.mounted) {
                          _showMessage(
                            context,
                            'Đã bắt đầu ${items[index].subjectName}',
                          );
                        }
                      },
                      onComplete: () async {
                        final note = await _noteDialog(context);
                        if (note == null) return;
                        await ref
                            .read(scheduleActionsProvider)
                            .complete(items[index], note);
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
    AppFeedbackService.success(context, message);
  }
}
