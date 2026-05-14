import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../services/firebase_error_translator.dart';
import '../services/share_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_popup.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

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
      appBar: AppBar(title: const Text('Các link đã chia sẻ')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: shares.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingSkeleton(itemCount: 4),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: EmptyState(
                title: 'Không tải được danh sách link',
                message: FirebaseErrorTranslator.readable(error),
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
                    title: 'Chưa có link nào',
                    message:
                        'Khi bạn tạo chia sẻ, link public sẽ xuất hiện tại đây để quản lý.',
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const SectionHeader(
                    title: 'Quản lý snapshot đã chia sẻ',
                    subtitle:
                        'Bật/tắt link, mở preview lại hoặc gửi share sheet từ cùng một nơi.',
                  ),
                  const SizedBox(height: 12),
                  for (final share in data)
                    _SharedLinkTile(
                      share: share,
                      busy: _busyIds.contains(share.id),
                      onOpen: () =>
                          context.push('/share/preview', extra: share),
                      onPublicView: () => context.push('/shared/${share.id}'),
                      onShare: service == null
                          ? null
                          : () => _runShareAction(
                              share.id,
                              () => service.shareLink(share),
                              successTitle: 'Đã mở share sheet',
                              successMessage:
                                  'Link công khai đã được gửi vào hệ thống chia sẻ.',
                            ),
                      onToggle: service == null
                          ? null
                          : (value) => _runShareAction(
                              share.id,
                              () => service.setActive(share.id, value),
                              successTitle: value
                                  ? 'Đã bật link'
                                  : 'Đã tắt link',
                              successMessage: value
                                  ? 'Người khác có thể mở snapshot này trở lại.'
                                  : 'Người khác sẽ không mở được snapshot này nữa.',
                            ),
                      onDelete: service == null
                          ? null
                          : () => _confirmDelete(service, share),
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'make by minhduc',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ShareService service, ShareScheduleModel share) {
    return showAppPopup(
      context,
      title: 'Xóa link chia sẻ',
      message:
          'Link ${share.title} sẽ bị xóa khỏi Firebase và không thể mở lại bằng QR hay deep link.',
      type: AppPopupType.error,
      primaryLabel: 'Xóa',
      onPrimary: () {
        _runShareAction(
          share.id,
          () => service.deleteShare(share.id),
          successTitle: 'Đã xóa link',
          successMessage: 'Link chia sẻ đã bị gỡ khỏi danh sách public.',
        );
      },
    );
  }

  Future<void> _runShareAction(
    String shareId,
    Future<void> Function() action, {
    required String successTitle,
    required String successMessage,
  }) async {
    setState(() => _busyIds.add(shareId));
    try {
      await action();
      if (!mounted) return;
      await showAppPopup(
        context,
        title: successTitle,
        message: successMessage,
        type: AppPopupType.success,
      );
      ref.invalidate(mySharesProvider);
    } catch (error) {
      if (!mounted) return;
      await showAppPopup(
        context,
        title: 'Không thể hoàn tất thao tác',
        message: FirebaseErrorTranslator.readable(error),
        type: AppPopupType.error,
      );
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
    required this.onShare,
    required this.onToggle,
    required this.onDelete,
  });

  final ShareScheduleModel share;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onPublicView;
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
                label: const Text('Preview'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy ? null : onPublicView,
                icon: const Icon(Icons.public_rounded),
                label: const Text('Public'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy || onShare == null ? null : () => onShare!(),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: const Text('Share'),
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
