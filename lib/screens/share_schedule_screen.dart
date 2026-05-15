import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
import '../services/nfc_quick_share_service.dart';
import '../theme/app_colors.dart';
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
  bool _nfcSupported = false;

  @override
  void initState() {
    super.initState();
    _loadNfcSupport();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final schedules =
        ref.watch(schedulesProvider).valueOrNull ?? const <ScheduleModel>[];
    final selected = _selectedSchedules(schedules);
    final subjectCount = selected
        .map((item) => item.subjectName)
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chia sẻ thời khóa biểu'),
        actions: [
          IconButton(
            tooltip: 'Lịch đã chia sẻ',
            onPressed: () => context.push('/shared-links'),
            icon: const Icon(Icons.folder_shared_rounded),
          ),
          IconButton(
            tooltip: 'Nhập lịch được chia sẻ',
            onPressed: () => context.push('/shared'),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: SoftGradientBackground(
        child: SafeArea(
          child: schedules.isEmpty
              ? const EmptyState(
                  title: 'Chưa có lịch để chia sẻ',
                  message:
                      'Hãy thêm ít nhất một môn học trước khi tạo liên kết hoặc mã QR.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    GlassCard(
                      radius: 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chia sẻ lịch học theo cách gọn gàng và dễ dùng.',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tạo một bản xem trước thật đẹp để bạn bè mở nhanh, quét mã hoặc lưu lại chỉ trong vài chạm.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetricPill(
                                icon: Icons.auto_stories_rounded,
                                label: '${selected.length} buổi học',
                              ),
                              _MetricPill(
                                icon: Icons.category_rounded,
                                label: '$subjectCount môn học',
                              ),
                              const _MetricPill(
                                icon: Icons.link_rounded,
                                label: 'Liên kết và mã QR',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SectionHeader(
                      title: 'Chọn phạm vi chia sẻ',
                      subtitle:
                          'Bạn có thể gửi lịch hôm nay, tuần này hoặc một môn cụ thể.',
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      radius: 30,
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
                                  label: Text(_typeLabel(type)),
                                  onSelected: (_) => setState(() {
                                    _type = type;
                                    if (type == ShareScheduleType.subject &&
                                        schedules.isNotEmpty) {
                                      _subjectId ??= schedules.first.id;
                                    }
                                  }),
                                ),
                            ],
                          ),
                          if (_type == ShareScheduleType.subject) ...[
                            const SizedBox(height: 16),
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
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: 'Bản xem trước',
                      subtitle:
                          '${selected.length} buổi học sẽ xuất hiện trong nội dung chia sẻ.',
                    ),
                    const SizedBox(height: 12),
                    if (selected.isEmpty)
                      const EmptyState(
                        title: 'Không có môn học phù hợp',
                        message:
                            'Thử đổi phạm vi chia sẻ hoặc chọn một môn khác để tiếp tục.',
                      )
                    else ...[
                      for (final schedule in selected.take(8))
                        ShareScheduleCard(schedule: schedule),
                    ],
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
                          : const Icon(Icons.ios_share_rounded),
                      label: Text(
                        _creating
                            ? 'Đang chuẩn bị nội dung chia sẻ...'
                            : 'Tạo liên kết chia sẻ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _creating
                          ? null
                          : () => context.push('/shared'),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Mở màn nhập lịch chia sẻ'),
                    ),
                    if (_nfcSupported) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _creating
                            ? null
                            : () => _shareViaNfc(selected),
                        icon: const Icon(Icons.nfc_rounded),
                        label: const Text('Chia sẻ nhanh qua NFC'),
                      ),
                    ],
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

  Future<void> _loadNfcSupport() async {
    final supported = await NfcQuickShareService.isSupported();
    if (mounted) {
      setState(() => _nfcSupported = supported);
    }
  }

  Future<ShareScheduleModel?> _prepareShare(
    List<ScheduleModel> selected,
  ) async {
    final service = ref.read(shareServiceProvider);
    if (service == null) {
      AppFeedbackService.error(
        context,
        const AppUserMessageException(
          'Bạn cần đăng nhập trước khi chia sẻ thời khóa biểu.',
        ),
      );
      return null;
    }
    if (selected.isEmpty) {
      AppFeedbackService.error(
        context,
        const AppUserMessageException(
          'Danh sách môn học đang trống nên chưa thể tạo chia sẻ.',
        ),
      );
      return null;
    }

    return service.createOrUpdateShare(
      type: _type,
      title: _shareTitle(),
      schedules: selected,
    );
  }

  Future<void> _createShare(List<ScheduleModel> selected) async {
    setState(() => _creating = true);
    try {
      final share = await _prepareShare(selected);
      if (share == null || !mounted) return;
      AppFeedbackService.success(context, 'Đã tạo liên kết chia sẻ');
      context.push('/share/preview', extra: share);
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _shareViaNfc(List<ScheduleModel> selected) async {
    setState(() => _creating = true);
    try {
      final share = await _prepareShare(selected);
      if (share == null) return;
      await NfcQuickShareService.startQuickShare(share.publicUrl);
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã sẵn sàng chia sẻ qua NFC.');
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.info(context, AppFeedbackService.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  String _typeLabel(ShareScheduleType type) {
    return switch (type) {
      ShareScheduleType.today => 'Hôm nay',
      ShareScheduleType.week => 'Tuần này',
      ShareScheduleType.subject => 'Một môn',
      ShareScheduleType.all => 'Toàn bộ',
    };
  }

  String _shareTitle() {
    return switch (_type) {
      ShareScheduleType.today => 'Lịch học hôm nay',
      ShareScheduleType.week => 'Lịch học tuần này',
      ShareScheduleType.subject => 'Lịch học môn đã chọn',
      ShareScheduleType.all => 'Toàn bộ thời khóa biểu',
    };
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.tileSurface,
        border: Border.all(color: colorScheme.glassStrokeSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
