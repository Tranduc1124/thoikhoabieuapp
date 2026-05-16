import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'animated_pressable.dart';
import 'glass_card.dart';
import 'motion_widgets.dart';

class ScheduleCard extends ConsumerWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    this.log,
    this.compact = false,
    this.index = 0,
    this.onStart,
    this.onComplete,
    this.onDelete,
    this.showDragHandle = false,
  });

  final ScheduleModel schedule;
  final StudyLogModel? log;
  final bool compact;
  final int index;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedExpanded = ref.watch(
      expandedCompletedCardsProvider.select(
        (value) => value[schedule.id] ?? false,
      ),
    );
    return PremiumScheduleCard(
      schedule: schedule,
      log: log,
      compact: compact,
      index: index,
      onStart: onStart,
      onComplete: onComplete,
      onDelete: onDelete,
      showDragHandle: showDragHandle,
      isExpandedByUser: completedExpanded,
      onToggleCompletedCard: () =>
          ref.read(expandedCompletedCardsProvider.notifier).toggle(schedule.id),
    );
  }
}

class PremiumScheduleCard extends StatelessWidget {
  const PremiumScheduleCard({
    super.key,
    required this.schedule,
    this.log,
    this.compact = false,
    this.index = 0,
    this.onStart,
    this.onComplete,
    this.onDelete,
    this.showDragHandle = false,
    required this.isExpandedByUser,
    required this.onToggleCompletedCard,
  });

  final ScheduleModel schedule;
  final StudyLogModel? log;
  final bool compact;
  final int index;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final bool showDragHandle;
  final bool isExpandedByUser;
  final VoidCallback onToggleCompletedCard;

