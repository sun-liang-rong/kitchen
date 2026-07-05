import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
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

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: 'records'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            WarmTopBar(
              title: '厨房许愿池',
              leading: const CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.surfaceHigh,
                child:
                    Icon(Icons.restaurant, size: 14, color: AppColors.primary),
              ),
              actions: const [NotificationBell()],
              centerTitle: true,
            ),
            const SizedBox(height: 10),
            Text('兑现记录', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('每顿饭都留下一点有用的记忆。',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.schedule, size: 17, color: AppColors.blueGray),
                const SizedBox(width: 6),
                Text('最近7天', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const SoftCard(
                padding: EdgeInsets.symmetric(vertical: 44, horizontal: 18),
                child: Center(child: Text('还没有兑现记录')),
              )
            else
              for (var i = 0; i < records.length; i++)
                _TimelineRecord(
                    record: records[i], isLast: i == records.length - 1),
          ],
        ),
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
