import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../models/weather_now_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_floating_button.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/schedule_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

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
    final weather = ref.watch(homeWeatherProvider).valueOrNull;

    return AppNavigationShell(
      currentIndex: 0,
      floatingActionButton: GlassFloatingButton(
        onPressed: () => context.push('/schedule/new'),
        icon: Icons.add_rounded,
        label: 'Thêm lịch',
      ),
      child: SoftGradientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    name: user?.displayName,
                    schedules: schedules.valueOrNull ?? const [],
                    weather: weather,
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
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Hôm nay',
                    subtitle: 'Lịch học, trạng thái và các lớp sắp tới',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                sliver: schedules.when(
                  loading: () => const SliverToBoxAdapter(
                    child: LoadingSkeleton(itemCount: 3),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    child: EmptyState(
                      title: 'Không tải được lịch',
                      message: 'Vui lòng thử lại sau ít phút.',
                      action: FilledButton.tonalIcon(
                        onPressed: () => ref.invalidate(schedulesProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          title: 'Hôm nay chưa có lịch học',
                          message:
                              'Thêm môn học đầu tiên để theo dõi giờ học, phòng học và lời nhắc thật gọn gàng.',
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
                        index: index,
                        onDelete: () => ref
                            .read(scheduleActionsProvider)
                            .delete(items[index].id),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.schedules,
    required this.weather,
  });

  final String? name;
  final List<ScheduleModel> schedules;
  final WeatherNowModel? weather;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalHours = schedules.fold<double>(
      0,
      (sum, item) => sum + item.duration.inMinutes / 60,
    );
    final next = _nextSchedule(schedules);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainer.withValues(alpha: 0.92),
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.86),
            colorScheme.primary.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: colorScheme.glassStroke),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name == null ? 'Thời khóa biểu của bạn' : 'Hi, $name',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Hero(
                tag: 'profile-avatar-home',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WeatherBadge(weather: weather, scheduleCount: schedules.length),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  label: 'Môn hôm nay',
                  value: '${schedules.length}',
                  icon: Icons.auto_stories_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStat(
                  label: 'Tổng giờ',
                  value: totalHours.toStringAsFixed(1),
                  icon: Icons.timer_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStat(
                  label: 'Tiếp theo',
                  value: next == null ? '--' : formatMinutes(next.startTime),
                  icon: Icons.near_me_rounded,
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 14),
            Text(
              'Môn tiếp theo: ${next.subjectName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ScheduleModel? _nextSchedule(List<ScheduleModel> schedules) {
    if (schedules.isEmpty) return null;
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final upcoming = schedules.where((item) => item.endTime >= minutes).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (upcoming.isNotEmpty) return upcoming.first;
    final sorted = [...schedules]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted.first;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _WeatherBadge extends StatelessWidget {
  const _WeatherBadge({required this.weather, required this.scheduleCount});

  final WeatherNowModel? weather;
  final int scheduleCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = weather?.summary ?? 'Thời tiết chưa sẵn sàng';
    final support = weather?.supportMessage(scheduleCount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colorScheme.tileSurface,
        border: Border.all(color: colorScheme.glassStrokeSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconForWeather(weather?.weatherCode),
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (support != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    support,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForWeather(int? code) {
    if (code == null) return Icons.wb_cloudy_rounded;
    if ({51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82}.contains(code)) {
      return Icons.grain_rounded;
    }
    if ({95, 96, 99}.contains(code)) {
      return Icons.thunderstorm_rounded;
    }
    if ({45, 48}.contains(code)) {
      return Icons.blur_on_rounded;
    }
    if (code == 0) return Icons.wb_sunny_rounded;
    return Icons.cloud_queue_rounded;
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colorScheme.tileSurface,
        border: Border.all(color: colorScheme.glassStrokeSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
