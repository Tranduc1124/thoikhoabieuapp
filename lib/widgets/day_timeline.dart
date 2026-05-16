import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../theme/app_motion.dart';
import 'morphing_schedule_list.dart';
import 'schedule_card.dart';

class DayTimeline extends StatelessWidget {
  const DayTimeline({
    super.key,
    required this.schedules,
    this.showDayHeader = false,
  });

  final List<ScheduleModel> schedules;
  final bool showDayHeader;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();

    final sorted = [...schedules]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.liquid,
      switchOutCurve: AppMotion.exit,
      child: Column(
        key: ValueKey(sorted.map((item) => item.id).join('-')),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sorted.length; i++)
            _TimelineRow(
              schedule: sorted[i],
              index: i,
              isLast: i == sorted.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.schedule,
    required this.index,
    required this.isLast,
  });

  final ScheduleModel schedule;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isCurrent = _isCurrent(schedule);
    final color = schedule.displayColor;
    return RepaintBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.liquid,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isCurrent
                        ? color.withValues(alpha: 0.16)
                        : Colors.transparent,
                  ),
                  child: Text(
                    formatMinutes(schedule.startTime),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isCurrent
                          ? color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: AppMotion.liquid,
                      width: 2,
                      height: 104,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.38),
                            color.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (isCurrent)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: color.withValues(alpha: 0.20),
                          ),
                        ),
                      ),
                    ),
                  ),
                MorphingScheduleCard(
                  key: ValueKey('timeline-morph-schedule-${schedule.id}'),
                  scheduleId: schedule.id,
                  index: index,
                  child: ScheduleCard(
                    key: ValueKey('timeline-schedule-card-${schedule.id}'),
                    schedule: schedule,
                    compact: true,
                    index: index,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrent(ScheduleModel schedule) {
    final now = DateTime.now();
    if (now.weekday != schedule.dayOfWeek) return false;
    final minutes = now.hour * 60 + now.minute;
    return minutes >= schedule.startTime && minutes <= schedule.endTime;
  }
}
