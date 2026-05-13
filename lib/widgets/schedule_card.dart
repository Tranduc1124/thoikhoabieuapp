import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import 'animated_pressable.dart';
import 'glass_card.dart';
import 'status_badge.dart';
import 'time_pill.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    this.log,
    this.compact = false,
    this.index = 0,
    this.onStart,
    this.onComplete,
    this.onDelete,
  });

  final ScheduleModel schedule;
  final StudyLogModel? log;
  final bool compact;
  final int index;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _softSubjectColor(schedule.displayColor, context);
    final status = _status();
    final statusData = _statusData(status, context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedPressable(
        onTap: () => context.push('/schedule/${schedule.id}', extra: schedule),
        child: GlassCard(
          margin: EdgeInsets.only(bottom: compact ? 12 : 16),
          radius: 24,
          padding: EdgeInsets.all(compact ? 16 : 18),
          borderColor: color.withValues(alpha: 0.22),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.035),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SubjectDot(color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TimePill(
                                  color: color,
                                  label:
                                      '${formatMinutes(schedule.startTime)} - ${formatMinutes(schedule.endTime)}',
                                ),
                                StatusBadge(
                                  label: statusData.label,
                                  icon: statusData.icon,
                                  color: statusData.color,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Tuỳ chọn',
                        icon: const Icon(Icons.more_horiz_rounded),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            context.push(
                              '/schedule/${schedule.id}',
                              extra: schedule,
                            );
                          }
                          if (value == 'delete') _confirmDelete(context);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded),
                                SizedBox(width: 10),
                                Text('Sửa'),
                              ],
                            ),
                          ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded),
                                  SizedBox(width: 10),
                                  Text('Xoá'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        if (schedule.room.isNotEmpty)
                          _MetaItem(
                            icon: Icons.location_on_rounded,
                            label: schedule.room,
                          ),
                        if (schedule.teacher.isNotEmpty)
                          _MetaItem(
                            icon: Icons.person_rounded,
                            label: schedule.teacher,
                          ),
                        if (schedule.note.isNotEmpty)
                          _MetaItem(
                            icon: Icons.notes_rounded,
                            label: schedule.note,
                          ),
                      ],
                    ),
                  ],
                  if (onStart != null || onComplete != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (onStart != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onStart,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Bắt đầu học'),
                            ),
                          ),
                        if (onStart != null && onComplete != null)
                          const SizedBox(width: 10),
                        if (onComplete != null)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onComplete,
                              icon: const Icon(Icons.done_rounded),
                              label: const Text('Đã học'),
                              style: FilledButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _confirmDelete(BuildContext context) async {
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá lịch học?'),
        content: Text(
          'Môn ${schedule.subjectName} sẽ bị xoá khỏi lịch của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }

  _StatusData _statusData(_ClassStatus status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      _ClassStatus.upcoming => _StatusData(
        label: 'Sắp học',
        icon: Icons.schedule_rounded,
        color: colorScheme.primary,
      ),
      _ClassStatus.active => const _StatusData(
        label: 'Đang học',
        icon: Icons.play_circle_rounded,
        color: Color(0xFF10A987),
      ),
      _ClassStatus.done => const _StatusData(
        label: 'Đã xong',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF8E99AB),
      ),
    };
  }

  Color _softSubjectColor(Color color, BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return hsl
        .withSaturation((hsl.saturation * 0.72).clamp(0.35, 0.72))
        .withLightness(isDark ? 0.68 : 0.58)
        .toColor();
  }
}

class _SubjectDot extends StatelessWidget {
  const _SubjectDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusData {
  const _StatusData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

enum _ClassStatus { upcoming, active, done }
