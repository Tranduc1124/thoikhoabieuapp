import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../services/firebase_error_translator.dart';
import '../services/nfc_quick_share_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_popup.dart';
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
            tooltip: 'Nhập lịch chia sẻ',
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
                      'Hãy thêm ít nhất một môn học trước khi tạo link hoặc QR.',
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
                            'Chia sẻ lịch học theo cách gọn và an toàn.',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'App sẽ tạo snapshot public trên Firebase, QR code và deep link để người nhận xem hoặc import.',
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
                              _MetricPill(
                                icon: Icons.link_rounded,
                                label: 'Link + QR + import',
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
                          '${selected.length} buổi học sẽ được đưa vào snapshot chia sẻ.',
                    ),
                    const SizedBox(height: 12),
                    if (selected.isEmpty)
                      const EmptyState(
                        title: 'Không có môn phù hợp',
                        message:
                            'Thử đổi loại chia sẻ hoặc chọn một môn khác để tiếp tục.',
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
                            ? 'Đang tạo link chia sẻ...'
                            : 'Tạo link + QR',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _creating
                          ? null
                          : () => context.push('/shared'),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Mở màn import lịch chia sẻ'),
                    ),
                    if (_nfcSupported) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _creating ? null : _shareViaNfc,
                        icon: const Icon(Icons.nfc_rounded),
                        label: const Text('Chia sẻ nhanh qua NFC'),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      'make by minhduc',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
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

  Future<void> _loadNfcSupport() async {
    final supported = await NfcQuickShareService.isSupported();
    if (mounted) {
      setState(() => _nfcSupported = supported);
    }
  }

  Future<void> _createShare(List<ScheduleModel> selected) async {
    final service = ref.read(shareServiceProvider);
    if (service == null) {
      await showAppPopup(
        context,
        title: 'Chưa đăng nhập',
        message: 'Bạn cần đăng nhập trước khi chia sẻ thời khóa biểu.',
        type: AppPopupType.error,
      );
      return;
    }
    if (selected.isEmpty) {
      await showAppPopup(
        context,
        title: 'Không có dữ liệu',
        message: 'Danh sách môn học đang trống nên chưa thể tạo chia sẻ.',
        type: AppPopupType.error,
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final share = await service.createOrUpdateShare(
        type: _type,
        title: _shareTitle(),
        schedules: selected,
      );
      if (!mounted) return;
      await showAppPopup(
        context,
        title: 'Đã tạo chia sẻ',
        message:
            'Link, QR code và bản xem trước đã sẵn sàng. Bạn có thể gửi ngay cho người khác.',
        type: AppPopupType.success,
      );
      if (mounted) {
        context.push('/share/preview', extra: share);
      }
    } catch (error) {
      if (!mounted) return;
      await showAppPopup(
        context,
        title: 'Không thể tạo chia sẻ',
        message: FirebaseErrorTranslator.readable(error),
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _shareViaNfc() async {
    final service = ref.read(shareServiceProvider);
    if (service == null) return;
    try {
      await NfcQuickShareService.startQuickShare(
        service.buildDeepLink('preview'),
      );
    } catch (error) {
      if (!mounted) return;
      await showAppPopup(
        context,
        title: 'NFC chưa sẵn sàng',
        message: FirebaseErrorTranslator.readable(error),
        type: AppPopupType.info,
      );
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
