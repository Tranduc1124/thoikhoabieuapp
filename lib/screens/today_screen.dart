import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/morphing_schedule_list.dart';
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

    return SoftGradientBackground(
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.medium,
          reverseDuration: AppMotion.fast,
          switchInCurve: AppMotion.liquid,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: _pageTransition,
          child: schedules.when(
            loading: () => const Padding(
              key: ValueKey('today-loading'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                0,
              ),
              child: LoadingSkeleton(itemCount: 4),
            ),
            error: (error, _) => EmptyState(
              key: const ValueKey('today-error'),
              title: 'Không tải được lịch hôm nay',
              message: AppFeedbackService.messageFor(error),
              action: FilledButton.tonalIcon(
                onPressed: () => ref.invalidate(schedulesProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  key: const ValueKey('today-empty'),
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
              return MorphingScheduleList(
                storageKey: const PageStorageKey('today-scroll'),
                schedules: items,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  112,
                ),
                headerSlivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: SectionHeader(
                          title: 'Lịch hôm nay',
                          subtitle:
                              'Theo dõi tiến độ từng buổi học và ghi chú nhanh sau giờ lên lớp',
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _TodaySummary(items: items),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    sliver: SliverToBoxAdapter(child: _TodayQuickActions()),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
                logForSchedule: (schedule) => logBySchedule[schedule.id],
                onDelete: (schedule) =>
                    ref.read(scheduleActionsProvider).delete(schedule.id),
                onReorder: (oldIndex, newIndex) => ref
                    .read(scheduleReorderActionsProvider)
                    .reorderDay(
                      day: DateTime.now().weekday,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                      visibleItems: items,
                    ),
                onStart: (schedule) async {
                  await ref.read(scheduleActionsProvider).start(schedule);
                  if (context.mounted) {
                    _showMessage(context, 'Đã bắt đầu ${schedule.subjectName}');
                  }
                },
                onComplete: (schedule) async {
                  final note = await _noteDialog(context);
                  if (note == null) return;
                  await ref
                      .read(scheduleActionsProvider)
                      .complete(schedule, note);
                  if (context.mounted) {
                    _showMessage(context, 'Đã đánh dấu hoàn thành.');
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pageTransition(Widget child, Animation<double> animation) {
    return MorphTransitionWidget(
      animation: animation,
      beginScale: 0.99,
      beginOpacity: 0.72,
      child: child,
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

class _TodayQuickActions extends StatelessWidget {
  const _TodayQuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.people_alt_rounded,
            label: 'Bạn bè',
            onTap: () => context.push('/friends'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.ios_share_rounded,
            label: 'Chia sẻ',
            onTap: () => context.push('/share'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: AnimatedButton(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(
                  alpha: context.isDark ? 0.22 : 0.14,
                ),
                colorScheme.tertiary.withValues(
                  alpha: context.isDark ? 0.18 : 0.12,
                ),
              ],
            ),
            border: Border.all(color: colorScheme.glassStrokeSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.items});

  final List<ScheduleModel> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalMinutes = items.fold<int>(
      0,
      (total, item) => total + item.duration.inMinutes,
    );
    final next = _nextSchedule(items);
    return Semantics(
      label: 'Tóm tắt lịch hôm nay',
      child: GlassCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useWrap = constraints.maxWidth < 340;
            final tiles = [
              _SummaryTile(
                icon: Icons.auto_stories_rounded,
                label: 'Môn',
                value: '${items.length}',
                color: colorScheme.primary,
              ),
              _SummaryTile(
                icon: Icons.timer_rounded,
                label: 'Giờ học',
                value: (totalMinutes / 60).toStringAsFixed(1),
                color: AppColors.mint,
              ),
              _SummaryTile(
                icon: Icons.near_me_rounded,
                label: 'Tiếp theo',
                value: next == null ? '--' : formatMinutes(next.startTime),
                color: AppColors.peach,
              ),
            ];
            if (useWrap) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  tiles[2],
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < tiles.length; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: tiles[index]),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  ScheduleModel? _nextSchedule(List<ScheduleModel> schedules) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final upcoming = schedules.where((item) => item.endTime >= minutes).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (upcoming.isNotEmpty) return upcoming.first;
    final sorted = [...schedules]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted.isEmpty ? null : sorted.first;
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value',
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.liquid,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: colorScheme.tileSurface,
          border: Border.all(color: colorScheme.glassStrokeSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
