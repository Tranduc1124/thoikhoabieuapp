import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
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
    return CustomScrollView(
      key: storageKey,
      cacheExtent: 900,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
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
        showDragHandle: false,
        onDelete: onDelete == null ? null : () => onDelete!(schedule),
        onStart: onStart == null ? null : () => onStart!(schedule),
        onComplete: onComplete == null ? null : () => onComplete!(schedule),
      ),
    );
    if (!draggable) return card;
    return KeyedSubtree(
      key: ValueKey('reorder-schedule-${schedule.id}'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: compact ? AppSpacing.md : AppSpacing.lg,
            right: AppSpacing.lg,
            child: _FloatingDragHandle(index: index),
          ),
        ],
      ),
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

class _FloatingDragHandle extends StatelessWidget {
  const _FloatingDragHandle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ReorderableDragStartListener(
      index: index,
      child: Tooltip(
        message: 'Keo de sap xep',
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: colorScheme.tileSurface.withValues(alpha: 0.92),
              border: Border.all(color: colorScheme.glassStrokeSubtle),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.softShadow.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: colorScheme.textSecondary.withValues(alpha: 0.9),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef StudyLogForSchedule = StudyLogModel? Function(ScheduleModel schedule);
typedef ScheduleCallback = void Function(ScheduleModel schedule);
