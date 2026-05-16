import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'time_pill.dart';

class ShareScheduleCard extends StatelessWidget {
  const ShareScheduleCard({
    super.key,
    required this.schedule,
    this.compact = false,
  });

  final ScheduleModel schedule;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = schedule.displayColor;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: EdgeInsets.only(bottom: compact ? 10 : 14),
      radius: compact ? 24 : 30,
      padding: EdgeInsets.all(compact ? 14 : 16),
      borderColor: color.withValues(alpha: 0.24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 42 : 50,
            height: compact ? 42 : 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, AppColors.lavender, 0.30)!],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        schedule.subjectName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TimePill(
                      label:
                          '${formatMinutes(schedule.startTime)} - ${formatMinutes(schedule.endTime)}',
                      color: color,
                      icon: Icons.schedule_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: dayName(schedule.dayOfWeek),
                      tint: color,
                    ),
                    if (schedule.room.trim().isNotEmpty)
                      _InfoChip(
                        icon: Icons.location_on_rounded,
                        label: schedule.room.trim(),
                        tint: color,
                      ),
                    if (schedule.teacher.trim().isNotEmpty)
                      _InfoChip(
                        icon: Icons.person_rounded,
                        label: schedule.teacher.trim(),
                        tint: color,
                      ),
                  ],
                ),
                if (schedule.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    schedule.note.trim(),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.tileSurface,
        border: Border.all(color: colorScheme.glassStrokeSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.50,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
