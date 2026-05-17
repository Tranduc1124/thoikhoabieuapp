import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../services/app_feedback_service.dart';
import '../services/share_debug_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/qr_share_box.dart';
import '../widgets/section_header.dart';
import '../widgets/share_schedule_card.dart';
import '../widgets/soft_gradient_background.dart';
import '../widgets/syncing_state_card.dart';

class SharedScheduleViewScreen extends ConsumerStatefulWidget {
  const SharedScheduleViewScreen({super.key, this.shareId});

  final String? shareId;

  @override
  ConsumerState<SharedScheduleViewScreen> createState() =>
      _SharedScheduleViewScreenState();
}

class _SharedScheduleViewScreenState
    extends ConsumerState<SharedScheduleViewScreen> {
  final _controller = TextEditingController();
  String? _shareId;
  final Set<String> _selectedScheduleIds = <String>{};
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _shareId = ShareDebugService.validateShareInput(widget.shareId ?? '');
    _controller.text = widget.shareId ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shareId = _shareId;
    final share = shareId == null
        ? null
        : ref.watch(publicShareProvider(shareId));

    return Scaffold(
      appBar: AppBar(title: const Text('Nhập lịch được chia sẻ')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              GlassCard(
                radius: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mở liên kết để xem trước lịch học.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn có thể thêm toàn bộ hoặc chỉ chọn những môn học cần thiết vào thời khóa biểu của mình.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Dán liên kết chia sẻ',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: _open,
                        ),
                      ),
                      onSubmitted: (_) => _open(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (share == null)
                const EmptyState(
                  title: 'Chưa có lịch nào được mở',
                  message:
                      'Dán liên kết hoặc quét mã để xem trước thời khóa biểu.',
                )
              else
                share.when(
                  skipLoadingOnRefresh: true,
                  skipLoadingOnReload: true,
                  loading: () => const SyncingStateCard(
                    title: 'Đang mở lịch chia sẻ',
                    message: 'Preview sẽ hiện ngay khi link được xác thực.',
                  ),
                  error: (error, _) => EmptyState(
                    title: 'Không mở được lịch chia sẻ',
                    message: AppFeedbackService.messageFor(error),
                    action: FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.invalidate(publicShareProvider(shareId!)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ),
                  data: (data) => _buildShareData(context, data, shareId!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareData(
    BuildContext context,
    ShareScheduleModel? data,
    String shareId,
  ) {
    if (data == null) {
      return const EmptyState(
        title: 'Không tìm thấy lịch học',
        message: 'Link chia sẻ đã bị xóa hoặc không còn hoạt động.',
      );
    }
    if (!data.isActive) {
      return const EmptyState(
        title: 'Liên kết không còn hoạt động',
        message: 'Lịch học này hiện không thể mở được nữa.',
      );
    }

    final schedules = data.schedulesSnapshot;
    final selectedIds = _selectedScheduleIds.isEmpty
        ? schedules.map((item) => item.id).toSet()
        : _selectedScheduleIds;
    final selectedSchedules = schedules
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: data.title, subtitle: 'Từ ${data.ownerName}'),
        const SizedBox(height: 12),
        GlassCard(
          radius: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    icon: Icons.category_rounded,
                    label: '${data.subjects.length} môn học',
                  ),
                  _InfoPill(
                    icon: Icons.auto_stories_rounded,
                    label: '${schedules.length} buổi học',
                  ),
                  _InfoPill(
                    icon: Icons.visibility_rounded,
                    label: '${data.viewCount} lượt xem',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              QrShareBox(
                data: data.publicUrl,
                label: 'Mã QR của lịch học này',
                subtitle: data.id,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Chọn môn học muốn thêm',
          subtitle:
              '${selectedSchedules.length} / ${schedules.length} buổi học đang được chọn.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: selectedIds.length == schedules.length,
              label: const Text('Chọn tất cả'),
              onSelected: (_) {
                setState(() {
                  _selectedScheduleIds
                    ..clear()
                    ..addAll(schedules.map((item) => item.id));
                });
              },
            ),
            FilterChip(
              selected: _selectedScheduleIds.isEmpty,
              label: const Text('Dùng mặc định'),
              onSelected: (_) {
                setState(_selectedScheduleIds.clear);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final schedule in schedules)
          _SelectableShareCard(
            schedule: schedule,
            selected: selectedIds.contains(schedule.id),
            onChanged: (selected) {
              setState(() {
                if (_selectedScheduleIds.isEmpty) {
                  _selectedScheduleIds.addAll(schedules.map((item) => item.id));
                }
                if (selected) {
                  _selectedScheduleIds.add(schedule.id);
                } else {
                  _selectedScheduleIds.remove(schedule.id);
                }
              });
            },
          ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _importing
              ? null
              : () => _importSchedules(data, selectedSchedules),
          icon: _importing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded),
          label: Text(
            _importing
                ? 'Đang thêm vào lịch của bạn…'
                : 'Thêm ${selectedSchedules.length} buổi học',
          ),
        ),
      ],
    );
  }

  Future<void> _importSchedules(
    ShareScheduleModel share,
    List<ScheduleModel> schedules,
  ) async {
    final service = ref.read(shareServiceProvider);
    if (service == null) {
      AppFeedbackService.error(
        context,
        const AppUserMessageException(
          'Bạn cần đăng nhập để thêm lịch học này.',
        ),
      );
      return;
    }
    if (schedules.isEmpty) {
      AppFeedbackService.info(
        context,
        'Hãy chọn ít nhất một buổi học để tiếp tục.',
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final imported = await service.importSchedules(
        share,
        schedules: schedules,
      );
      if (!mounted) return;
      AppFeedbackService.success(
        context,
        imported == 0
            ? 'Không có môn học mới để thêm.'
            : 'Đã thêm $imported buổi học vào thời khóa biểu.',
      );
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<void> _open() async {
    final normalized = ShareDebugService.validateShareInput(_controller.text);
    if (normalized == null || normalized.isEmpty) {
      AppFeedbackService.error(
        context,
        const AppUserMessageException('Liên kết chia sẻ này chưa hợp lệ.'),
      );
      return;
    }
    setState(() {
      _shareId = normalized;
      _selectedScheduleIds.clear();
    });
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

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

class _SelectableShareCard extends StatelessWidget {
  const _SelectableShareCard({
    required this.schedule,
    required this.selected,
    required this.onChanged,
  });

  final ScheduleModel schedule;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Opacity(
          opacity: selected ? 1 : 0.78,
          child: ShareScheduleCard(schedule: schedule),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: Checkbox(
            value: selected,
            onChanged: (value) => onChanged(value ?? false),
            side: BorderSide(color: colorScheme.glassStroke),
          ),
        ),
      ],
    );
  }
}