  @override
  Widget build(BuildContext context) {
    final palette = SubjectPalette.fromSchedule(schedule);
    final status = _status();
    final statusData = _statusData(status, context);
    final isDark = Theme.of(context).colorScheme.isDark;
    final canCollapse = status == _ClassStatus.done;
    final isCollapsed = canCollapse && !isExpandedByUser;
    final isSoon = _isSoon();

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: 'Mở chi tiết môn ${schedule.subjectName}',
        child: AnimatedPressable(
          scale: 0.985,
          onLongPress: showDragHandle
              ? null
              : () => context.push('/schedule/${schedule.id}', extra: schedule),
          onTap: () {
            if (canCollapse) {
              onToggleCompletedCard();
              return;
            }
            context.push('/schedule/${schedule.id}', extra: schedule);
          },
          child: Hero(
            tag: 'schedule-card-${schedule.id}',
            transitionOnUserGestures: true,
            flightShuttleBuilder:
                (context, animation, direction, fromContext, toContext) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.liquid,
                    reverseCurve: AppMotion.exit,
                  );
                  final shuttle = direction == HeroFlightDirection.push
                      ? toContext.widget
                      : fromContext.widget;
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0.84, end: 1).animate(curved),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.965,
                        end: 1,
                      ).animate(curved),
                      child: shuttle,
                    ),
                  );
                },
            child: GlassCard(
              margin: EdgeInsets.only(
                bottom: compact ? AppSpacing.md : AppSpacing.xl,
              ),
              radius: compact ? AppRadius.lg : AppRadius.xl,
              padding: EdgeInsets.zero,
              borderColor: isSoon
                  ? palette.primary.withValues(alpha: isDark ? 0.52 : 0.36)
                  : palette.borderColor(isDark),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  compact ? AppRadius.lg : AppRadius.xl,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: _CardAtmosphere(palette: palette)),
                    Positioned(
                      top: -34,
                      right: -20,
                      child: _GradientGlow(
                        color: palette.primary,
                        size: compact ? 110 : 150,
                        opacity: isDark ? 0.18 : 0.14,
                      ),
                    ),
                    Positioned(
                      left: -42,
                      bottom: -44,
                      child: _GradientGlow(
                        color: palette.secondary,
                        size: compact ? 120 : 170,
                        opacity: isDark ? 0.12 : 0.10,
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(
                                  alpha: isDark ? 0.05 : 0.20,
                                ),
                                Colors.transparent,
                                palette.primary.withValues(
                                  alpha: isDark ? 0.05 : 0.07,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: AppMotion.medium,
                      curve: AppMotion.liquid,
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: isCollapsed ? (compact ? 96 : 104) : 0,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            compact ? AppSpacing.lg : AppSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Header(
                                schedule: schedule,
                                palette: palette,
                                onDelete: onDelete,
                                showDragHandle: showDragHandle,
                                onConfirmDelete: () => _confirmDelete(context),
                              ),
                              if (!isCollapsed) ...[
                                SizedBox(height: compact ? 14 : AppSpacing.lg),
                                Wrap(
                                  spacing: 9,
                                  runSpacing: 9,
                                  children: [
                                    GlassPill(
                                      icon: Icons.access_time_rounded,
                                      label:
                                          '${formatMinutes(schedule.startTime)} - ${formatMinutes(schedule.endTime)}',
                                      palette: palette,
                                    ),
                                    ScheduleStatusPill(
                                      label: isSoon
                                          ? 'Sắp tới'
                                          : statusData.label,
                                      icon: statusData.icon,
                                      colors: statusData.colors,
                                      active:
                                          status == _ClassStatus.active ||
                                          isSoon,
                                      muted: status == _ClassStatus.done,
                                    ),
                                  ],
                                ),
                                if (!compact && _hasInfo) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  Wrap(
                                    spacing: 9,
                                    runSpacing: 9,
                                    children: [
                                      if (schedule.teacher.trim().isNotEmpty)
                                        ScheduleInfoChip(
                                          icon: Icons.school_rounded,
                                          label: schedule.teacher.trim(),
                                          palette: palette,
                                        ),
                                      if (schedule.room.trim().isNotEmpty)
                                        ScheduleInfoChip(
                                          icon: Icons.location_on_rounded,
                                          label: schedule.room.trim(),
                                          palette: palette,
                                        ),
                                      if (schedule.note.trim().isNotEmpty)
                                        ScheduleInfoChip(
                                          icon: Icons.sticky_note_2_rounded,
                                          label: schedule.note.trim(),
                                          palette: palette,
                                        ),
                                      if (schedule.hasMapLocation)
                                        _MapChip(
                                          label: 'Apple Maps',
                                          palette: palette,
                                          onTap: () =>
                                              _openMap(schedule.appleMapsUrl),
                                        ),
                                      if (schedule.hasMapLocation)
                                        _MapChip(
                                          label: 'Google Maps',
                                          palette: palette,
                                          onTap: () =>
                                              _openMap(schedule.googleMapsUrl),
                                        ),
                                    ],
                                  ),
                                ],
                                if (onStart != null || onComplete != null) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  _Actions(
                                    palette: palette,
                                    onStart: onStart,
                                    onComplete: onComplete,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasInfo =>
      schedule.teacher.trim().isNotEmpty ||
      schedule.room.trim().isNotEmpty ||
      schedule.note.trim().isNotEmpty ||
      schedule.hasMapLocation;

  _ClassStatus _status() {
    if (_isCompletedStatus(log?.status.name)) return _ClassStatus.done;
    if (_isActiveStatus(log?.status.name)) return _ClassStatus.active;
    final now = DateTime.now();
    if (now.weekday != schedule.dayOfWeek) return _ClassStatus.upcoming;
    final minutes = now.hour * 60 + now.minute;
    if (minutes > schedule.endTime) return _ClassStatus.done;
    if (minutes >= schedule.startTime) return _ClassStatus.active;
    return _ClassStatus.upcoming;
  }

  bool _isCompletedStatus(String? value) {
    if (value == null) return false;
    return const {
      'completed',
      'done',
      'finished',
      'đã xong',
    }.contains(value.trim().toLowerCase());
  }

  bool _isActiveStatus(String? value) {
    if (value == null) return false;
    return const {
      'started',
      'active',
      'in_progress',
      'đang học',
    }.contains(value.trim().toLowerCase());
  }

  bool _isSoon() {
    if (log != null) return false;
    final now = DateTime.now();
    if (now.weekday != schedule.dayOfWeek) return false;
    final minutes = now.hour * 60 + now.minute;
    final remaining = schedule.startTime - minutes;
    return remaining >= 0 && remaining <= 20;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch học?'),
        content: Text(
          'Môn ${schedule.subjectName} sẽ được xóa khỏi thời khóa biểu của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }

  Future<void> _openMap(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  _StatusData _statusData(_ClassStatus status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      _ClassStatus.upcoming => _StatusData(
        label: 'Sắp học',
        icon: Icons.schedule_rounded,
        colors: [colorScheme.primary, AppColors.lavender],
      ),
      _ClassStatus.active => const _StatusData(
        label: 'Đang học',
        icon: Icons.play_circle_rounded,
        colors: [Color(0xFF14B8A6), Color(0xFF4ADE80)],
      ),
      _ClassStatus.done => const _StatusData(
        label: 'Đã xong',
        icon: Icons.check_circle_rounded,
        colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
      ),
      _ClassStatus.cancelled => const _StatusData(
        label: 'Hủy',
        icon: Icons.cancel_rounded,
        colors: [Color(0xFFF87171), Color(0xFFFB7185)],
      ),
    };
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final SubjectPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: ScheduleInfoChip(
        icon: Icons.map_rounded,
        label: label,
        palette: palette,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.schedule,
    required this.palette,
    required this.onDelete,
    required this.showDragHandle,
    required this.onConfirmDelete,
  });

  final ScheduleModel schedule;
  final SubjectPalette palette;
  final VoidCallback? onDelete;
  final bool showDragHandle;
  final VoidCallback onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 320;
        final titleStyle =
            (tight
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
                  height: 1.16,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.textPrimary,
                );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SubjectGradientIcon(palette: palette, compact: tight),
            SizedBox(width: tight ? AppSpacing.sm : AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.subjectName,
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dayName(schedule.dayOfWeek),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: tight ? AppSpacing.xs : AppSpacing.sm),
            if (showDragHandle) ...[
              Semantics(
                label: 'Kéo để sắp xếp môn ${schedule.subjectName}',
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: colorScheme.textSecondary.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            _MoreMenu(
              schedule: schedule,
              onDelete: onDelete,
              onConfirmDelete: onConfirmDelete,
            ),
          ],
        );
      },
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.schedule,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  final ScheduleModel schedule;
  final VoidCallback? onDelete;
  final VoidCallback onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Tùy chọn môn ${schedule.subjectName}',
      child: AnimatedButton(
        onTap: () => _openMenu(context),
        scale: 0.92,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: GlassContainer(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            Icons.more_horiz_rounded,
            color: colorScheme.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      color: context.surfaceColor.withValues(
        alpha: context.isDark ? 0.98 : 0.96,
      ),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded),
              SizedBox(width: AppSpacing.sm),
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
                SizedBox(width: AppSpacing.sm),
                Text('Xóa'),
              ],
            ),
          ),
      ],
    );
    if (!context.mounted || selected == null) return;
    if (selected == 'edit') {
      context.push('/schedule/${schedule.id}', extra: schedule);
    }
    if (selected == 'delete') onConfirmDelete();
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.palette, this.onStart, this.onComplete});

  final SubjectPalette palette;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 330;
        final buttons = [
          if (onStart != null)
            OutlinedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu'),
            ),
          if (onComplete != null)
            FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.done_rounded),
              label: const Text('Đã học'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ];
        if (vertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                buttons[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: buttons[i]),
            ],
          ],
        );
      },
    );
  }
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.radius = 20,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: backgroundColor ?? colorScheme.tileSurface,
        border: Border.all(color: borderColor ?? colorScheme.glassStrokeSubtle),
        boxShadow: [
          BoxShadow(
            color: colorScheme.softShadow.withValues(alpha: 0.62),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassContainer(
      radius: 22,
      borderColor: palette.borderColor(colorScheme.isDark),
      backgroundColor: palette.softFill(colorScheme.isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniGradientIcon(icon: icon, palette: palette),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleStatusPill extends StatefulWidget {
  const ScheduleStatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    this.active = false,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool active;
  final bool muted;

  @override
  State<ScheduleStatusPill> createState() => _ScheduleStatusPillState();
}

class _ScheduleStatusPillState extends State<ScheduleStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ScheduleStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = widget.active ? _controller.value : 0.0;
        return AnimatedScale(
          scale: widget.active ? 1 + pulse * 0.018 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.liquid,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: widget.muted
                    ? [
                        colorScheme.tileSurface,
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: colorScheme.isDark ? 0.22 : 0.72,
                        ),
                      ]
                    : widget.colors,
              ),
              border: Border.all(
                color: widget.muted
                    ? colorScheme.glassStrokeSubtle
                    : colorScheme.glassStroke,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.colors.first.withValues(
                    alpha: widget.active ? 0.20 + pulse * 0.16 : 0.12,
                  ),
                  blurRadius: widget.active ? 18 + pulse * 10 : 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.muted
                      ? colorScheme.textSecondary
                      : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.muted
                        ? colorScheme.textSecondary
                        : Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ScheduleInfoChip extends StatelessWidget {
  const ScheduleInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassContainer(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor: colorScheme.tileSurface,
      borderColor: palette
          .borderColor(colorScheme.isDark)
          .withValues(alpha: colorScheme.isDark ? 0.76 : 0.62),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: palette.primary),
          const SizedBox(width: 6),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.56,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectGradientIcon extends StatelessWidget {
  const SubjectGradientIcon({
    super.key,
    required this.palette,
    this.compact = false,
  });

  final SubjectPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 50.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.sm : AppRadius.md,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.secondary, palette.highlight],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
    );
  }
}

class _MiniGradientIcon extends StatelessWidget {
  const _MiniGradientIcon({required this.icon, required this.palette});

  final IconData icon;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [palette.primary, palette.secondary]),
      ),
      child: Icon(icon, size: 13, color: Colors.white),
    );
  }
}

