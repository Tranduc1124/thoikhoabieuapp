import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../theme/app_colors.dart';
import 'animated_pressable.dart';
import 'glass_card.dart';

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
    return PremiumScheduleCard(
      schedule: schedule,
      log: log,
      compact: compact,
      index: index,
      onStart: onStart,
      onComplete: onComplete,
      onDelete: onDelete,
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
    final palette = SubjectPalette.fromSchedule(schedule);
    final status = _status();
    final statusData = _statusData(status, context);
    final isDark = Theme.of(context).colorScheme.isDark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 45),
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
        scale: 0.985,
        onTap: () => context.push('/schedule/${schedule.id}', extra: schedule),
        child: GlassCard(
          margin: EdgeInsets.only(bottom: compact ? 12 : 18),
          radius: compact ? 28 : 34,
          padding: EdgeInsets.zero,
          borderColor: palette.borderColor(isDark),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 28 : 34),
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
                Padding(
                  padding: EdgeInsets.all(compact ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        schedule: schedule,
                        palette: palette,
                        onDelete: onDelete,
                        onConfirmDelete: () => _confirmDelete(context),
                      ),
                      SizedBox(height: compact ? 14 : 16),
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
                            label: statusData.label,
                            icon: statusData.icon,
                            colors: statusData.colors,
                            active: status == _ClassStatus.active,
                            muted: status == _ClassStatus.done,
                          ),
                        ],
                      ),
                      if (!compact && _hasInfo) ...[
                        const SizedBox(height: 16),
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
                          ],
                        ),
                      ],
                      if (onStart != null || onComplete != null) ...[
                        const SizedBox(height: 18),
                        _Actions(
                          palette: palette,
                          onStart: onStart,
                          onComplete: onComplete,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasInfo =>
      schedule.teacher.trim().isNotEmpty ||
      schedule.room.trim().isNotEmpty ||
      schedule.note.trim().isNotEmpty;

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
        label: 'Huỷ',
        icon: Icons.cancel_rounded,
        colors: [Color(0xFFF87171), Color(0xFFFB7185)],
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.schedule,
    required this.palette,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  final ScheduleModel schedule;
  final SubjectPalette palette;
  final VoidCallback? onDelete;
  final VoidCallback onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubjectGradientIcon(palette: palette),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
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
        const SizedBox(width: 8),
        _MoreMenu(
          schedule: schedule,
          onDelete: onDelete,
          onConfirmDelete: onConfirmDelete,
        ),
      ],
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
    return GlassContainer(
      radius: 18,
      padding: EdgeInsets.zero,
      child: PopupMenuButton<String>(
        tooltip: 'Tuỳ chọn',
        icon: Icon(
          Icons.more_horiz_rounded,
          color: colorScheme.textSecondary,
          size: 22,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorScheme.isDark
            ? const Color(0xFF151D2F)
            : Colors.white.withValues(alpha: 0.96),
        onSelected: (value) {
          if (value == 'edit') {
            context.push('/schedule/${schedule.id}', extra: schedule);
          }
          if (value == 'delete') onConfirmDelete();
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
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.palette, this.onStart, this.onComplete});

  final SubjectPalette palette;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onStart != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu học'),
            ),
          ),
        if (onStart != null && onComplete != null) const SizedBox(width: 10),
        if (onComplete != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.done_rounded),
              label: const Text('Đã học'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.textPrimary,
              fontWeight: FontWeight.w900,
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
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
                    : Colors.white.withValues(alpha: 0.22),
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
      radius: 18,
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
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
        ],
      ),
    );
  }
}

class SubjectGradientIcon extends StatelessWidget {
  const SubjectGradientIcon({super.key, required this.palette});

  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
