import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../domain/spirit_models.dart';
import '../providers/spirit_controller.dart';
import 'spirit_image.dart';

class SpiritPanel extends ConsumerWidget {
  const SpiritPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(spiritControllerProvider);
    final state = asyncState.valueOrNull;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: AnimatedSwitcher(
          duration: AppAnimation.normal,
          child: asyncState.isLoading
              ? const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              : state?.isBound != true
                  ? const _DormantPanel()
                  : _BoundPanel(state: state!),
        ),
      ),
    );
  }
}

class _DormantPanel extends StatelessWidget {
  const _DormantPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: MagazineEmptyState(
        title: '待唤醒精灵',
        message: '完成情侣绑定后，签到积分和共同养成会一起开启。',
        icon: Icons.auto_awesome_outlined,
      ),
    );
  }
}

class _BoundPanel extends ConsumerWidget {
  const _BoundPanel({required this.state});

  final SpiritState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = state.home;
    if (home == null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: RitualButton(
            onPressed: () =>
                ref.read(spiritControllerProvider.notifier).refresh(),
            icon: Icons.sync_rounded,
            label: '同步精灵',
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          _SpiritHero(state: state),
          const SizedBox(height: 14),
          _StyleSection(state: state),
          const SizedBox(height: 14),
          _CheckinCard(state: state),
          const SizedBox(height: 14),
          _FeedSection(state: state),
          const SizedBox(height: 14),
          _GrowthLogSection(logs: state.logs),
          const SizedBox(height: 14),
          _PointTransactionSection(transactions: state.transactions),
        ],
      ),
    );
  }
}

class _SpiritHero extends ConsumerWidget {
  const _SpiritHero({required this.state});

  final SpiritState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spirit = state.home!.spirit;
    final points = state.home!.points;
    return SoftCard(
      radius: AppRadius.lg,
      gradient: AppColors.coverGradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 118,
            height: 118,
            child: SpiritMotion(
              style: spirit.style,
              width: 118,
              height: 118,
              effectScale: 1.12,
              burstKey: state.feedbackMessage.hashCode,
              child: SpiritImage(
                appearance: spirit.appearance,
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spirit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: '改名',
                      onPressed: state.isMutating
                          ? null
                          : () => _showRename(context, ref),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                ),
                Text(
                  'Lv.${spirit.level} · ${spiritStageLabel(spirit.stage)} · ${points.balance} 积分',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: spirit.progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.62),
                    color: AppColors.sage,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${spirit.exp}/${spirit.expToNextLevel} 经验',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRename(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: state.home!.spirit.name);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('给精灵改名'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 12,
            decoration: const InputDecoration(
              labelText: '精灵名字',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop();
                  ref.read(spiritControllerProvider.notifier).rename(name);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }
}

class _CheckinCard extends ConsumerWidget {
  const _CheckinCard({required this.state});

  final SpiritState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkin = state.home!.checkin;
    return SoftCard(
      radius: AppRadius.lg,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.calendar_month, color: AppColors.mocha),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkin.checkedInToday ? '今天已签到' : '今天还没签到',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '连续 ${checkin.streakDays} 天 · 今日 +${checkin.todayPoints} 积分',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: checkin.checkedInToday || state.isMutating
                ? null
                : () => ref.read(spiritControllerProvider.notifier).checkin(),
            icon: Icon(checkin.checkedInToday
                ? Icons.check_circle_outline
                : Icons.add_task_rounded),
            label: Text(checkin.checkedInToday ? '已签' : '签到'),
          ),
        ],
      ),
    );
  }
}

class _StyleSection extends ConsumerWidget {
  const _StyleSection({required this.state});

