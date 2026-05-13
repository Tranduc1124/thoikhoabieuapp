import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/share_schedule_card.dart';
import '../widgets/soft_gradient_background.dart';

class ShareScheduleScreen extends ConsumerStatefulWidget {
  const ShareScheduleScreen({super.key});

  @override
  ConsumerState<ShareScheduleScreen> createState() =>
      _ShareScheduleScreenState();
}

class _ShareScheduleScreenState extends ConsumerState<ShareScheduleScreen> {
  ShareScheduleType _type = ShareScheduleType.week;
  String? _subjectId;
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final schedules =
        ref.watch(schedulesProvider).valueOrNull ?? const <ScheduleModel>[];
    final selected = _selectedSchedules(schedules);
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ lịch')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: schedules.isEmpty
              ? const EmptyState(
                  title: 'Chưa có lịch để chia sẻ',
                  message: 'Thêm lịch học trước khi tạo link hoặc QR.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    const SectionHeader(
                      title: 'Tạo lịch chia sẻ',
                      subtitle: 'Snapshot public chỉ chứa lịch bạn chọn',
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final type in ShareScheduleType.values)
                                ChoiceChip(
                                  selected: _type == type,
                                  label: Text(_label(type)),
                                  onSelected: (_) =>
                                      setState(() => _type = type),
                                ),
                            ],
                          ),
                          if (_type == ShareScheduleType.subject) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _subjectId ?? schedules.first.id,
                              decoration: const InputDecoration(
                                labelText: 'Chọn môn học',
                              ),
                              items: schedules
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.id,
                                      child: Text(item.subjectName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _subjectId = value),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionHeader(title: 'Preview (${selected.length} môn)'),
                    const SizedBox(height: 12),
                    for (final schedule in selected.take(8))
                      ShareScheduleCard(schedule: schedule),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _creating
                          ? null
                          : () => _createShare(selected),
                      icon: _creating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_rounded),
                      label: const Text('Tạo link + QR'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<ScheduleModel> _selectedSchedules(List<ScheduleModel> schedules) {
    final today = DateTime.now().weekday;
    return switch (_type) {
      ShareScheduleType.today =>
        schedules.where((item) => item.dayOfWeek == today).toList(),
      ShareScheduleType.week => schedules,
      ShareScheduleType.subject =>
        schedules
            .where((item) => item.id == (_subjectId ?? schedules.first.id))
            .toList(),
      ShareScheduleType.all => schedules,
    }..sort((a, b) {
      final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      return dayCompare == 0 ? a.startTime.compareTo(b.startTime) : dayCompare;
    });
  }

  Future<void> _createShare(List<ScheduleModel> selected) async {
    final service = ref.read(shareServiceProvider);
    if (service == null || selected.isEmpty) return;
    setState(() => _creating = true);
    try {
      final share = await service.createShare(
        type: _type,
        title: _label(_type),
        schedules: selected,
      );
      if (mounted) context.push('/share/preview', extra: share);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String _label(ShareScheduleType type) {
    return switch (type) {
      ShareScheduleType.today => 'Lịch hôm nay',
      ShareScheduleType.week => 'Lịch tuần này',
      ShareScheduleType.subject => 'Một môn học',
      ShareScheduleType.all => 'Toàn bộ lịch',
    };
  }
}
