import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/study_log_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/schedule_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(todaySchedulesProvider);
    final logs =
        ref.watch(todayStudyLogsProvider).valueOrNull ??
        const <StudyLogModel>[];
    final logBySchedule = {for (final log in logs) log.scheduleId: log};
    final user = ref.watch(appUserProvider).valueOrNull;

    return AppNavigationShell(
      currentIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/schedule/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm lịch'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  name: user?.name,
                  count: schedules.valueOrNull?.length ?? 0,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  hintText: 'Tìm môn học',
                  leading: const Icon(Icons.search_rounded),
                  onChanged: (value) =>
                      ref.read(searchQueryProvider.notifier).state = value,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
              sliver: schedules.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: EmptyState(
                    title: 'Không tải được lịch',
                    message: error.toString(),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        title: 'Hôm nay chưa có lịch học',
                        message:
                            'Tạo môn học đầu tiên để theo dõi giờ học, phòng học và nhắc nhở.',
                        action: FilledButton.icon(
                          onPressed: () => context.push('/schedule/new'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm môn học'),
                        ),
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => ScheduleCard(
                      schedule: items[index],
                      log: logBySchedule[items[index].id],
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.count});

  final String? name;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
            const Color(0xFF1FC8A9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name == null ? 'Thời khoá biểu của bạn' : 'Hi, $name',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Hôm nay bạn có $count tiết học',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}
