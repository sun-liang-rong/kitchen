import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../../spirit/presentation/widgets/spirit_overlay_scaffold.dart';
import '../providers/wish_pool_controller.dart';

class FulfillmentRecordsPage extends ConsumerWidget {
  const FulfillmentRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishPoolControllerProvider);
    final records = [
      for (final item in state.fulfillments)
        _DisplayRecord(
          item.actualDishName,
          '刚刚',
          item.note ?? '这顿饭已经被好好记下来了。',
          [
            '实现人：${item.fulfillerId == state.me.id ? '我' : '她'}',
            if (item.helperTasksDone.isNotEmpty)
              '搭手：${item.helperTasksDone.join('、')}',
            ...item.feedbackTags,
            if (item.addToDishes) '已加入我们家的菜',
          ],
        ),
    ];

    return SpiritOverlayScaffold(
      child: MagazineScaffold(
        bottomNavigationBar: const AppBottomNav(current: 'records'),
        children: [
          const MagazineHeader(
            title: '兑现记录',
            kicker: 'Dinner Diary',
            subtitle: '每顿饭都留下一点有用的记忆。',
            leadingIcon: Icons.history_edu_rounded,
            actions: [NotificationBell()],
          ),
          MagazineCoverCard(
            label: '最近7天',
            icon: Icons.schedule_rounded,
            child: Text(
              records.isEmpty ? '还没有新的饭后回忆。' : '这些愿望，已经变成了饭桌上的记忆。',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 18),
          if (records.isEmpty)
            const MagazineEmptyState(
              title: '还没有兑现记录',
              message: '愿望被吃到之后，会在这里变成一页饭后回忆。',
              icon: Icons.local_dining_rounded,
            )
          else
            for (var i = 0; i < records.length; i++)
              _TimelineRecord(
                  record: records[i], isLast: i == records.length - 1),
        ],
      ),
    );
  }
}

class _DisplayRecord {
  const _DisplayRecord(this.title, this.time, this.note, this.tags);

  final String title;
  final String time;
  final String note;
  final List<String> tags;
}

class _TimelineRecord extends StatelessWidget {
  const _TimelineRecord({required this.record, required this.isLast});

  final _DisplayRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 214,
                color: AppColors.outline.withValues(alpha: 0.7),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftCard(
              radius: AppRadius.xl,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FoodImageTile(
                      title: record.title,
                      height: 150,
                      icon: Icons.local_dining),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      Text(record.time,
                          style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record.note,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in record.tags) SoftChip(label: tag),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
