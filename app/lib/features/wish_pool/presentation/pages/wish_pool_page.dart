import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../spirit/presentation/widgets/spirit_overlay_scaffold.dart';
import '../../domain/models/kitchen_models.dart';
import '../providers/wish_pool_controller.dart';

class WishPoolPage extends ConsumerStatefulWidget {
  const WishPoolPage({super.key});

  @override
  ConsumerState<WishPoolPage> createState() => _WishPoolPageState();
}

class _WishPoolPageState extends ConsumerState<WishPoolPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(wishPoolControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message != previous?.errorMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishPoolControllerProvider);
    final controller = ref.read(wishPoolControllerProvider.notifier);
    final session = ref.watch(sessionControllerProvider).valueOrNull;

    return SpiritOverlayScaffold(
      child: MagazineScaffold(
        bottomNavigationBar: const AppBottomNav(current: 'pool'),
        children: [
          MagazineHeader(
            title: '厨房许愿池',
            kicker: 'Today Menu',
            subtitle: '想吃什么先许愿，谁有空谁来实现。',
            leadingIcon: Icons.flatware_rounded,
            actions: const [NotificationBell(color: AppColors.primary)],
            center: true,
          ),
          const SizedBox(height: 8),
          _TodayFocusCard(
            partnerName:
                session?.binding.partner?.nickname ?? state.partner.nickname,
            state: state,
            onManage: () => _showUnbindSheet(context, ref),
          ),
          const SizedBox(height: 24),
          const MagazineSectionTitle(
            title: '两个人的厨房状态',
            subtitle: '先看今天适不适合开火。',
          ),
          _KitchenStatusRow(state: state, controller: controller),
          const SizedBox(height: 24),
          const MagazineSectionTitle(
            title: '愿望流',
            subtitle: '翻一翻今天池子里的小念头。',
          ),
          _StatusFilter(state: state, controller: controller),
          const SizedBox(height: 24),
          if (state.isLoading && state.wishes.isEmpty)
            const _LoadingState()
          else if (state.errorMessage != null && state.wishes.isEmpty)
            _ErrorState(
              message: state.errorMessage!,
              onRetry: controller.retry,
            )
          else if (state.visibleWishes.isEmpty)
            _EmptyState(
              hasAnyWish: state.wishes.isNotEmpty,
              onCreateWish: () => context.push('/wish/new'),
            )
          else
            for (var i = 0; i < state.visibleWishes.length; i++) ...[
              _StaggeredEntry(
                index: i,
                child: _WishCard(
                  wish: state.visibleWishes[i],
                  state: state,
                  controller: controller,
                ),
              ),
              const SizedBox(height: 14),
            ],
          if (state.isRefreshing) ...[
            const SizedBox(height: 8),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
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

    return MagazineCoverCard(
      label: '今天的饭点',
      icon: Icons.wb_twilight_rounded,
      onTap: focusWish == null
          ? null
          : () => context.push('/wish/${focusWish.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton.filledTonal(
                tooltip: '管理绑定',
                onPressed: onManage,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  foregroundColor: AppColors.primaryDeep,
                ),
                icon: const Icon(Icons.manage_accounts_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            focusTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            focusLine,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PoolPill(
                  value: waitingCount,
                  label: '等你接住',
                  icon: Icons.favorite_border_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PoolPill(
                  value: confirmCount,
                  label: '等点头',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PoolPill(
                  value: fulfilledCount,
                  label: '已吃到',
                  icon: Icons.local_dining_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.mine.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.66),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.soup_kitchen_outlined,
                    size: 16,
                    color: AppColors.primaryDeep,
                  ),
                ),
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
    );
  }
}

class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + index.clamp(0, 5) * 55),
      curve: AppAnimation.smoothCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.64)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: AppColors.primaryDeep),
              const SizedBox(width: 5),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              color: user.isMe
                  ? AppColors.mine.withValues(alpha: 0.56)
                  : AppColors.partner.withValues(alpha: 0.48),
              borderColor: Colors.white.withValues(alpha: 0.62),
              radius: AppRadius.sm,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              onTap: user.isMe
                  ? () => _showKitchenStatusSheet(context, controller, user.id)
                  : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.72),
                    child: Icon(
                      user.isMe
                          ? Icons.rice_bowl_rounded
                          : Icons.soup_kitchen_rounded,
                      color:
                          user.isMe ? AppColors.primaryDeep : AppColors.coral,
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
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                        Text(
                          _kitchenStatusText(
                              state.kitchenStatuses[user.id]?.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
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
  const _EmptyState({
    required this.hasAnyWish,
    required this.onCreateWish,
  });

  final bool hasAnyWish;
  final VoidCallback onCreateWish;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.flatware_rounded,
              color: AppColors.primaryDeep,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasAnyWish ? '当前筛选下没有愿望' : '先许下第一个饭点愿望',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasAnyWish ? '换个筛选看看，或者新建一个今天想吃的。' : '把想吃的、能接受的替代方案和希望时间写清楚。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _GradientWishButton(onPressed: onCreateWish),
        ],
      ),
    );
  }
}

class _GradientWishButton extends StatelessWidget {
  const _GradientWishButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 176),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.58),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(176, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
          icon: const Icon(Icons.add_circle_rounded),
          label: const Text(
            '许个愿望',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SoftCard(
      padding: EdgeInsets.symmetric(vertical: 42),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.coral),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
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
