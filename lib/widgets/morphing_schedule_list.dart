import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import 'schedule_card.dart';

class MorphingScheduleList extends StatelessWidget {
  const MorphingScheduleList({
    super.key,
    required this.schedules,
    this.padding = EdgeInsets.zero,
    this.storageKey,
    this.compact = false,
    this.logForSchedule,
    this.onDelete,
    this.onStart,
    this.onComplete,
    this.headerSlivers = const [],
    this.trailingSlivers = const [],
  });

  final List<ScheduleModel> schedules;
  final EdgeInsetsGeometry padding;
  final PageStorageKey<String>? storageKey;
  final bool compact;
  final StudyLogForSchedule? logForSchedule;
  final ScheduleCallback? onDelete;
  final ScheduleCallback? onStart;
  final ScheduleCallback? onComplete;
  final List<Widget> headerSlivers;
  final List<Widget> trailingSlivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: storageKey,
      slivers: [
        ...headerSlivers,
        SliverPadding(
          padding: padding,
          sliver: SliverMorphingScheduleList(
            schedules: schedules,
            compact: compact,
            logForSchedule: logForSchedule,
            onDelete: onDelete,
            onStart: onStart,
            onComplete: onComplete,
          ),
        ),
        ...trailingSlivers,
      ],
    );
  }
}

class SliverMorphingScheduleList extends StatelessWidget {
  const SliverMorphingScheduleList({
    super.key,
    required this.schedules,
    this.compact = false,
    this.logForSchedule,
    this.onDelete,
    this.onStart,
    this.onComplete,
  });

  final List<ScheduleModel> schedules;
  final bool compact;
  final StudyLogForSchedule? logForSchedule;
  final ScheduleCallback? onDelete;
  final ScheduleCallback? onStart;
  final ScheduleCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return MorphingScheduleCard(
          key: ValueKey('morph-schedule-${schedule.id}'),
          scheduleId: schedule.id,
          index: index,
          child: ScheduleCard(
            key: ValueKey('schedule-card-${schedule.id}'),
            schedule: schedule,
            log: logForSchedule?.call(schedule),
            compact: compact,
            index: index,
            onDelete: onDelete == null ? null : () => onDelete!(schedule),
            onStart: onStart == null ? null : () => onStart!(schedule),
            onComplete: onComplete == null ? null : () => onComplete!(schedule),
          ),
        );
      },
    );
  }
}

class MorphingScheduleCard extends StatefulWidget {
  const MorphingScheduleCard({
    super.key,
    required this.scheduleId,
    required this.index,
    required this.child,
  });

  final String scheduleId;
  final int index;
  final Widget child;

  @override
  State<MorphingScheduleCard> createState() => _MorphingScheduleCardState();
}

class _MorphingScheduleCardState extends State<MorphingScheduleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future<void>.delayed(Duration(milliseconds: widget.index * 28), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MorphingScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduleId != widget.scheduleId ||
        oldWidget.index != widget.index) {
      _controller
        ..duration = Duration(
          milliseconds: 300 + widget.index.clamp(0, 5) * 20,
        )
        ..forward(from: 0.18);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _curved,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
        builder: (context, child) {
          final value = _curved.value;
          final easedOpacity = value.clamp(0.0, 1.0);
          return Opacity(
            opacity: easedOpacity,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - value)),
              child: Transform.scale(
                scale: 0.965 + (0.035 * value),
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

typedef StudyLogForSchedule = StudyLogModel? Function(ScheduleModel schedule);
typedef ScheduleCallback = void Function(ScheduleModel schedule);
