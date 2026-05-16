import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/soft_gradient_background.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  final _friendFilterController = TextEditingController();
  String _friendFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    _friendFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final friends = ref.watch(friendsProvider);
    final requests = ref.watch(incomingFriendRequestsProvider);
    final searchResults = ref.watch(friendSearchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bạn bè')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              GlassCard(
                radius: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết nối cùng bạn bè học tập.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tìm bạn, gửi lời mời và chia sẻ nhịp học mỗi tuần trong một không gian thật gọn gàng.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText:
                            'Tìm theo tên, ID người dùng, ID hồ sơ hoặc email',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) =>
                          ref.read(friendSearchQueryProvider.notifier).state =
                              value,
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 16),
                      _QrProfileInvite(user: user),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                radius: AppRadius.lg,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _friendFilterController,
                  decoration: const InputDecoration(
                    labelText: 'Lọc bạn bè hiện có',
                    prefixIcon: Icon(Icons.filter_alt_rounded),
                  ),
                  onChanged: (value) => setState(() => _friendFilter = value),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Lời mời đến',
                subtitle: 'Chấp nhận để kết nối và cùng theo dõi lịch học.',
              ),
              const SizedBox(height: 12),
              requests.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const LoadingSkeleton(itemCount: 1),
                error: (error, _) => EmptyState(
                  title: 'Không tải được lời mời',
                  message: AppFeedbackService.messageFor(error),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      title: 'Chưa có lời mời nào',
                      message:
                          'Khi ai đó gửi lời mời kết bạn, bạn sẽ thấy tại đây.',
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (item) => _RequestTile(
                            key: ValueKey('friend-request-${item.id}'),
                            request: item,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Kết quả tìm kiếm',
                subtitle: 'Gửi lời mời chỉ với một chạm.',
              ),
              const SizedBox(height: 12),
              searchResults.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const LoadingSkeleton(itemCount: 2),
                error: (error, _) => EmptyState(
                  title: 'Không tìm thấy người dùng',
                  message: AppFeedbackService.messageFor(error),
                ),
                data: (items) {
                  if (_searchController.text.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  if (items.isEmpty) {
                    return const EmptyState(
                      title: 'Không có kết quả phù hợp',
                      message:
                          'Thử tìm bằng tên người dùng hoặc email đầy đủ hơn.',
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (item) => _SearchUserTile(
                            key: ValueKey('friend-search-${item.id}'),
                            user: item,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Bạn bè của bạn',
                subtitle: 'Theo dõi nhịp học và những môn đang học cùng nhau.',
              ),
              const SizedBox(height: 12),
              friends.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const LoadingSkeleton(itemCount: 2),
                error: (error, _) => EmptyState(
                  title: 'Không tải được danh sách bạn bè',
                  message: AppFeedbackService.messageFor(error),
                ),
                data: (items) {
                  final filtered = _filterFriends(items);
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      title: 'Chưa có bạn học nào',
                      message:
                          'Hãy gửi lời mời đầu tiên hoặc đổi bộ lọc để tiếp tục.',
                    );
                  }
                  return Column(
                    children: filtered
                        .map(
                          (item) => _FriendTile(
                            key: ValueKey('friend-${item.friendId}'),
                            friend: item,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FriendModel> _filterFriends(List<FriendModel> friends) {
    final query = _friendFilter.trim().toLowerCase();
    if (query.isEmpty) return friends;
    return friends
        .where((friend) {
          final profile = friend.friendIdProfile > 0
              ? friend.friendIdProfile.toString()
              : '';
          final haystack = [
            friend.friendName,
            friend.friendUsername ?? '',
            friend.friendIdUser ?? '',
            friend.friendId,
            profile,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QrProfileInvite extends ConsumerWidget {
  const _QrProfileInvite({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(friendServiceProvider);
    final publicId = user.idUser.isEmpty ? user.username : user.idUser;
    final link = service?.buildProfileShareLink(publicId) ?? publicId;
    return GlassCard(
      radius: 28,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: link,
              size: 82,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã kết nối của bạn',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (user.idUser.trim().isNotEmpty) '@${user.idUser}',
                    if (user.idProfile > 0) 'ID #${user.idProfile}',
                  ].join(' • '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({super.key, required this.request});

  final FriendRequestModel request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(
                name: request.fromName,
                primaryUrl: request.fromAvatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.fromName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      final service = ref.read(friendServiceProvider);
                      if (service == null) return;
                      await service.rejectRequest(request.id);
                      ref.invalidate(incomingFriendRequestsProvider);
                    } catch (error) {
                      if (!context.mounted) return;
                      AppFeedbackService.error(context, error);
                    }
                  },
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    try {
                      final service = ref.read(friendServiceProvider);
                      final currentUser = ref.read(appUserProvider).valueOrNull;
                      final schedules =
                          ref.read(schedulesProvider).valueOrNull ?? const [];
                      if (service == null || currentUser == null) return;
                      await service.acceptRequest(
                        request: request,
                        currentUser: currentUser,
                        schedules: schedules,
                      );
                      ref.invalidate(incomingFriendRequestsProvider);
                      ref.invalidate(friendsProvider);
                    } catch (error) {
                      if (!context.mounted) return;
                      AppFeedbackService.error(context, error);
                    }
                  },
                  child: const Text('Chấp nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchUserTile extends ConsumerWidget {
  const _SearchUserTile({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AppAvatar(name: user.name, primaryUrl: user.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(user.username),
              ],
            ),
          ),
          AnimatedButton(
            onTap: () async {
              await _sendRequest(context, ref);
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.14),
              ),
              child: Text(
                'Kết bạn',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(friendServiceProvider);
      final current = ref.read(appUserProvider).valueOrNull;
      if (service == null || current == null) return;
      await service.sendFriendRequest(fromUser: current, toUser: user);
      if (context.mounted) {
        AppFeedbackService.success(context, 'Đã gửi lời mời kết bạn');
      }
    } catch (error) {
      if (!context.mounted) return;
      AppFeedbackService.error(context, error);
    }
  }
}

class _FriendTile extends ConsumerWidget {
  const _FriendTile({super.key, required this.friend});

  final FriendModel friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Stack(
            children: [
              AppAvatar(
                name: friend.friendName,
                primaryUrl: friend.friendAvatarUrl,
                radius: 26,
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: friend.online
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.friendName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  [
                    if ((friend.friendIdUser ?? friend.friendUsername ?? '')
                        .trim()
                        .isNotEmpty)
                      '@${(friend.friendIdUser ?? friend.friendUsername)!}',
                    if (friend.friendIdProfile > 0)
                      'ID #${friend.friendIdProfile}',
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${friend.studyStreak} ngày liên tục • ${friend.weeklyHours.toStringAsFixed(1)} giờ/tuần',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (friend.sharedSubjects.isNotEmpty)
                  Text(
                    'Môn học chung: ${friend.sharedSubjects.take(3).join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              try {
                final service = ref.read(friendServiceProvider);
                if (service == null) return;
                await service.removeFriend(friend.friendId);
              } catch (error) {
                if (!context.mounted) return;
                AppFeedbackService.error(context, error);
              }
            },
            icon: const Icon(Icons.person_remove_alt_1_rounded),
          ),
        ],
      ),
    );
  }
}
