import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';
import '../widgets/syncing_state_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyStatsProvider);
    final scheduleCount = ref.watch(schedulesProvider).valueOrNull?.length ?? 0;

    return SoftGradientBackground(
      child: SafeArea(
        child: stats.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: SyncingStateCard(
              title: 'Đang tính thống kê',
              message: 'Dữ liệu lịch đã lưu sẽ giúp giảm nháy khi làm mới.',
            ),
          ),
          error: (error, _) => EmptyState(
            title: 'Không tải được thống kê',
            message: AppFeedbackService.messageFor(error),
            action: FilledButton.tonalIcon(
              onPressed: () {
                ref.invalidate(schedulesProvider);
                ref.invalidate(weekStudyLogsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
          data: (value) {
            final entries = value.hoursBySubject.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            if (entries.isEmpty) {
              return const EmptyState(
                title: 'Chưa có dữ liệu thống kê',
                message:
                    'Thêm thời khóa biểu để xem tổng số giờ học và những môn học nổi bật trong tuần.',
              );
            }
            final completion = scheduleCount == 0
                ? 0.0
                : (value.completedCount / scheduleCount).clamp(0.0, 1.0);
            return ListView(
              key: const PageStorageKey('statistics-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
              children: [
                const SectionHeader(
                  title: 'Thống kê tuần',
                  subtitle: 'Tổng quan thời lượng và tiến độ học tập của bạn',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Tổng giờ',
                        value: value.totalHours.toStringAsFixed(1),
                        icon: Icons.timer_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Hoàn thành',
                        value: '${(completion * 100).round()}%',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10A987),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProgressSummaryCard(
                  completion: completion,
                  completedCount: value.completedCount,
                  totalCount: scheduleCount,
                  topSubject: value.topSubject,
                ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tuần này bạn dành nhiều thời gian nhất cho môn ${value.topSubject}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bạn đã hoàn thành ${(completion * 100).round()}% lịch học trong tuần này.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 250,
                        child: BarChart(_chartData(context, entries)),
                      ),
                      const SizedBox(height: 18),
                      _SubjectBreakdown(entries: entries),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  BarChartData _chartData(
    BuildContext context,
    List<MapEntry<String, double>> entries,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = [
      colorScheme.primary,
      const Color(0xFF87DCC0),
      const Color(0xFFFFB59D),
      const Color(0xFFC9B6FF),
      const Color(0xFF9AD7FF),
    ];
    return BarChartData(
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: colorScheme.glassStrokeSubtle, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (index, _) {
              final i = index.toInt();
              if (i < 0 || i >= entries.length) return const SizedBox.shrink();
              final text = entries[i].key;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  text.length > 7 ? '${text.substring(0, 7)}.' : text,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(enabled: true),
      barGroups: [
        for (var i = 0; i < entries.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                width: 24,
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    palette[i % palette.length].withValues(alpha: 0.64),
                    palette[i % palette.length],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.completion,
    required this.completedCount,
    required this.totalCount,
    required this.topSubject,
  });

  final double completion;
  final int completedCount;
  final int totalCount;
  final String topSubject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: completion,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colorScheme.tileSurface,
                ),
                Text(
                  '${(completion * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tien do tuan nay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedCount/$totalCount buoi hoc da hoan thanh. Mon noi bat: $topSubject.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectBreakdown extends StatelessWidget {
  const _SubjectBreakdown({required this.entries});

  final List<MapEntry<String, double>> entries;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = entries.fold<double>(0, (sum, item) => sum + item.value);
    return Column(
      children: [
        for (final entry in entries.take(6)) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${entry.value.toStringAsFixed(1)}h',
                style: TextStyle(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total <= 0 ? 0 : entry.value / total,
              minHeight: 8,
              backgroundColor: colorScheme.tileSurface,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
