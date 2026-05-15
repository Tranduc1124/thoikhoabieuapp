import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pro_feature_providers.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/qr_share_box.dart';
import '../widgets/soft_gradient_background.dart';

class PublicProfileCardScreen extends ConsumerWidget {
  const PublicProfileCardScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(publicProfileCardProvider(cardId));
    return Scaffold(
      appBar: AppBar(title: const Text('Thẻ hồ sơ')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: card.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                title: 'Không mở được thẻ hồ sơ',
                message: AppFeedbackService.messageFor(error),
              ),
              data: (data) {
                if (data == null) {
                  return const EmptyState(
                    title: 'Không tìm thấy thẻ hồ sơ',
                    message:
                        'Thẻ hồ sơ này có thể đã bị xoá hoặc không còn hoạt động.',
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surfaceContainer,
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.glassStroke,
                    ),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            name: data.displayName,
                            primaryUrl: data.avatarUrl,
                            radius: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                Text(data.username),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (data.bio.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(data.bio),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Môn yêu thích: ${data.favoriteSubject.isEmpty ? 'Chưa đặt' : data.favoriteSubject}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      QrShareBox(
                        data:
                            data.qrLink ?? 'thoikhoabieu://profile/${data.id}',
                        label: 'Quét để mở hồ sơ',
                        subtitle: '${data.studyStreak} ngày học liên tục',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
