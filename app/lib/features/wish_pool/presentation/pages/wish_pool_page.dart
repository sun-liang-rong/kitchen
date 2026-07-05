import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../domain/models/kitchen_models.dart';
import '../providers/wish_pool_controller.dart';

class WishPoolPage extends ConsumerWidget {
  const WishPoolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishPoolControllerProvider);
    final controller = ref.read(wishPoolControllerProvider.notifier);
    final session = ref.watch(sessionControllerProvider).valueOrNull;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: 'pool'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            WarmTopBar(
              title: '厨房许愿池',
              subtitle: '想吃什么先许愿，谁有空谁来实现。',
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceHigh,
                child:
                    Icon(Icons.restaurant, size: 15, color: AppColors.primary),
              ),
              actions: const [NotificationBell(color: AppColors.primary)],
              centerTitle: true,
            ),
            const SizedBox(height: 12),
            _TodayFocusCard(
              partnerName:
                  session?.binding.partner?.nickname ?? state.partner.nickname,
              state: state,
              onManage: () => _showUnbindSheet(context, ref),
            ),
            const SizedBox(height: 14),
            _KitchenStatusRow(state: state, controller: controller),
            const SizedBox(height: 18),
            _StatusFilter(state: state, controller: controller),
            const SizedBox(height: 14),
            if (state.visibleWishes.isEmpty)
              const _EmptyState()
            else
              for (final wish in state.visibleWishes) ...[
                _WishCard(wish: wish, state: state, controller: controller),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({
    required this.partnerName,
    required this.state,
    required this.onManage,
  });

  final String partnerName;
  final WishPoolState state;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final waitingCount = state.wishes
        .where((wish) =>
            wish.creatorId != state.me.id && wish.status == WishStatus.inPool)
        .length;
    final confirmCount = state.wishes
        .where((wish) => wish.status == WishStatus.pendingConfirmation)
        .length;
    final fulfilledCount = state.wishes
        .where((wish) => wish.status == WishStatus.fulfilled)
        .length;
    final focusWish = state.wishes
            .where((wish) =>
                wish.creatorId != state.me.id &&
                wish.status != WishStatus.fulfilled)
            .cast<Wish?>()
            .firstOrNull ??
        state.wishes
            .where((wish) => wish.status != WishStatus.fulfilled)
            .cast<Wish?>()
            .firstOrNull;
    final partnerStatus =
        _kitchenStatusText(state.kitchenStatuses[state.partner.id]?.status);
    final focusTitle = focusWish == null ? '今晚先许一个小愿望' : focusWish.title;
    final focusLine = focusWish == null
        ? '你和$partnerName还没有新的饭点想法。'
        : '${_wishOwnerText(focusWish, state)}${focusWish.intensity}，希望${focusWish.desiredTime}。';

    return SoftCard(
      color: AppColors.surface,
      padding: EdgeInsets.zero,
      onTap: focusWish == null
          ? null
          : () => context.push('/wish/${focusWish.id}'),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 24,
            child: Icon(
              Icons.local_fire_department_outlined,
              color: AppColors.primary.withValues(alpha: 0.28),
              size: 54,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SoftChip(
                      label: '今天的饭点',
                      icon: Icons.wb_twilight_outlined,
                      selected: true,
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: '管理绑定',
                      onPressed: onManage,
                      icon: const Icon(Icons.manage_accounts_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  focusTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  focusLine,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PoolPill(
                      value: waitingCount,
                      label: '等你接住',
                      icon: Icons.favorite_border,
                    ),
                    _PoolPill(
                      value: confirmCount,
                      label: '等点头',
                      icon: Icons.forum_outlined,
                    ),
                    _PoolPill(
                      value: fulfilledCount,
                      label: '已吃到',
                      icon: Icons.local_dining_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.44)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.soup_kitchen_outlined,
                          size: 18, color: AppColors.sage),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$partnerName今天：$partnerStatus',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolPill extends StatelessWidget {
  const _PoolPill({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryDeep),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

void _showUnbindSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('管理绑定', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '解绑后不会删除历史愿望和兑现记录，但新的许愿池不会继续共享。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(sessionControllerProvider.notifier).unbind();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.link_off),
                label: const Text('解除绑定'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _KitchenStatusRow extends StatelessWidget {
  const _KitchenStatusRow({required this.state, required this.controller});

  final WishPoolState state;
  final WishPoolController controller;

  @override
  Widget build(BuildContext context) {
    final partnerPronoun = thirdPersonPronoun(state.partner.gender);
    return Row(
      children: [
        for (final user in state.users) ...[
          Expanded(
            child: SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              onTap: user.isMe
                  ? () => _showKitchenStatusSheet(context, controller, user.id)
                  : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: user.isMe
                        ? AppColors.surfaceLow
                        : AppColors.surfaceContainer,
                    child: Icon(
                      user.isMe
                          ? Icons.rice_bowl_outlined
                          : Icons.soup_kitchen_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isMe ? '我的' : '$partnerPronoun的',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          _kitchenStatusText(
                              state.kitchenStatuses[user.id]?.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user != state.users.last) const SizedBox(width: 12),
        ],
      ],
    );
  }

  void _showKitchenStatusSheet(
    BuildContext context,
    WishPoolController controller,
    String userId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              Text('设置我的厨房状态', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in KitchenStatusValue.values)
                    SoftChip(
                      label: _kitchenStatusText(status),
                      icon: Icons.local_dining,
                      dense: false,
                      onTap: () {
                        controller.setKitchenStatus(
                          userId,
                          status,
                          note: _kitchenStatusHint(status),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.state, required this.controller});

  final WishPoolState state;
  final WishPoolController controller;

  @override
  Widget build(BuildContext context) {
    final filters = <WishStatus?, String>{
      null: '全部',
      WishStatus.inPool: '池中',
      WishStatus.pendingConfirmation: '待确认',
      WishStatus.claimed: '已认领',
      WishStatus.deferred: '改天',
      WishStatus.shelved: '先搁着',
      WishStatus.fulfilled: '已兑现',
    };
    final partnerPronoun = thirdPersonPronoun(state.partner.gender);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SoftChip(
            label: '所有人',
            selected: state.creatorFilter == WishCreatorFilter.all,
            onTap: () => controller.selectCreator(WishCreatorFilter.all),
          ),
          const SizedBox(width: 8),
          SoftChip(
            label: '$partnerPronoun许的',
            selected: state.creatorFilter == WishCreatorFilter.partner,
            onTap: () => controller.selectCreator(WishCreatorFilter.partner),
          ),
          const SizedBox(width: 8),
          SoftChip(
            label: '我许的',
            selected: state.creatorFilter == WishCreatorFilter.me,
            onTap: () => controller.selectCreator(WishCreatorFilter.me),
          ),
          const SizedBox(width: 8),
          for (final entry in filters.entries) ...[
            SoftChip(
              label: entry.value,
              selected: state.selectedStatus == entry.key,
              onTap: () => controller.selectStatus(entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _WishCard extends StatelessWidget {
  const _WishCard({
    required this.wish,
    required this.state,
    required this.controller,
  });

  final Wish wish;
  final WishPoolState state;
  final WishPoolController controller;

  @override
  Widget build(BuildContext context) {
    final creator = state.users.firstWhere((user) => user.id == wish.creatorId);
    final response = wish.currentResponse;
    final creatorPronoun =
        creator.isMe ? '我' : thirdPersonPronoun(creator.gender);
    final responderPronoun =
        creator.isMe ? thirdPersonPronoun(state.partner.gender) : '你';
    final isMine = creator.isMe;

    return SoftCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/wish/${wish.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Stack(
                  children: [
                    FoodImageTile(title: wish.title, height: 86),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: SoftChip(
                          label: _wishStatusText(wish.status), dense: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$creatorPronoun许的',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      wish.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      response == null
                          ? '还没人回应，适合现在接住。'
                          : '$responderPronoun回应：${_responseText(response)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              SoftChip(label: wish.intensity),
              SoftChip(label: '希望${wish.desiredTime}'),
              if (wish.helperTasks.isNotEmpty)
                SoftChip(label: '愿意${wish.helperTasks.first}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isMine ? Icons.favorite_border : Icons.pan_tool_alt_outlined,
                color: AppColors.primaryDeep,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isMine ? '这是你放进池子里的愿望' : '可以回应、换个版本，或者约个一起做的时间',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
              FilledButton(
                onPressed: wish.status == WishStatus.fulfilled || isMine
                    ? null
                    : () => _handlePrimaryAction(context, wish, controller),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(82, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(isMine ? '我的愿望' : _primaryActionText(wish.status)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePrimaryAction(
    BuildContext context,
    Wish wish,
    WishPoolController controller,
  ) {
    if (wish.status == WishStatus.claimed ||
        wish.status == WishStatus.deferred ||
        wish.status == WishStatus.together) {
      context.push('/wish/${wish.id}');
      return;
    }
    if (wish.status == WishStatus.pendingConfirmation) {
      context.push('/wish/${wish.id}');
      return;
    }
    context.push('/wish/${wish.id}');
  }

  String _primaryActionText(WishStatus status) {
    return switch (status) {
      WishStatus.inPool => '我接住',
      WishStatus.pendingConfirmation => '等点头',
      WishStatus.claimed || WishStatus.deferred || WishStatus.together => '吃完啦',
      WishStatus.shelved => '再商量',
      WishStatus.fulfilled => '已吃到',
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          '这个筛选下还没有愿望',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

String _wishOwnerText(Wish wish, WishPoolState state) {
  final creator = state.users.firstWhere((user) => user.id == wish.creatorId);
  final pronoun = creator.isMe ? '你' : thirdPersonPronoun(creator.gender);
  return '$pronoun说';
}

String _wishStatusText(WishStatus status) {
  return switch (status) {
    WishStatus.inPool => '池中',
    WishStatus.pendingConfirmation => '待确认',
    WishStatus.claimed => '已认领',
    WishStatus.deferred => '改天',
    WishStatus.together => '一起做',
    WishStatus.shelved => '先搁着',
    WishStatus.fulfilled => '已兑现',
  };
}

String _responseText(WishResponse response) {
  return switch (response.type) {
    WishResponseType.fulfillTonight => '今晚实现',
    WishResponseType.lightVersion => '做轻松版',
    WishResponseType.alternative => '换个版本',
    WishResponseType.defer => '周末安排',
    WishResponseType.together => '一起做',
    WishResponseType.shelve => '先搁着',
  };
}

String _kitchenStatusText(KitchenStatusValue? status) {
  return switch (status) {
    KitchenStatusValue.seriousCook => '想认真做一顿',
    KitchenStatusValue.normal => '今天正常',
    KitchenStatusValue.tired => '有点累',
    KitchenStatusValue.simpleOnly => '只想简单吃',
    KitchenStatusValue.noCooking => '不想开火',
    KitchenStatusValue.cookTogether => '适合一起做',
    null => '未设置',
  };
}

String _kitchenStatusHint(KitchenStatusValue status) {
  return switch (status) {
    KitchenStatusValue.seriousCook => '今天可以认真安排一顿',
    KitchenStatusValue.normal => '正常发挥就很好',
    KitchenStatusValue.tired => '今天适合快手菜或一起完成',
    KitchenStatusValue.simpleOnly => '简单吃也可以',
    KitchenStatusValue.noCooking => '今天可以外食或不动锅',
    KitchenStatusValue.cookTogether => '适合两个人一起做',
  };
}
