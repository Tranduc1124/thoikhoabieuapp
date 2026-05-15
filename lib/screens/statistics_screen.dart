import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/schedule_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyStatsProvider);
    final scheduleCount = ref.watch(schedulesProvider).valueOrNull?.length ?? 0;

    return AppNavigationShell(
      currentIndex: 3,
      child: SoftGradientBackground(
        child: SafeArea(
          child: stats.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingSkeleton(itemCount: 3),
            ),
            error: (error, _) => EmptyState(
              title: 'Không tải được thống kê',
              message: error.toString(),
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
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 720),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return SizedBox(
                              height: 250,
                              child: BarChart(
                                _chartData(context, entries, value),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  BarChartData _chartData(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    double progress,
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
                toY: entries[i].value * progress,
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
