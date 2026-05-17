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
import '../widgets/motion_widgets.dart';
import '../widgets/soft_gradient_background.dart';
import '../widgets/syncing_state_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
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

  static String monthTitle(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedCalendarMonthProvider);
    final eventsState = ref.watch(calendarEventsProvider);
    final eventItems =
        eventsState.valueOrNull ?? ref.watch(calendarEventsSnapshotProvider);
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              sliver: eventItems != null
                  ? SliverToBoxAdapter(
                      child: _CalendarMonthCard(
                        month: month,
                        selectedDate: _selectedDate,
                        events: eventItems,
                        onDayTap: (date, event) {
                          setState(() => _selectedDate = date);
                        },
                        onDayLongPress: (date, event) =>
                            _openEditor(context, ref, date, event),
                      ),
                    )
                  : eventsState.when(
                      skipLoadingOnRefresh: true,
                      skipLoadingOnReload: true,
                      loading: () => const SliverToBoxAdapter(
                        child: SyncingStateCard(
                          title: 'Đang mở lịch',
                          message: 'Ghi chú và ngày đã ghim sẽ được nạp ngay.',
                        ),
                      ),
                      error: (error, _) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          title: 'Không tải được lịch',
                          message:
                              'Dữ liệu lịch local chưa sẵn sàng, thử lại sau.',
                          action: FilledButton.tonalIcon(
                            onPressed: () =>
                                ref.invalidate(calendarEventsProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tải lại'),
                          ),
                        ),
                      ),
                      data: (_) => const SliverToBoxAdapter(child: SizedBox()),
                    ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                116,
              ),
              sliver: eventItems == null
                  ? const SliverToBoxAdapter(child: SizedBox())
                  : SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final selectedKey = VietnameseCalendarUtils.dateKey(
                            _selectedDate,
                          );
                          return _SelectedDayPanel(
                            date: _selectedDate,
                            event: eventItems[selectedKey],
                            monthEvents: _eventsForMonth(eventItems, month),
                            onEdit: () => _openEditor(
                              context,
                              ref,
                              _selectedDate,
                              eventItems[selectedKey],
                            ),
                            onOpenEvent: (event) {
                              final date = VietnameseCalendarUtils.parseDateKey(
                                event.dateKey,
                              );
                              setState(() => _selectedDate = date);
                              _openEditor(context, ref, date, event);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _setMonth(WidgetRef ref, DateTime date) {
    final next = DateTime(date.year, date.month);
    ref.read(selectedCalendarMonthProvider.notifier).state = next;
    setState(() => _selectedDate = DateTime(next.year, next.month, 1));
  }

  List<CalendarEventModel> _eventsForMonth(
    Map<String, CalendarEventModel> items,
    DateTime month,
  ) {
    final events = items.values.where((event) {
      final date = VietnameseCalendarUtils.parseDateKey(event.dateKey);
      return date.year == month.year &&
          date.month == month.month &&
          event.hasContent;
    }).toList()..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return events;
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
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: AppMotion.fast,
              curve: AppMotion.liquid,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.78,
                minChildSize: 0.48,
                maxChildSize: 0.94,
                builder: (context, scrollController) {
                  return Container(
                    margin: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      safeBottom + AppSpacing.md,
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
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
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        bottom: safeBottom + AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 5,
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                color: colorScheme.textHint.withValues(
                                  alpha: 0.38,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _dateTitle(date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: colorScheme.textPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Âm lịch ${VietnameseCalendarUtils.lunarDate(date).shortLabel}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
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
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
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
                  );
                },
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

class _CalendarMonthCard extends StatelessWidget {
  const _CalendarMonthCard({
    required this.month,
    required this.selectedDate,
    required this.events,
    required this.onDayTap,
    required this.onDayLongPress,
  });

  final DateTime month;
  final DateTime selectedDate;
  final Map<String, CalendarEventModel> events;
  final void Function(DateTime date, CalendarEventModel? event) onDayTap;
  final void Function(DateTime date, CalendarEventModel? event) onDayLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthStartColor = colorScheme.isDark
        ? const Color(0xFF111A2B)
        : colorScheme.surfaceContainerHigh.withValues(alpha: 0.94);
    final monthEndColor = colorScheme.isDark
        ? const Color(0xFF0D1424)
        : colorScheme.tileSurface.withValues(alpha: 0.86);
    final monthEvents = events.values.where((event) {
      final date = VietnameseCalendarUtils.parseDateKey(event.dateKey);
      return date.year == month.year &&
          date.month == month.month &&
          event.hasContent;
    }).length;
    final pinnedCount = events.values.where((event) {
      final date = VietnameseCalendarUtils.parseDateKey(event.dateKey);
      return date.year == month.year &&
          date.month == month.month &&
          event.pinned;
    }).length;
    final holidayCount = VietnameseCalendarUtils.monthGridDays(month)
        .where(
          (date) =>
              date.month == month.month &&
              VietnameseCalendarUtils.holidayLabel(date) != null,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [monthStartColor, monthEndColor],
        ),
        border: Border.all(color: colorScheme.glassStrokeSubtle),
        boxShadow: [
          BoxShadow(
            color: colorScheme.softShadow.withValues(alpha: 0.52),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          _MonthStatsRow(
            eventCount: monthEvents,
            pinnedCount: pinnedCount,
            holidayCount: holidayCount,
          ),
          const SizedBox(height: AppSpacing.md),
          _WeekdayRow(labels: CalendarScreen._weekdayLabels),
          const SizedBox(height: AppSpacing.sm),
          _CalendarGrid(
            month: month,
            selectedDate: selectedDate,
            events: events,
            onDayTap: onDayTap,
            onDayLongPress: onDayLongPress,
          ),
        ],
      ),
    );
  }
}

class _MonthStatsRow extends StatelessWidget {
  const _MonthStatsRow({
    required this.eventCount,
    required this.pinnedCount,
    required this.holidayCount,
  });

  final int eventCount;
  final int pinnedCount;
  final int holidayCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Row(
          children: [
            Expanded(
              child: _MonthStatPill(
                icon: Icons.event_note_rounded,
                label: compact ? 'Note' : 'Ghi chú',
                value: '$eventCount',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MonthStatPill(
                icon: Icons.push_pin_rounded,
                label: compact ? 'Ghim' : 'Đã ghim',
                value: '$pinnedCount',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MonthStatPill(
                icon: Icons.flag_rounded,
                label: compact ? 'Lễ' : 'Ngày lễ',
                value: '$holidayCount',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonthStatPill extends StatelessWidget {
  const _MonthStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: colorScheme.tileSurface.withValues(alpha: 0.82),
        border: Border.all(color: colorScheme.glassStrokeSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
    required this.selectedDate,
    required this.events,
    required this.onDayTap,
    required this.onDayLongPress,
  });

  final DateTime month;
  final DateTime selectedDate;
  final Map<String, CalendarEventModel> events;
  final void Function(DateTime date, CalendarEventModel? event) onDayTap;
  final void Function(DateTime date, CalendarEventModel? event) onDayLongPress;

  @override
  Widget build(BuildContext context) {
    final days = VietnameseCalendarUtils.monthGridDays(month);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final cellHeight = compact ? 66.0 : 76.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: compact ? 5 : AppSpacing.xs,
            mainAxisSpacing: compact ? 5 : AppSpacing.xs,
            mainAxisExtent: cellHeight,
          ),
          itemBuilder: (context, index) {
            final date = days[index];
            final key = VietnameseCalendarUtils.dateKey(date);
            return RepaintBoundary(
              child: _CalendarDayCell(
                key: ValueKey('calendar-day-$key'),
                date: date,
                month: month,
                selected: VietnameseCalendarUtils.dateKey(selectedDate) == key,
                event: events[key],
                compact: compact,
                onTap: () => onDayTap(date, events[key]),
                onLongPress: () => onDayLongPress(date, events[key]),
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
    super.key,
    required this.date,
    required this.month,
    required this.selected,
    required this.event,
    required this.compact,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime date;
  final DateTime month;
  final bool selected;
  final CalendarEventModel? event;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
    final muted = !inMonth;

    return Semantics(
      button: true,
      label:
          'Ngày ${date.day} tháng ${date.month}. ${holiday ?? ''} ${event?.title ?? ''}',
      child: AnimatedButton(
        onTap: onTap,
        onLongPress: onLongPress,
        scale: 0.97,
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.sm : AppRadius.md,
        ),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.liquid,
          padding: EdgeInsets.all(compact ? 4 : AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              compact ? AppRadius.sm : AppRadius.md,
            ),
            gradient: hasEvent
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      eventColor.withValues(
                        alpha: colorScheme.isDark ? 0.30 : 0.20,
                      ),
                      colorScheme.surfaceContainerHigh.withValues(
                        alpha: colorScheme.isDark ? 0.56 : 0.76,
                      ),
                    ],
                  )
                : null,
            color: hasEvent
                ? null
                : selected
                ? colorScheme.primary.withValues(alpha: 0.13)
                : colorScheme.tileSurface.withValues(alpha: muted ? 0.45 : 1),
            border: Border.all(
              width: selected || today ? 1.5 : 1,
              color: selected
                  ? eventColor
                  : today
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
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: muted
                            ? colorScheme.textHint.withValues(alpha: 0.78)
                            : selected
                            ? eventColor
                            : colorScheme.textPrimary,
                        fontSize: compact ? 15 : 16,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lunar.shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: muted
                            ? colorScheme.textHint.withValues(alpha: 0.62)
                            : colorScheme.textSecondary,
                        fontSize: compact ? 8.5 : 9.5,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (holiday != null)
                Positioned(
                  left: 5,
                  top: 5,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.28),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              if (event?.pinned == true)
                Positioned(
                  right: 4,
                  top: 3,
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 11,
                    color: eventColor,
                  ),
                ),
              if (hasEvent)
                Positioned(
                  left: 9,
                  right: 9,
                  bottom: 6,
                  child: Container(
                    height: selected ? 4 : 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      color: eventColor,
                    ),
                  ),
                ),
              if (!hasEvent && !muted)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Icon(
                    Icons.add_rounded,
                    size: 11,
                    color: colorScheme.textHint.withValues(alpha: 0.58),
                  ),
                ),
              if (holiday != null && selected)
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 11,
                  child: Text(
                    holiday,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: eventColor,
                      fontSize: 8,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.date,
    required this.event,
    required this.monthEvents,
    required this.onEdit,
    required this.onOpenEvent,
  });

  final DateTime date;
  final CalendarEventModel? event;
  final List<CalendarEventModel> monthEvents;
  final VoidCallback onEdit;
  final ValueChanged<CalendarEventModel> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = Color(event?.colorValue ?? 0xFF6A8DFF);
    final holiday = VietnameseCalendarUtils.holidayLabel(date);
    final lunar = VietnameseCalendarUtils.lunarDate(date);
    final panelSurface = colorScheme.isDark
        ? const Color(0xFF101827)
        : colorScheme.surfaceContainerHigh.withValues(alpha: 0.90);
    final eventListSurface = colorScheme.isDark
        ? const Color(0xFF111A2B)
        : colorScheme.surfaceContainerHigh.withValues(alpha: 0.84);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedButton(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  eventColor.withValues(
                    alpha: event == null
                        ? (colorScheme.isDark ? 0.13 : 0.09)
                        : (colorScheme.isDark ? 0.27 : 0.18),
                  ),
                  panelSurface,
                ],
              ),
              border: Border.all(
                color: eventColor.withValues(
                  alpha: event == null ? 0.16 : 0.34,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: eventColor.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: eventColor.withValues(alpha: 0.16),
                    border: Border.all(
                      color: eventColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: eventColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'ÂL ${lunar.shortLabel}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event?.title.trim().isNotEmpty == true
                            ? event!.title
                            : holiday ?? 'Chưa có ghi chú',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        event?.note.trim().isNotEmpty == true
                            ? event!.note
                            : 'Nhấn để thêm màu, note, comment hoặc ghim countdown.',
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
                Icon(Icons.edit_calendar_rounded, color: eventColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: eventListSurface,
            border: Border.all(color: colorScheme.glassStrokeSubtle),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sự kiện tháng này',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      '${monthEvents.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (monthEvents.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: colorScheme.tileSurface,
                    border: Border.all(color: colorScheme.glassStrokeSubtle),
                  ),
                  child: Text(
                    'Tháng này chưa có ngày được ghi chú.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                for (final item in monthEvents.take(6))
                  _MonthEventTile(
                    key: ValueKey('month-event-${item.dateKey}'),
                    event: item,
                    onTap: () => onOpenEvent(item),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthEventTile extends StatelessWidget {
  const _MonthEventTile({super.key, required this.event, required this.onTap});

  final CalendarEventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = VietnameseCalendarUtils.parseDateKey(event.dateKey);
    final color = Color(event.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AnimatedButton(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: colorScheme.tileSurface,
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  color: color.withValues(alpha: 0.16),
                ),
                child: Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
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
                      event.title.isEmpty ? 'Ngày đã ghi chú' : event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (event.note.trim().isNotEmpty)
                      Text(
                        event.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (event.pinned)
                Icon(Icons.push_pin_rounded, color: color, size: 18),
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
