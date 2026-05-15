import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';
import '../widgets/time_pill.dart';

class WidgetPreviewScreen extends ConsumerWidget {
  const WidgetPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySchedulesProvider).valueOrNull ?? const [];
    final next = _next(today);
    return Scaffold(
      appBar: AppBar(title: const Text('Widget iPhone')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const SectionHeader(
                title: 'Home Screen Widget',
                subtitle: 'Dữ liệu được sync local để WidgetKit đọc nhanh',
              ),
              const SizedBox(height: 16),
              _SmallWidgetPreview(next: next),
              const SizedBox(height: 16),
              _MediumWidgetPreview(items: today.take(3).toList()),
              const SizedBox(height: 16),
              _LargeWidgetPreview(items: today),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(widgetSyncActionsProvider).syncNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sync dữ liệu widget.')),
                    );
                  }
                },
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sync widget ngay'),
              ),
            ],
          ),
        ),
      ),
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
        borderColor: color.withValues(alpha: 0.20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_month_rounded, color: color),
            const Spacer(),
            Text(
              next?.subjectName ?? 'Không có lịch hôm nay',
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
            const Text('Không có lịch hôm nay')
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(item.subjectName)),
                    Text(formatMinutes(item.startTime)),
                  ],
                ),
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
            'Timeline',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (final item in items.take(6))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: item.displayColor.withValues(alpha: 0.16),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: item.displayColor,
                ),
              ),
              title: Text(item.subjectName),
              subtitle: Text(item.room),
              trailing: Text(formatMinutes(item.startTime)),
            ),
        ],
      ),
    );
  }
}
