import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../services/app_feedback_service.dart';
import '../services/share_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';
import '../widgets/syncing_state_card.dart';

class ManageSharedLinksScreen extends ConsumerStatefulWidget {
  const ManageSharedLinksScreen({super.key});

  @override
  ConsumerState<ManageSharedLinksScreen> createState() =>
      _ManageSharedLinksScreenState();
}

class _ManageSharedLinksScreenState
    extends ConsumerState<ManageSharedLinksScreen> {
  final Set<String> _busyIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final shares = ref.watch(mySharesProvider);
    final service = ref.watch(shareServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Liên kết đã chia sẻ')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: shares.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: SyncingStateCard(
                title: 'Đang tải liên kết',
                message: 'Các lịch đã chia sẻ sẽ được giữ ổn định khi làm mới.',
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: EmptyState(
                title: 'Không tải được danh sách',
                message: AppFeedbackService.messageFor(error),
                action: FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(mySharesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ),
            ),
            data: (data) {
              if (data.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: EmptyState(
                    title: 'Chưa có liên kết nào',
                    message:
                        'Khi bạn chia sẻ thời khóa biểu, liên kết sẽ xuất hiện tại đây để tiện quản lý.',
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const SectionHeader(
                    title: 'Quản lý lịch đã chia sẻ',
                    subtitle:
                        'Bật hoặc tắt liên kết, xem lại lịch và chia sẻ lại bất cứ lúc nào.',
                  ),
                  const SizedBox(height: 12),
                  for (final share in data)
                    _SharedLinkTile(
                      share: share,
                      busy: _busyIds.contains(share.id),
                      onOpen: () =>
                          context.push('/share/preview', extra: share),
                      onPublicView: service == null
                          ? null
                          : () => _runShareAction(
                              share.id,
                              () => service.openPublicLink(share.id),
                              successMessage: 'Đã mở liên kết chia sẻ.',
                            ),
                      onCopy: service == null
                          ? null
                          : () => _runShareAction(
                              share.id,
                              () => service.copyLink(share.publicUrl),
                              successMessage: 'Đã sao chép link.',
                            ),
                      onShare: service == null
                          ? null
                          : () => _runShareAction(
                              share.id,
                              () => service.shareLink(share),
                              successMessage: 'Đã mở bảng chia sẻ.',
                            ),
                      onToggle: service == null
                          ? null
                          : (value) => _runShareAction(
                              share.id,
                              () => service.setActive(share.id, value),
                              successMessage: value
                                  ? 'Liên kết đã được bật.'
                                  : 'Liên kết đã được tắt.',
                            ),
                      onDelete: service == null
                          ? null
                          : () => _confirmDelete(service, share),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    ShareService service,
    ShareScheduleModel share,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa liên kết chia sẻ?'),
        content: Text(
          'Liên kết của "${share.title}" sẽ ngừng hoạt động và không thể mở lại từ bên ngoài.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runShareAction(
      share.id,
      () => service.deleteShare(share.id),
      successMessage: 'Đã xóa liên kết chia sẻ.',
    );
  }

  Future<void> _runShareAction(
    String shareId,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _busyIds.add(shareId));
    final loading = AppFeedbackService.loading(
      context,
      'Đang cập nhật thay đổi…',
    );
    try {
      await action();
      loading.close();
      if (!mounted) return;
      AppFeedbackService.success(context, successMessage);
      ref.invalidate(mySharesProvider);
    } catch (error) {
      loading.close();
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(shareId));
      }
    }
  }
}

class _SharedLinkTile extends StatelessWidget {
  const _SharedLinkTile({
    required this.share,
    required this.busy,
    required this.onOpen,
    required this.onPublicView,
    required this.onCopy,
    required this.onShare,
    required this.onToggle,
    required this.onDelete,
  });

  final ShareScheduleModel share;
  final bool busy;
  final VoidCallback onOpen;
  final Future<void> Function()? onPublicView;
  final Future<void> Function()? onCopy;
  final Future<void> Function()? onShare;
  final ValueChanged<bool>? onToggle;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      share.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${share.schedulesSnapshot.length} buổi học • ${share.viewCount} lượt xem',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: share.isActive,
                onChanged: busy || onToggle == null ? null : onToggle,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: busy ? null : onOpen,
                icon: const Icon(Icons.remove_red_eye_rounded),
                label: const Text('Xem trước'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy || onPublicView == null
                    ? null
                    : () => onPublicView!(),
                icon: const Icon(Icons.public_rounded),
                label: const Text('Mở link'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy || onCopy == null ? null : () => onCopy!(),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Sao chép'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy || onShare == null ? null : () => onShare!(),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: const Text('Chia sẻ lại'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy || onDelete == null ? null : () => onDelete!(),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
