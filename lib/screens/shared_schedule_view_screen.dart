import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pro_feature_providers.dart';
import '../widgets/empty_state.dart';
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

  @override
  void initState() {
    super.initState();
    _shareId = widget.shareId;
    _controller.text = widget.shareId ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shareId = _shareId;
    final share = shareId == null
        ? null
        : ref.watch(publicShareProvider(shareId));
    return Scaffold(
      appBar: AppBar(title: const Text('Xem lịch chia sẻ')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const SectionHeader(
                title: 'Nhập link hoặc mã chia sẻ',
                subtitle: 'Chỉ xem snapshot public, không thể chỉnh sửa',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Share ID hoặc link',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: _open,
                  ),
                ),
                onSubmitted: (_) => _open(),
              ),
              const SizedBox(height: 18),
              if (share == null)
                const EmptyState(
                  title: 'Chưa mở lịch nào',
                  message:
                      'Dán link hoặc shareId để xem lịch ở chế độ chỉ đọc.',
                )
              else
                share.when(
                  loading: () => const LoadingSkeleton(itemCount: 3),
                  error: (error, _) => EmptyState(
                    title: 'Không mở được lịch',
                    message: error.toString(),
                  ),
                  data: (data) {
                    if (data == null) {
                      return const EmptyState(
                        title: 'Không tìm thấy lịch',
                        message: 'ShareId không tồn tại hoặc đã bị xoá.',
                      );
                    }
                    if (!data.isActive) {
                      return const EmptyState(
                        title: 'Link đã tắt',
                        message: 'Chủ sở hữu đã tắt lịch chia sẻ này.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: data.title,
                          subtitle: 'Từ ${data.ownerName}',
                        ),
                        const SizedBox(height: 14),
                        for (final schedule in data.schedulesSnapshot)
                          ShareScheduleCard(schedule: schedule),
                        const SizedBox(height: 12),
                        QrShareBox(data: data.link, label: data.id),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _open() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _shareId = raw.contains('/') ? raw.split('/').last : raw;
    });
  }
}
