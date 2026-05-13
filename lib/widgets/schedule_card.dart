import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    this.log,
    this.compact = false,
    this.onStart,
    this.onComplete,
  });

  final ScheduleModel schedule;
  final StudyLogModel? log;
  final bool compact;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final color = schedule.displayColor;
    final status = _status();
    final statusLabel = switch (status) {
      _ClassStatus.upcoming => 'Sap hoc',
      _ClassStatus.active => 'Dang hoc',
      _ClassStatus.done => 'Da hoc xong',
    };
    final statusIcon = switch (status) {
      _ClassStatus.upcoming => Icons.schedule_rounded,
      _ClassStatus.active => Icons.play_circle_rounded,
      _ClassStatus.done => Icons.check_circle_rounded,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: compact ? 10 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            Color.lerp(color, Colors.black, 0.18)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () =>
              context.push('/schedule/${schedule.id}', extra: schedule),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Container(
                        key: ValueKey(statusLabel),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.17),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.access_time_rounded,
                      label:
                          '${formatMinutes(schedule.startTime)} - ${formatMinutes(schedule.endTime)}',
                    ),
                    if (schedule.room.isNotEmpty)
                      _MetaChip(
                        icon: Icons.location_on_rounded,
                        label: schedule.room,
                      ),
                    if (schedule.teacher.isNotEmpty)
                      _MetaChip(
                        icon: Icons.person_rounded,
                        label: schedule.teacher,
                      ),
                  ],
                ),
                if (schedule.note.isNotEmpty && !compact) ...[
                  const SizedBox(height: 12),
                  Text(
                    schedule.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.35,
                    ),
                  ),
                ],
                if (onStart != null || onComplete != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (onStart != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onStart,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Bat dau hoc'),
                            style: _actionStyle(),
                          ),
                        ),
                      if (onStart != null && onComplete != null)
                        const SizedBox(width: 10),
                      if (onComplete != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onComplete,
                            icon: const Icon(Icons.done_rounded),
                            label: const Text('Da hoc'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _actionStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
    );
  }

  _ClassStatus _status() {
    if (log?.status == StudyStatus.completed) return _ClassStatus.done;
    if (log?.status == StudyStatus.started) return _ClassStatus.active;
    final now = DateTime.now();
    if (now.weekday != schedule.dayOfWeek) return _ClassStatus.upcoming;
    final minutes = now.hour * 60 + now.minute;
    if (minutes >= schedule.endTime) return _ClassStatus.done;
    if (minutes >= schedule.startTime) return _ClassStatus.active;
    return _ClassStatus.upcoming;
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ClassStatus { upcoming, active, done }
