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
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _NotificationScaffold(
            children: const [
              SoftCard(
                padding: EdgeInsets.symmetric(vertical: 42),
                child: Center(child: Text('通知暂时加载不了')),
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
                const SoftCard(
                  padding: EdgeInsets.symmetric(vertical: 42),
                  child: Center(child: Text('还没有通知')),
                )
              else
                for (final item in data.items) ...[
                  SoftCard(
                    borderColor:
                        item.isUnread ? AppColors.primaryContainer : null,
                    padding: const EdgeInsets.all(14),
                    onTap: item.isUnread
                        ? () => ref
                            .read(notificationsControllerProvider.notifier)
                            .markRead(item.id)
                        : null,
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
                                    const SoftChip(label: '未读', selected: true),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(item.content,
                                  style: Theme.of(context).textTheme.bodySmall),
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
        WarmTopBar(
          title: '通知',
          subtitle: unreadCount == 0 ? '没有未读通知。' : '有 $unreadCount 条通知等你看。',
          leading: IconButton(
            tooltip: '返回',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text('全部已读'),
            ),
          ],
          centerTitle: true,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
