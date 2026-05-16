import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../theme/app_motion.dart';
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
    final idsKey = schedules.map((item) => item.id).join('|');
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      reverseDuration: AppMotion.fast,
      switchInCurve: AppMotion.liquid,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: _morphTransition,
      child: CustomScrollView(
        key: ValueKey('${storageKey?.value ?? 'schedule-list'}-$idsKey'),
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
      ),
    );
  }

  Widget _morphTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.liquid);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.70, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      ),
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
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
        childCount: schedules.length,
        findChildIndexCallback: (key) {
          final value = key is ValueKey<String> ? key.value : null;
          if (value == null || !value.startsWith('morph-schedule-')) {
            return null;
          }
          final id = value.substring('morph-schedule-'.length);
          final index = schedules.indexWhere((item) => item.id == id);
          return index < 0 ? null : index;
        },
      ),
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
      duration: AppMotion.medium,
    );
    _curved = CurvedAnimation(parent: _controller, curve: AppMotion.liquid);
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
          milliseconds: AppMotion.medium.inMilliseconds +
              widget.index.clamp(0, 5) * 20,
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
          duration: AppMotion.medium,
          curve: AppMotion.liquid,
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
