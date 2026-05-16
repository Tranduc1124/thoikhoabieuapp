import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_event_model.dart';
import '../providers/calendar_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/vietnamese_calendar_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _monthNames = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedCalendarMonthProvider);
    final events = ref.watch(calendarEventsProvider);
    final pinned = ref.watch(pinnedCalendarEventProvider);

    return SoftGradientBackground(
      child: SafeArea(
        child: CustomScrollView(
          key: const PageStorageKey('calendar-scroll'),
          cacheExtent: 760,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: _CalendarHeader(
                  month: month,
                  onPrevious: () =>
                      _setMonth(ref, DateTime(month.year, month.month - 1)),
                  onNext: () =>
                      _setMonth(ref, DateTime(month.year, month.month + 1)),
                  onToday: () => _setMonth(ref, DateTime.now()),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  switchInCurve: AppMotion.liquid,
                  switchOutCurve: AppMotion.exit,
                  child: pinned == null
                      ? const _CalendarHintCard(key: ValueKey('calendar-hint'))
                      : _PinnedCalendarCard(
                          key: ValueKey('calendar-pinned-${pinned.dateKey}'),
                          event: pinned,
                          onTap: () => _openEditor(
                            context,
                            ref,
                            VietnameseCalendarUtils.parseDateKey(
                              pinned.dateKey,
                            ),
                            pinned,
                          ),
                        ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Lịch',
                  subtitle: 'Ghi chú ngày thi, khảo sát, deadline và ngày lễ',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              sliver: SliverToBoxAdapter(
                child: _WeekdayRow(labels: _weekdayLabels),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                116,
              ),
              sliver: events.when(
                loading: () => const SliverToBoxAdapter(
                  child: LoadingSkeleton(itemCount: 3),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: 'Không tải được lịch',
                    message: 'Dữ liệu lịch local chưa sẵn sàng, thử lại sau.',
                    action: FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(calendarEventsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tải lại'),
                    ),
                  ),
                ),
                data: (items) => SliverToBoxAdapter(
                  child: _CalendarGrid(
                    month: month,
                    events: items,
                    onDayTap: (date, event) =>
                        _openEditor(context, ref, date, event),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String monthTitle(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  void _setMonth(WidgetRef ref, DateTime date) {
    ref.read(selectedCalendarMonthProvider.notifier).state = DateTime(
      date.year,
      date.month,
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    CalendarEventModel? event,
  ) async {
    final key = VietnameseCalendarUtils.dateKey(date);
    final titleController = TextEditingController(text: event?.title ?? '');
    final noteController = TextEditingController(text: event?.note ?? '');
    var selectedColor = event?.colorValue ?? _CalendarPalette.values.first;
    var pinned = event?.pinned ?? false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  color: colorScheme.surfaceColor,
                  border: Border.all(color: colorScheme.glassStrokeSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.softShadow,
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dateTitle(date),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: colorScheme.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Âm lịch ${VietnameseCalendarUtils.lunarDate(date).shortLabel}',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: colorScheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Đóng',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          hintText: 'Lịch thi, khảo sát, sinh nhật...',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: noteController,
                        minLines: 3,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Note / comment',
                          hintText: 'Ghi nội dung cần nhớ cho ngày này',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Màu ngày',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final colorValue in _CalendarPalette.values)
                            _ColorSwatch(
                              color: Color(colorValue),
                              selected: selectedColor == colorValue,
                              onTap: () => setModalState(
                                () => selectedColor = colorValue,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: pinned,
                        onChanged: (value) =>
                            setModalState(() => pinned = value),
                        title: const Text('Ghim lên Home'),
                        subtitle: const Text(
                          'Hiển thị countdown to rõ ở màn Home.',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          if (event != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await ref
                                      .read(calendarActionsProvider)
                                      .delete(key);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Xóa'),
                              ),
                            ),
                          if (event != null)
                            const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final next = CalendarEventModel(
                                  dateKey: key,
                                  title: titleController.text.trim(),
                                  note: noteController.text.trim(),
                                  colorValue: selectedColor,
                                  pinned: pinned,
                                  updatedAt: DateTime.now(),
                                );
                                await ref
                                    .read(calendarActionsProvider)
                                    .save(next);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Lưu ngày'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    noteController.dispose();
  }

  String _dateTitle(DateTime date) {
    return 'Ngày ${date.day}/${date.month}/${date.year}';
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
            colorScheme.primary.withValues(alpha: 0.14),
            colorScheme.tertiary.withValues(alpha: 0.11),
          ],
        ),
        border: Border.all(color: colorScheme.glassStroke),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.13),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'calendar-tab-icon',
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                ),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CalendarScreen.monthTitle(month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Nhấn vào từng ngày để đổi màu, note và ghim countdown',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _HeaderIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: AppSpacing.xs),
          _HeaderIconButton(icon: Icons.today_rounded, onTap: onToday),
          const SizedBox(width: AppSpacing.xs),
          _HeaderIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: colorScheme.tileSurface,
          border: Border.all(color: colorScheme.glassStrokeSubtle),
        ),
        child: Icon(icon, size: 21, color: colorScheme.textPrimary),
      ),
    );
  }
}

class _CalendarHintCard extends StatelessWidget {
  const _CalendarHintCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: colorScheme.tileSurface,
        border: Border.all(color: colorScheme.glassStrokeSubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Ghim một ngày quan trọng để hiện countdown lớn ở Home.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedCalendarCard extends StatelessWidget {
  const _PinnedCalendarCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final CalendarEventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = Color(event.colorValue);
    final days = VietnameseCalendarUtils.countdownDays(event.dateKey);
    final date = VietnameseCalendarUtils.parseDateKey(event.dateKey);
    final countdown = days == 0
        ? 'Hôm nay'
        : days > 0
        ? 'Còn $days ngày'
        : 'Đã qua ${days.abs()} ngày';
    return AnimatedButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [
              eventColor.withValues(alpha: colorScheme.isDark ? 0.24 : 0.18),
              colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(color: eventColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: eventColor.withValues(alpha: 0.18),
              ),
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: eventColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countdown,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: eventColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    event.title.isEmpty ? 'Ngày đã ghim' : event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  if (event.note.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      event.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.events,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<String, CalendarEventModel> events;
  final void Function(DateTime date, CalendarEventModel? event) onDayTap;

  @override
  Widget build(BuildContext context) {
    final days = VietnameseCalendarUtils.monthGridDays(month);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: compact ? AppSpacing.xs : AppSpacing.sm,
            mainAxisSpacing: compact ? AppSpacing.xs : AppSpacing.sm,
            childAspectRatio: compact ? 0.72 : 0.86,
          ),
          itemBuilder: (context, index) {
            final date = days[index];
            final key = VietnameseCalendarUtils.dateKey(date);
            return ScheduleFadeWidget(
              index: index,
              child: _CalendarDayCell(
                date: date,
                month: month,
                event: events[key],
                compact: compact,
                onTap: () => onDayTap(date, events[key]),
              ),
            );
          },
        );
      },
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.month,
    required this.event,
    required this.compact,
    required this.onTap,
  });

  final DateTime date;
  final DateTime month;
  final CalendarEventModel? event;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final inMonth = date.month == month.month;
    final lunar = VietnameseCalendarUtils.lunarDate(date);
    final holiday = VietnameseCalendarUtils.holidayLabel(date);
    final eventColor = event == null
        ? colorScheme.primary
        : Color(event!.colorValue);
    final hasEvent = event?.hasContent == true;

    return Semantics(
      button: true,
      label:
          'Ngày ${date.day} tháng ${date.month}. ${holiday ?? ''} ${event?.title ?? ''}',
      child: AnimatedButton(
        onTap: onTap,
        scale: 0.97,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.liquid,
          padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: hasEvent
                ? eventColor.withValues(alpha: colorScheme.isDark ? 0.22 : 0.16)
                : colorScheme.tileSurface,
            border: Border.all(
              width: today ? 1.6 : 1,
              color: today
                  ? colorScheme.primary
                  : hasEvent
                  ? eventColor.withValues(alpha: 0.38)
                  : colorScheme.glassStrokeSubtle,
            ),
            boxShadow: hasEvent
                ? [
                    BoxShadow(
                      color: eventColor.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${date.day}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: inMonth
                            ? colorScheme.textPrimary
                            : colorScheme.textHint,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (event?.pinned == true)
                    Icon(Icons.push_pin_rounded, size: 13, color: eventColor),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'ÂL ${lunar.shortLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: inMonth
                      ? colorScheme.textSecondary
                      : colorScheme.textHint.withValues(alpha: 0.76),
                  fontSize: compact ? 9.5 : 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (holiday != null) ...[
                const SizedBox(height: 2),
                Text(
                  holiday,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: eventColor,
                    fontSize: compact ? 9 : 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              const Spacer(),
              if (hasEvent)
                Text(
                  event!.title.isEmpty ? event!.note : event!.title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 14,
                    color: colorScheme.textHint.withValues(alpha: 0.72),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.liquid,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            width: selected ? 3 : 1,
            color: selected ? Theme.of(context).colorScheme.textPrimary : color,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: selected ? 0.34 : 0.18),
              blurRadius: selected ? 18 : 9,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _CalendarPalette {
  const _CalendarPalette._();

  static const values = <int>[
    0xFF6A8DFF,
    0xFF67D7B0,
    0xFFFFB397,
    0xFFA78BFA,
    0xFFFF7A8A,
    0xFF8ED8FF,
    0xFFFFC66D,
    0xFF2ECC9B,
  ];
}
