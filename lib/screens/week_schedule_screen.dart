import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/day_timeline.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_floating_button.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class WeekScheduleScreen extends ConsumerWidget {
  const WeekScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final query = ref.watch(searchQueryProvider);

    return AppNavigationShell(
      currentIndex: 1,
      floatingActionButton: GlassFloatingButton(
        onPressed: () => context.push('/schedule/new'),
        icon: Icons.add_rounded,
      ),
      child: SoftGradientBackground(
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: 7,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: schedules.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: LoadingSkeleton(itemCount: 4),
                  ),
                  error: (error, _) => EmptyState(
                    title: 'Không tải được lịch tuần',
                    message: error.toString(),
                    action: FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(schedulesProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ),
                  data: (items) {
                    final filtered =
                        items
                            .where((item) => item.dayOfWeek == selectedDay)
                            .where(
                              (item) => query.trim().isEmpty
                                  ? true
                                  : item.subjectName.toLowerCase().contains(
                                      query.trim().toLowerCase(),
                                    ),
                            )
                            .toList()
                          ..sort((a, b) => a.startTime.compareTo(b.startTime));
                    if (filtered.isEmpty) {
                      return EmptyState(
                        title: 'Chưa có lịch cho ${dayName(selectedDay)}',
                        message: 'Thêm môn học hoặc đổi bộ lọc để tiếp tục.',
                        action: FilledButton.icon(
                          onPressed: () => context.push('/schedule/new'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm lịch học'),
                        ),
                      );
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: ListView(
                        key: ValueKey('$selectedDay-${filtered.length}'),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
                        children: [
                          _FilterHint(count: filtered.length),
                          const SizedBox(height: 18),
                          _DayPartSection(
                            title: 'Buổi sáng',
                            schedules: filtered
                                .where((item) => item.startTime < 12 * 60)
                                .toList(),
                          ),
                          _DayPartSection(
                            title: 'Buổi chiều',
                            schedules: filtered
                                .where(
                                  (item) =>
                                      item.startTime >= 12 * 60 &&
                                      item.startTime < 18 * 60,
                                )
                                .toList(),
                          ),
                          _DayPartSection(
                            title: 'Buổi tối',
                            schedules: filtered
                                .where((item) => item.startTime >= 18 * 60)
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      duration: const Duration(milliseconds: 180),
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
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
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

class _DayPartSection extends StatelessWidget {
  const _DayPartSection({required this.title, required this.schedules});

  final String title;
  final List<ScheduleModel> schedules;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: 12),
          DayTimeline(schedules: schedules),
        ],
      ),
    );
  }
}
