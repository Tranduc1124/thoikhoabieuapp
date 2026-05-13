import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pro_feature_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class ManageSharedLinksScreen extends ConsumerWidget {
  const ManageSharedLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shares = ref.watch(mySharesProvider);
    final service = ref.watch(shareServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Link đã chia sẻ')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: shares.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingSkeleton(itemCount: 4),
            ),
            error: (error, _) => EmptyState(
              title: 'Không tải được link',
              message: error.toString(),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  title: 'Chưa có link chia sẻ',
                  message: 'Tạo link từ màn Chia sẻ lịch để quản lý tại đây.',
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  const SectionHeader(
                    title: 'Các lịch đã chia sẻ',
                    subtitle: 'Có thể tắt hoặc xoá public link bất cứ lúc nào',
                  ),
                  const SizedBox(height: 16),
                  for (final share in items)
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  share.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              Switch(
                                value: share.isActive,
                                onChanged: service == null
                                    ? null
                                    : (value) =>
                                          service.setActive(share.id, value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${share.schedulesSnapshot.length} môn • ${share.viewCount} lượt xem',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: service == null
                                      ? null
                                      : () => service.shareLink(share),
                                  icon: const Icon(Icons.ios_share_rounded),
                                  label: const Text('Share'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.filledTonal(
                                onPressed: service == null
                                    ? null
                                    : () => service.deleteShare(share.id),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ],
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
}