class _CardAtmosphere extends StatelessWidget {
  const _CardAtmosphere({required this.palette});

  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF101827),
                  const Color(0xFF111827),
                  Color.lerp(const Color(0xFF151D2F), palette.primary, 0.10)!,
                ]
              : [
                  Colors.white.withValues(alpha: 0.78),
                  palette.highlight.withValues(alpha: 0.15),
                  palette.primary.withValues(alpha: 0.08),
                ],
        ),
      ),
    );
  }
}

class _GradientGlow extends StatelessWidget {
  const _GradientGlow({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.35),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class SubjectPalette {
  const SubjectPalette({
    required this.primary,
    required this.secondary,
    required this.highlight,
  });

  final Color primary;
  final Color secondary;
  final Color highlight;

  Color get glow => primary;

  Color softFill(bool isDark) {
    return isDark
        ? Color.lerp(const Color(0xFF101827), primary, 0.14)!
        : Color.lerp(Colors.white, highlight, 0.42)!;
  }

  Color borderColor(bool isDark) {
    return isDark
        ? primary.withValues(alpha: 0.28)
        : primary.withValues(alpha: 0.20);
  }

  static SubjectPalette forSubject(String subject) {
    final normalized = subject.trim().toLowerCase();
    final hash = normalized.runes.fold<int>(
      0,
      (value, char) => (value * 31 + char) & 0x7fffffff,
    );
    return palettes[hash % palettes.length];
  }

  static SubjectPalette fromSchedule(ScheduleModel schedule) {
    if (!schedule.hasCustomColor) {
      return forSubject(schedule.subjectName);
    }
    return fromColor(schedule.displayColor);
  }

  static SubjectPalette fromColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final normalized = hsl
        .withSaturation(hsl.saturation.clamp(0.48, 0.78))
        .withLightness(hsl.lightness.clamp(0.48, 0.62));
    return SubjectPalette(
      primary: normalized.toColor(),
      secondary: normalized
          .withHue((normalized.hue + 10) % 360)
          .withLightness((normalized.lightness + 0.10).clamp(0.52, 0.72))
          .toColor(),
      highlight: normalized
          .withSaturation((normalized.saturation * 0.60).clamp(0.32, 0.62))
          .withLightness(0.82)
          .toColor(),
    );
  }

  static const palettes = [
    SubjectPalette(
      primary: Color(0xFF5B8CFF),
      secondary: Color(0xFF7BA7FF),
      highlight: Color(0xFFA5C4FF),
    ),
    SubjectPalette(
      primary: Color(0xFF7C5CFF),
      secondary: Color(0xFFA78BFA),
      highlight: Color(0xFFC4B5FD),
    ),
    SubjectPalette(
      primary: Color(0xFFFF6FAE),
      secondary: Color(0xFFFF92C2),
      highlight: Color(0xFFFFC2D9),
    ),
    SubjectPalette(
      primary: Color(0xFFFF9F5A),
      secondary: Color(0xFFFFB87A),
      highlight: Color(0xFFFFD1A6),
    ),
    SubjectPalette(
      primary: Color(0xFF14B8A6),
      secondary: Color(0xFF2DD4BF),
      highlight: Color(0xFF99F6E4),
    ),
    SubjectPalette(
      primary: Color(0xFF22C55E),
      secondary: Color(0xFF4ADE80),
      highlight: Color(0xFFBBF7D0),
    ),
    SubjectPalette(
      primary: Color(0xFFF87171),
      secondary: Color(0xFFFB7185),
      highlight: Color(0xFFFECACA),
    ),
    SubjectPalette(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF818CF8),
      highlight: Color(0xFFC7D2FE),
    ),
    SubjectPalette(
      primary: Color(0xFF06B6D4),
      secondary: Color(0xFF67E8F9),
      highlight: Color(0xFFCFFAFE),
    ),
    SubjectPalette(
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFFCD34D),
      highlight: Color(0xFFFEF3C7),
    ),
  ];
}

class _StatusData {
  const _StatusData({
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
}

enum _ClassStatus { upcoming, active, done, cancelled }
