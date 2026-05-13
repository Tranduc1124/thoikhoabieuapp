import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/schedule_provider.dart';
import '../widgets/app_navigation_shell.dart';
import '../widgets/empty_state.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyStatsProvider);

    return AppNavigationShell(
      currentIndex: 3,
      child: SafeArea(
        child: stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Không tải được thống kê',
            message: error.toString(),
          ),
          data: (value) {
            final entries = value.hoursBySubject.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            if (entries.isEmpty) {
              return const EmptyState(
                title: 'Chưa có dữ liệu thống kê',
                message:
                    'Thêm thời khoá biểu để xem tổng số giờ học và môn học nổi bật.',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
              children: [
                Text(
                  'Thống kê tuần',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Tổng giờ',
                        value: value.totalHours.toStringAsFixed(1),
                        icon: Icons.timer_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Đã hoàn thành',
                        value: '${value.completedCount}',
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bạn học ${value.topSubject} nhiều nhất tuần này',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 240,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (index, _) {
                                      final i = index.toInt();
                                      if (i < 0 || i >= entries.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final text = entries[i].key;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          text.length > 6
                                              ? '${text.substring(0, 6)}.'
                                              : text,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                for (var i = 0; i < entries.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entries[i].value,
                                        width: 22,
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
