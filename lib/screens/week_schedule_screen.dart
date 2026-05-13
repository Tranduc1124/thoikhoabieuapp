import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/day_timeline.dart';
import '../widgets/empty_state.dart';

class WeekScheduleScreen extends ConsumerWidget {
  const WeekScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final query = ref.watch(searchQueryProvider);

    return AppNavigationShell(
      currentIndex: 1,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/schedule/new'),
        child: const Icon(Icons.add_rounded),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thời khoá biểu tuần',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () =>
                        ref.read(selectedDayProvider.notifier).state =
                            DateTime.now().weekday,
                    icon: const Icon(Icons.today_rounded),
                    tooltip: 'Hôm nay',
                  ),
                ],
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
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  return ChoiceChip(
                    selected: selectedDay == day,
                    label: Text(dayName(day)),
                    onSelected: (_) =>
                        ref.read(selectedDayProvider.notifier).state = day,
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: 7,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: schedules.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => EmptyState(
                  title: 'Không tải được lịch tuần',
                  message: error.toString(),
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
                      message: 'Thêm môn học hoặc đổi bộ lọc để xem timeline.',
                      action: FilledButton.icon(
                        onPressed: () => context.push('/schedule/new'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm lịch'),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    children: [
                      _FilterHint(count: filtered.length),
                      const SizedBox(height: 14),
                      DayTimeline(schedules: filtered),
                    ],
                  );
                },
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count môn học trong ngày đã chọn. Kéo thả có thể bổ sung sau bằng calendar package chuyên dụng.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
