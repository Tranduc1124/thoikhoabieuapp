import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';
import '../widgets/syncing_state_card.dart';
import '../widgets/time_pill.dart';

class WidgetPreviewScreen extends ConsumerWidget {
  const WidgetPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayState = ref.watch(todaySchedulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Widget iPhone')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const SectionHeader(
                title: 'Xem nhanh lịch học',
                subtitle:
                    'Theo dõi lịch học ngay trên màn hình chính mà không cần mở app.',
              ),
              const SizedBox(height: 16),
              todayState.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const SyncingStateCard(
                  title: 'Đang dựng widget',
                  message: 'Preview sẽ dùng lịch hôm nay ngay khi sẵn sàng.',
                ),
                error: (error, _) => GlassCard(
                  borderColor: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.22),
                  child: Text(AppFeedbackService.messageFor(error)),
                ),
                data: (today) => _WidgetPreviewContent(today: today),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(widgetSyncActionsProvider).syncNow();
                  if (!context.mounted) return;
                  AppFeedbackService.success(
                    context,
                    'Widget đã được cập nhật.',
                  );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Cập nhật widget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WidgetPreviewContent extends StatelessWidget {
  const _WidgetPreviewContent({required this.today});

  final List<ScheduleModel> today;

  @override
  Widget build(BuildContext context) {
    final next = _next(today);
    return Column(
      children: [
        _SmallWidgetPreview(next: next),
        const SizedBox(height: 16),
        _MediumWidgetPreview(items: today.take(3).toList()),
        const SizedBox(height: 16),
        _LargeWidgetPreview(items: today),
      ],
    );
  }

  ScheduleModel? _next(List<ScheduleModel> items) {
    if (items.isEmpty) return null;
    final minutes = DateTime.now().hour * 60 + DateTime.now().minute;
    final upcoming = items.where((item) => item.endTime >= minutes).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.isEmpty ? items.first : upcoming.first;
  }
}

class _SmallWidgetPreview extends StatelessWidget {
  const _SmallWidgetPreview({required this.next});

  final ScheduleModel? next;

  @override
  Widget build(BuildContext context) {
    final color = next?.displayColor ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 168,
      child: GlassCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderColor: color.withValues(alpha: 0.20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_month_rounded, color: color),
            const Spacer(),
            Text(
              next?.subjectName ?? 'Chưa có lịch học hôm nay',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (next != null)
              TimePill(
                color: color,
                label:
                    '${formatMinutes(next!.startTime)} - ${formatMinutes(next!.endTime)}',
              ),
          ],
        ),
      ),
    );
  }
}

class _MediumWidgetPreview extends StatelessWidget {
  const _MediumWidgetPreview({required this.items});

  final List<ScheduleModel> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch hôm nay',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Chưa có lịch học hôm nay',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (final item in items)
              _WidgetScheduleRow(
                key: ValueKey('medium-widget-${item.id}'),
                item: item,
              ),
        ],
      ),
    );
  }
}

class _LargeWidgetPreview extends StatelessWidget {
  const _LargeWidgetPreview({required this.items});

  final List<ScheduleModel> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trong ngày',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Widget sẽ tự hiện môn học khi bạn thêm lịch hôm nay.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          for (final item in items.take(6))
            ListTile(
              key: ValueKey('large-widget-${item.id}'),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
              ),
              leading: CircleAvatar(
                backgroundColor: item.displayColor.withValues(alpha: 0.16),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: item.displayColor,
                ),
              ),
              title: Text(item.subjectName),
              subtitle: Text(
                item.room.trim().isEmpty ? dayName(item.dayOfWeek) : item.room,
              ),
              trailing: Text(formatMinutes(item.startTime)),
            ),
        ],
      ),
    );
  }
}

class _WidgetScheduleRow extends StatelessWidget {
  const _WidgetScheduleRow({super.key, required this.item});

  final ScheduleModel item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: colorScheme.tileSurface,
        border: Border.all(color: colorScheme.glassStrokeSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              color: item.displayColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.subjectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatMinutes(item.startTime),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.mint,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
