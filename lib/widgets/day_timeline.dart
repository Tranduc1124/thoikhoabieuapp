import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
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
    if (schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final schedule in schedules)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 58,
                  child: Column(
                    children: [
                      Text(
                        formatMinutes(schedule.startTime),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: schedule.displayColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ScheduleCard(schedule: schedule, compact: true),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
