import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../providers/notifications_controller.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const KitchenIllustrationBackground(),
            state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _NotificationScaffold(
                children: const [
                  MagazineEmptyState(
                    title: '通知暂时加载不了',
                    message: '稍后再翻开这页看看。',
                    icon: Icons.notifications_off_outlined,
                  ),
                ],
              ),
              data: (data) => _NotificationScaffold(
                unreadCount: data.unreadCount,
                onMarkAllRead: data.unreadCount == 0
                    ? null
                    : () => ref
                        .read(notificationsControllerProvider.notifier)
                        .markAllRead(),
                children: [
                  if (data.items.isEmpty)
                    const MagazineEmptyState(
                      title: '还没有通知',
                      message: '有新的回应、确认或兑现时，这里会亮起来。',
                      icon: Icons.notifications_none_rounded,
                    )
                  else
                    for (final item in data.items) ...[
                      SoftCard(
                        radius: AppRadius.xl,
                        borderColor:
                            item.isUnread ? AppColors.primaryContainer : null,
                        padding: const EdgeInsets.all(14),
                        onTap: () async {
                          if (item.isUnread) {
                            await ref
                                .read(notificationsControllerProvider.notifier)
                                .markRead(item.id);
                          }
                          if (!context.mounted) {
                            return;
                          }
                          final relatedId = item.relatedId;
                          if (relatedId != null && relatedId.isNotEmpty) {
                            context.push('/wish/$relatedId');
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: item.isUnread
                                  ? AppColors.surfaceContainer
                                  : AppColors.surfaceLow,
                              child: Icon(_iconForType(item.type),
                                  color: AppColors.primary, size: 19),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      if (item.isUnread)
                                        const SoftChip(
                                            label: '未读', selected: true),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item.content,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'WISH_RESPONDED' => Icons.forum_outlined,
      'WISH_CLAIMED' => Icons.check_circle_outline,
      'WISH_FULFILLED' => Icons.local_dining,
      _ => Icons.notifications_none,
    };
  }
}

class _NotificationScaffold extends StatelessWidget {
  const _NotificationScaffold({
    required this.children,
    this.unreadCount = 0,
    this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback? onMarkAllRead;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        MagazineHeader(
          title: '通知',
          kicker: 'Inbox',
          subtitle: unreadCount == 0 ? '没有未读通知。' : '有 $unreadCount 条通知等你看。',
          leadingIcon: Icons.notifications_none_rounded,
          actions: [
            IconButton(
              tooltip: '返回',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text('全部已读'),
            ),
          ],
          center: true,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
