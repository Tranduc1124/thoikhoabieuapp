import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';

import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../services/app_feedback_service.dart';
import '../services/share_debug_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/qr_share_box.dart';
import '../widgets/share_schedule_card.dart';
import '../widgets/soft_gradient_background.dart';

class SharePreviewScreen extends ConsumerStatefulWidget {
  const SharePreviewScreen({super.key, required this.share});

  final ShareScheduleModel share;

  @override
  ConsumerState<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends ConsumerState<SharePreviewScreen> {
  final _controller = ScreenshotController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final service = ref.watch(shareServiceProvider);
    final qrValid = ShareDebugService.validateQrPayload(widget.share.qrData);

    return Scaffold(
      appBar: AppBar(title: const Text('Xem trước chia sẻ')),
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
                      'Mọi thứ đã sẵn sàng để gửi đi.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn có thể chia sẻ bằng đường dẫn, mã QR hoặc lưu lại thành ảnh thật gọn gàng.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _PreviewPill(
                          icon: Icons.verified_rounded,
                          label: qrValid
                              ? 'Mã QR sẵn sàng'
                              : 'Kiểm tra lại mã QR',
                          color: qrValid
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                        _PreviewPill(
                          icon: Icons.visibility_rounded,
                          label: '${widget.share.viewCount} lượt xem',
                          color: colorScheme.primary,
                        ),
                        _PreviewPill(
                          icon: Icons.public_rounded,
                          label: 'Link web thật',
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Screenshot(
                controller: _controller,
                child: _SharePoster(share: widget.share),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ShareActionButton(
                    child: FilledButton.icon(
                      onPressed: _busy || service == null ? null : _shareLink,
                      icon: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: _busy
                            ? const SizedBox.square(
                                key: ValueKey('share-busy'),
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.ios_share_rounded,
                                key: ValueKey('share-ready'),
                              ),
                      ),
                      label: const Text('Chia sẻ ngay'),
                    ),
                  ),
                  _ShareActionButton(
                    child: OutlinedButton.icon(
                      onPressed: _busy || service == null ? null : _copyLink,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Sao chép link'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ShareActionButton(
                    child: OutlinedButton.icon(
                      onPressed: _busy || service == null ? null : _shareImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Chia sẻ ảnh'),
                    ),
                  ),
                  _ShareActionButton(
                    child: OutlinedButton.icon(
                      onPressed: _busy || service == null ? null : _saveImage,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Lưu ảnh'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ShareActionButton(
                    child: OutlinedButton.icon(
                      onPressed: _busy || service == null ? null : _openWebLink,
                      icon: const Icon(Icons.public_rounded),
                      label: const Text('Mở liên kết'),
                    ),
                  ),
                  _ShareActionButton(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/shared-links'),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Quản lý chia sẻ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    final service = ref.read(shareServiceProvider);
    if (service == null) return;
    await _runBusyTask(() async {
      final file = await service.captureShareImage(
        controller: _controller,
        filename: 'thoikhoabieu_${widget.share.id}',
      );
      await service.shareImage(file, text: widget.share.publicUrl);
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã mở bảng chia sẻ.');
    });
  }

  Future<void> _shareLink() async {
    final service = ref.read(shareServiceProvider);
    if (service == null) return;
    await _runBusyTask(() async {
      await service.shareLink(widget.share);
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã mở bảng chia sẻ.');
    });
  }

  Future<void> _copyLink() async {
    final service = ref.read(shareServiceProvider);
    if (service == null) return;
    try {
      await service.copyLink(widget.share.publicUrl);
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã sao chép link.');
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    }
  }

  Future<void> _saveImage() async {
    final service = ref.read(shareServiceProvider);
    if (service == null) return;
    await _runBusyTask(() async {
      await service.saveShareImage(
        controller: _controller,
        filename: 'thoikhoabieu_poster_${widget.share.id}',
      );
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã lưu ảnh vào Photos/Gallery.');
    });
  }

  Future<void> _openWebLink() async {
    final service = ref.read(shareServiceProvider);
    if (service == null) return;
    try {
      await service.openPublicLink(widget.share.id);
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã mở liên kết chia sẻ.');
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    }
  }

  Future<void> _runBusyTask(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _ShareActionButton extends StatelessWidget {
  const _ShareActionButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = width - 40;
    final itemWidth = contentWidth >= 390
        ? (contentWidth - 10) / 2
        : contentWidth;
    return SizedBox(width: itemWidth, child: child);
  }
}

class _SharePoster extends StatelessWidget {
  const _SharePoster({required this.share});

  final ShareScheduleModel share;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ScheduleFadeWidget(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainer.withValues(alpha: 0.96),
              colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(color: colorScheme.glassStroke),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.16),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _OwnerAvatar(photoUrl: share.profilePhoto),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Từ ${share.ownerName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            QrShareBox(
              data: share.publicUrl,
              label: 'Quét để xem hoặc thêm vào lịch của bạn',
              subtitle: share.id,
            ),
            const SizedBox(height: 18),
            for (final schedule in share.schedulesSnapshot.take(8))
              ShareScheduleCard(schedule: schedule, compact: true),
            if (share.schedulesSnapshot.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${share.schedulesSnapshot.length - 8} buổi học khác',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  const _OwnerAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = photoUrl != null && photoUrl!.trim().isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              photoUrl!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _AvatarFallback(),
            ),
          )
        : const _AvatarFallback();

    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
      ),
      child: child,
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: const Icon(Icons.person_rounded),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

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
          Icon(icon, size: 16, color: color),
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
