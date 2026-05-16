import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../theme/app_motion.dart';
import 'motion_widgets.dart';
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
    this.onReorder,
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
  final ReorderCallback? onReorder;
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
      transitionBuilder: (child, animation) =>
          MorphTransitionWidget(animation: animation, child: child),
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
              onReorder: onReorder,
            ),
          ),
          ...trailingSlivers,
        ],
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
    this.onReorder,
  });

  final List<ScheduleModel> schedules;
  final bool compact;
  final StudyLogForSchedule? logForSchedule;
  final ScheduleCallback? onDelete;
  final ScheduleCallback? onStart;
  final ScheduleCallback? onComplete;
  final ReorderCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    if (onReorder != null) {
      return SliverReorderableList(
        itemBuilder: (context, index) =>
            _buildItem(context, index, draggable: true),
        itemCount: schedules.length,
        onReorder: onReorder!,
        proxyDecorator: _proxyDecorator,
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        _buildItem,
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

  Widget _buildItem(BuildContext context, int index, {bool draggable = false}) {
    final schedule = schedules[index];
    final card = MorphingScheduleCard(
      key: ValueKey('morph-schedule-${schedule.id}'),
      scheduleId: schedule.id,
      index: index,
      child: ScheduleCard(
        key: ValueKey('schedule-card-${schedule.id}'),
        schedule: schedule,
        log: logForSchedule?.call(schedule),
        compact: compact,
        index: index,
        showDragHandle: draggable,
        dragIndex: draggable ? index : null,
        onDelete: onDelete == null ? null : () => onDelete!(schedule),
        onStart: onStart == null ? null : () => onStart!(schedule),
        onComplete: onComplete == null ? null : () => onComplete!(schedule),
      ),
    );
    if (!draggable) return card;
    return KeyedSubtree(
      key: ValueKey('reorder-schedule-${schedule.id}'),
      child: card,
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return MorphTransitionWidget(
      animation: animation,
      beginScale: 0.98,
      beginOffset: Offset.zero,
      child: Material(
        color: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        child: child,
      ),
    );
  }
}

class MorphingScheduleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ScheduleFadeWidget(index: index, child: child);
  }
}

typedef StudyLogForSchedule = StudyLogModel? Function(ScheduleModel schedule);
typedef ScheduleCallback = void Function(ScheduleModel schedule);
