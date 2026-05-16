import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../models/weather_now_model.dart';
import '../providers/auth_provider.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/morphing_schedule_list.dart';
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
    final friendRequestCount =
        ref.watch(incomingFriendRequestsProvider).valueOrNull?.length ?? 0;

    return SoftGradientBackground(
      child: SafeArea(
        child: CustomScrollView(
          key: const PageStorageKey('home-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  name: user?.displayName,
                  schedules: schedules.valueOrNull ?? const [],
                  weather: weather,
                  friendRequestCount: friendRequestCount,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              sliver: SliverToBoxAdapter(
                child: _HomePrimaryActions(
                  friendRequestCount: friendRequestCount,
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
                  return SliverMorphingScheduleList(
                    schedules: items,
                    logForSchedule: (schedule) => logBySchedule[schedule.id],
                    onDelete: (schedule) =>
                        ref.read(scheduleActionsProvider).delete(schedule.id),
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

class _HomePrimaryActions extends StatelessWidget {
  const _HomePrimaryActions({required this.friendRequestCount});

  final int friendRequestCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeActionButton(
            icon: Icons.people_alt_rounded,
            label: friendRequestCount > 0
                ? '$friendRequestCount lời mời'
                : 'Bạn bè',
            onTap: () => context.push('/friends'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _HomeActionButton(
            icon: Icons.ios_share_rounded,
            label: 'Chia sẻ lịch',
            onTap: () => context.push('/share'),
          ),
        ),
      ],
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
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
    return AnimatedButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: colorScheme.tileSurface,
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.schedules,
    required this.weather,
    required this.friendRequestCount,
  });

  final String? name;
  final List<ScheduleModel> schedules;
  final WeatherNowModel? weather;
  final int friendRequestCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalHours = schedules.fold<double>(
      0,
      (sum, item) => sum + item.duration.inMinutes / 60,
    );
    final next = _nextSchedule(schedules);
    final nextAlert = _nextAlert(next);

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
          AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.liquid,
            switchOutCurve: AppMotion.exit,
            child: nextAlert == null && friendRequestCount == 0
                ? const SizedBox.shrink(key: ValueKey('home-alert-empty'))
                : Padding(
                    key: ValueKey('home-alert-$nextAlert-$friendRequestCount'),
                    padding: const EdgeInsets.only(top: 12),
                    child: _InlineAlert(
                      icon: friendRequestCount > 0
                          ? Icons.person_add_alt_1_rounded
                          : Icons.notifications_active_rounded,
                      message: friendRequestCount > 0
                          ? '$friendRequestCount lời mời kết bạn đang chờ.'
                          : nextAlert!,
                      color: friendRequestCount > 0
                          ? AppColors.lavender
                          : AppColors.warning,
                    ),
                  ),
          ),
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

  String? _nextAlert(ScheduleModel? schedule) {
    if (schedule == null) return null;
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final remaining = schedule.startTime - minutes;
    if (remaining < 0 || remaining > 20) return null;
    if (remaining == 0) return '${schedule.subjectName} đang bắt đầu.';
    return '${schedule.subjectName} bắt đầu sau $remaining phút.';
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: colorScheme.isDark ? 0.18 : 0.14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
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
