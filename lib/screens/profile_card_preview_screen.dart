import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../models/profile_card_model.dart';
import '../providers/pro_feature_providers.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/qr_share_box.dart';
import '../widgets/soft_gradient_background.dart';

class ProfileCardPreviewScreen extends ConsumerStatefulWidget {
  const ProfileCardPreviewScreen({super.key, required this.card});

  final ProfileCardModel card;

  @override
  ConsumerState<ProfileCardPreviewScreen> createState() =>
      _ProfileCardPreviewScreenState();
}

class _ProfileCardPreviewScreenState
    extends ConsumerState<ProfileCardPreviewScreen> {
  final _controller = ScreenshotController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final shareService = ref.watch(shareServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Card')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Screenshot(
                controller: _controller,
                child: _ProfilePoster(card: widget.card),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _busy || shareService == null ? null : _shareImage,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: const Text('Share profile card'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    final shareService = ref.read(shareServiceProvider);
    if (shareService == null) return;
    setState(() => _busy = true);
    try {
      final file = await shareService.captureShareImage(
        controller: _controller,
        filename: 'profile_card_${widget.card.id}',
      );
      await shareService.shareImage(file, text: widget.card.qrLink);
      if (!mounted) return;
      AppFeedbackService.success(context, 'Đã mở bảng chia sẻ');
    } catch (error) {
      if (!mounted) return;
      AppFeedbackService.error(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ProfilePoster extends StatelessWidget {
  const _ProfilePoster({required this.card});

  final ProfileCardModel card;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainer.withValues(alpha: 0.96),
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
            colorScheme.primary.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: colorScheme.glassStroke),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: card.displayName,
                primaryUrl: card.avatarUrl,
                radius: 34,
                iconSize: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(card.username),
                  ],
                ),
              ),
            ],
          ),
          if (card.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(card.bio, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(label: 'Streak', value: '${card.studyStreak}d'),
              const SizedBox(width: 10),
              _Metric(
                label: 'Hours',
                value: card.weeklyHours.toStringAsFixed(1),
              ),
              const SizedBox(width: 10),
              _Metric(label: 'Classes', value: '${card.totalClasses}'),
            ],
          ),
          const SizedBox(height: 18),
          if (card.favoriteSubject.isNotEmpty)
            Text(
              'Môn yêu thích: ${card.favoriteSubject}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          const SizedBox(height: 16),
          QrShareBox(
            data: card.qrLink ?? 'thoikhoabieu://profile/${card.id}',
            label: 'Quét để mở profile',
            subtitle: 'make by minhduc',
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Theme.of(context).colorScheme.tileSurface,
          border: Border.all(
            color: Theme.of(context).colorScheme.glassStrokeSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
