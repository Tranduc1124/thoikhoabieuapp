import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
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

class WeekScheduleScreen extends ConsumerWidget {
  const WeekScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSchedules = ref.watch(selectedDaySchedulesProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final query = ref.watch(searchQueryProvider);

    return SoftGradientBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: SectionHeader(
                title: 'Thời khóa biểu tuần',
                subtitle:
                    'Chọn từng ngày để xem lịch học buổi sáng, chiều và tối',
                trailing: IconButton.filledTonal(
                  onPressed: () =>
                      ref.read(selectedDayProvider.notifier).state =
                          DateTime.now().weekday,
                  icon: const Icon(Icons.today_rounded),
                  tooltip: 'Hôm nay',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBar(
                hintText: 'Tìm theo môn học',
                leading: const Icon(Icons.search_rounded),
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).state = value,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: ListView.separated(
                key: const PageStorageKey('week-days-scroll'),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  return _DayPill(
                    day: day,
                    selected: selectedDay == day,
                    onTap: () =>
                        ref.read(selectedDayProvider.notifier).state = day,
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: 7,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                reverseDuration: AppMotion.fast,
                switchInCurve: AppMotion.liquid,
                switchOutCurve: AppMotion.exit,
                transitionBuilder: _contentTransition,
                child: selectedSchedules.when(
                  loading: () => const Padding(
                    key: ValueKey('week-loading'),
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: LoadingSkeleton(itemCount: 4),
                  ),
                  error: (error, _) => EmptyState(
                    key: const ValueKey('week-error'),
                    title: 'Không tải được lịch tuần',
                    message: AppFeedbackService.messageFor(error),
                    action: FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(schedulesProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ),
                  data: (filtered) {
                    if (filtered.isEmpty) {
                      return EmptyState(
                        key: ValueKey('week-empty-$selectedDay-$query'),
                        title: 'Chưa có lịch cho ${dayName(selectedDay)}',
                        message: 'Thêm môn học hoặc đổi bộ lọc để tiếp tục.',
                        action: FilledButton.icon(
                          onPressed: () => context.push('/schedule/new'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm lịch học'),
                        ),
                      );
                    }
                    return CustomScrollView(
                      key: PageStorageKey('week-day-$selectedDay'),
                      cacheExtent: 900,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.md,
                            AppSpacing.xl,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _FilterHint(count: filtered.length),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.lg),
                        ),
                        ..._dayPartSlivers(
                          title: 'Buổi sáng',
                          onReorder: (oldIndex, newIndex, visibleItems) => ref
                              .read(scheduleReorderActionsProvider)
                              .reorderDay(
                                day: selectedDay,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                                visibleItems: visibleItems,
                              ),
                          schedules: filtered
                              .where((item) => item.startTime < 12 * 60)
                              .toList(),
                        ),
                        ..._dayPartSlivers(
                          title: 'Buổi chiều',
                          onReorder: (oldIndex, newIndex, visibleItems) => ref
                              .read(scheduleReorderActionsProvider)
                              .reorderDay(
                                day: selectedDay,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                                visibleItems: visibleItems,
                              ),
                          schedules: filtered
                              .where(
                                (item) =>
                                    item.startTime >= 12 * 60 &&
                                    item.startTime < 18 * 60,
                              )
                              .toList(),
                        ),
                        ..._dayPartSlivers(
                          title: 'Buổi tối',
                          onReorder: (oldIndex, newIndex, visibleItems) => ref
                              .read(scheduleReorderActionsProvider)
                              .reorderDay(
                                day: selectedDay,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                                visibleItems: visibleItems,
                              ),
                          schedules: filtered
                              .where((item) => item.startTime >= 18 * 60)
                              .toList(),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 112)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentTransition(Widget child, Animation<double> animation) {
    return MorphTransitionWidget(
      animation: animation,
      beginScale: 0.99,
      child: child,
    );
  }
}

List<Widget> _dayPartSlivers({
  required String title,
  required DayPartReorderCallback onReorder,
  required List<ScheduleModel> schedules,
}) {
  if (schedules.isEmpty) return const [];
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      sliver: SliverToBoxAdapter(child: SectionHeader(title: title)),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      sliver: SliverMorphingScheduleList(
        schedules: schedules,
        compact: true,
        onReorder: (oldIndex, newIndex) =>
            onReorder(oldIndex, newIndex, schedules),
      ),
    ),
  ];
}

typedef DayPartReorderCallback =
    void Function(int oldIndex, int newIndex, List<ScheduleModel> visibleItems);

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: selected ? 1 : 0.96,
      duration: AppMotion.fast,
      curve: AppMotion.liquid,
      child: ChoiceChip(
        selected: selected,
        label: Text(dayName(day)),
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primary.withValues(alpha: 0.18),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.28)
              : colorScheme.outline.withValues(alpha: 0.14),
        ),
        labelStyle: TextStyle(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilterHint extends StatelessWidget {
  const _FilterHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count môn học trong ngày đã chọn',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
