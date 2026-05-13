import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../models/share_schedule_model.dart';
import '../providers/pro_feature_providers.dart';
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

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(shareServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Preview chia sẻ')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Screenshot(
                controller: _controller,
                child: _SharePoster(share: widget.share),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: service == null
                    ? null
                    : () async {
                        final file = await service.captureShareImage(
                          controller: _controller,
                          filename: 'thoikhoabieu_${widget.share.id}',
                        );
                        await service.shareImage(file, text: widget.share.link);
                      },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share ảnh'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: service == null
                    ? null
                    : () => service.shareLink(widget.share),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Share link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharePoster extends StatelessWidget {
  const _SharePoster({required this.share});

  final ShareScheduleModel share;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.18),
            colorScheme.tertiary.withValues(alpha: 0.12),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: colorScheme.primary,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời Khoá Biểu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('Từ ${share.ownerName}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            share.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          for (final schedule in share.schedulesSnapshot.take(8))
            ShareScheduleCard(schedule: schedule, compact: true),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: QrShareBox(data: share.link, size: 86, label: 'Quét để xem'),
          ),
        ],
      ),
    );
  }
}