  final SpiritState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = state.home!.spirit.style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagazineSectionTitle(
          title: '款式',
          subtitle: '选择你们家的精灵气质。',
        ),
        Row(
          children: [
            for (final style in SpiritStyle.values) ...[
              Expanded(
                child: _StyleTile(
                  style: style,
                  selected: style == current,
                  disabled: state.isMutating,
                  onTap: () => ref
                      .read(spiritControllerProvider.notifier)
                      .updateStyle(style),
                ),
              ),
              if (style != SpiritStyle.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final SpiritStyle style;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: selected ? AppColors.primaryContainer : AppColors.surface,
      onTap: disabled || selected ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpiritImage(
            appearance: _previewAppearance(style),
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 6),
          Text(
            spiritStyleLabel(style),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.primaryDeep : AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  String _previewAppearance(SpiritStyle style) {
    return switch (style) {
      SpiritStyle.flame => 'flame_growing',
      SpiritStyle.shadow => 'shadow_growing',
      SpiritStyle.celestial => 'celestial_growing',
    };
  }
}

class _FeedSection extends ConsumerWidget {
  const _FeedSection({required this.state});

  final SpiritState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = state.home!.points.balance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagazineSectionTitle(
          title: '投喂',
          subtitle: '消耗积分，增加经验。',
        ),
        for (final type in FeedType.values) ...[
          _FeedTile(
            type: type,
            balance: balance,
            disabled: state.isMutating,
            onTap: () => ref.read(spiritControllerProvider.notifier).feed(type),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({
    required this.type,
    required this.balance,
    required this.disabled,
    required this.onTap,
  });

  final FeedType type;
  final int balance;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cost = feedTypeCost(type);
    final exp = feedTypeExp(type);
    final enough = balance >= cost;
    final subtitle = enough ? '$cost 积分 · +$exp 经验' : '还差 ${cost - balance} 积分';

    return SoftCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: enough ? AppColors.surface : AppColors.surfaceLow,
      onTap: enough && !disabled ? onTap : null,
      child: Row(
        children: [
          Icon(_feedIcon(type),
              color: enough ? AppColors.primaryDeep : AppColors.textLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedTypeLabel(type),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            enough ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  IconData _feedIcon(FeedType type) {
    return switch (type) {
      FeedType.normal => Icons.rice_bowl_rounded,
      FeedType.delicate => Icons.bakery_dining_rounded,
      FeedType.feast => Icons.local_dining_rounded,
    };
  }
}

class _GrowthLogSection extends StatelessWidget {
  const _GrowthLogSection({required this.logs});

  final List<SpiritGrowthLog> logs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagazineSectionTitle(
          title: '成长记录',
          subtitle: '最近的签到、投喂和升级。',
        ),
        if (logs.isEmpty)
          const SoftCard(
            radius: AppRadius.lg,
            child: Text('还没有成长记录。'),
          )
        else
          for (final log in logs.take(8)) ...[
            SoftCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(_logIcon(log.type), color: AppColors.primaryDeep),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      log.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  IconData _logIcon(SpiritLogType type) {
    return switch (type) {
      SpiritLogType.feed => Icons.restaurant_rounded,
      SpiritLogType.levelUp => Icons.trending_up_rounded,
      SpiritLogType.stageChanged => Icons.auto_awesome_rounded,
      SpiritLogType.wishFulfilled => Icons.favorite_rounded,
      SpiritLogType.checkin => Icons.calendar_today_rounded,
    };
  }
}

class _PointTransactionSection extends StatelessWidget {
  const _PointTransactionSection({required this.transactions});

  final List<PointTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagazineSectionTitle(
          title: '积分流水',
          subtitle: '最近的获得和消耗。',
        ),
        if (transactions.isEmpty)
          const SoftCard(
            radius: AppRadius.lg,
            child: Text('还没有积分流水。'),
          )
        else
          for (final transaction in transactions.take(8)) ...[
            SoftCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: _isEarn(transaction)
                        ? AppColors.cream
                        : AppColors.surfaceLow,
                    child: Icon(
                      _transactionIcon(transaction.reason),
                      size: 18,
                      color: _isEarn(transaction)
                          ? AppColors.primaryDeep
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description ??
                              _transactionLabel(transaction.reason),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '余额 ${transaction.balanceAfter}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${transaction.amount > 0 ? '+' : ''}${transaction.amount}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _isEarn(transaction)
                              ? AppColors.primaryDeep
                              : AppColors.coral,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  bool _isEarn(PointTransaction transaction) =>
      transaction.type == PointTransactionType.earn;

  IconData _transactionIcon(PointReason reason) {
    return switch (reason) {
      PointReason.checkin => Icons.calendar_today_rounded,
      PointReason.createWish => Icons.favorite_border_rounded,
      PointReason.respondWish => Icons.forum_outlined,
      PointReason.confirmResponse => Icons.check_circle_outline,
      PointReason.fulfillWish => Icons.local_dining_rounded,
      PointReason.addDish => Icons.menu_book_outlined,
      PointReason.feedSpirit => Icons.rice_bowl_rounded,
    };
  }

  String _transactionLabel(PointReason reason) {
    return switch (reason) {
      PointReason.checkin => '每日签到',
      PointReason.createWish => '发起愿望',
      PointReason.respondWish => '回应愿望',
      PointReason.confirmResponse => '确认安排',
      PointReason.fulfillWish => '记录兑现',
      PointReason.addDish => '添加菜品',
      PointReason.feedSpirit => '投喂精灵',
    };
  }
}
