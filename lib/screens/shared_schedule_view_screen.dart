import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../services/firebase_error_translator.dart';
import '../services/share_debug_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_popup.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/qr_share_box.dart';
import '../widgets/section_header.dart';
import '../widgets/share_schedule_card.dart';
import '../widgets/soft_gradient_background.dart';

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
                      'Mở link, QR hoặc share ID để xem trước.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn có thể import toàn bộ hoặc chỉ chọn vài môn vào tài khoản hiện tại. App sẽ tự tránh trùng lịch.',
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
                        labelText: 'Dán link hoặc share ID',
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
                  title: 'Chưa mở lịch nào',
                  message:
                      'Dán link chia sẻ, deep link hoặc share ID để xem trước thời khóa biểu.',
                )
              else
                share.when(
                  loading: () => const LoadingSkeleton(itemCount: 3),
                  error: (error, _) => EmptyState(
                    title: 'Không mở được lịch chia sẻ',
                    message: FirebaseErrorTranslator.readable(error),
                    action: FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.invalidate(publicShareProvider(shareId!)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ),
                  data: (data) => _buildShareData(context, data, shareId!),
                ),
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

  Widget _buildShareData(
    BuildContext context,
    ShareScheduleModel? data,
    String shareId,
  ) {
    if (data == null) {
      return const EmptyState(
        title: 'Không tìm thấy lịch',
        message: 'Share ID không tồn tại hoặc chủ sở hữu đã xóa liên kết.',
      );
    }
    if (!data.isActive) {
      return const EmptyState(
        title: 'Liên kết đã tắt hoặc hết hạn',
        message: 'Chủ sở hữu không còn cho phép mở snapshot này.',
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
                    label: '${data.subjects.length} môn',
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
                data: data.qrData,
                label: 'QR của liên kết công khai',
                subtitle: data.id,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Chọn môn để import',
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
                ? 'Đang import lịch...'
                : 'Import ${selectedSchedules.length} buổi học',
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
      await showAppPopup(
        context,
        title: 'Chưa đăng nhập',
        message: 'Bạn cần đăng nhập để import lịch vào tài khoản.',
        type: AppPopupType.error,
      );
      return;
    }
    if (schedules.isEmpty) {
      await showAppPopup(
        context,
        title: 'Chưa chọn dữ liệu',
        message: 'Hãy chọn ít nhất một buổi học để import.',
        type: AppPopupType.info,
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
      await showAppPopup(
        context,
        title: 'Import hoàn tất',
        message: imported == 0
            ? 'Không có buổi học mới nào được thêm vì dữ liệu đã tồn tại.'
            : 'Đã thêm $imported buổi học vào tài khoản của bạn.',
        type: AppPopupType.success,
      );
    } catch (error) {
      if (!mounted) return;
      await showAppPopup(
        context,
        title: 'Import thất bại',
        message: FirebaseErrorTranslator.readable(error),
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<void> _open() async {
    final normalized = ShareDebugService.validateShareInput(_controller.text);
    if (normalized == null || normalized.isEmpty) {
      await showAppPopup(
        context,
        title: 'Link không hợp lệ',
        message: 'Hãy nhập share ID hoặc link chia sẻ hợp lệ.',
        type: AppPopupType.error,
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
