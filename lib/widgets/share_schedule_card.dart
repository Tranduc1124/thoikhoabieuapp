import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
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
    final color = schedule.displayColor;
    return GlassCard(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      radius: compact ? 18 : 22,
      padding: EdgeInsets.all(compact ? 12 : 14),
      borderColor: color.withValues(alpha: 0.20),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 42,
            height: compact ? 34 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.auto_stories_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TimePill(
                      label:
                          '${formatMinutes(schedule.startTime)} - ${formatMinutes(schedule.endTime)}',
                      color: color,
                    ),
                    if (schedule.room.isNotEmpty)
                      TimePill(
                        label: schedule.room,
                        color: color,
                        icon: Icons.location_on_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
