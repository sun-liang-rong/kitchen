import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../wish_pool/domain/models/kitchen_models.dart';
import '../../../wish_pool/presentation/providers/wish_pool_controller.dart';

class WishDetailPage extends ConsumerStatefulWidget {
  const WishDetailPage({required this.wishId, super.key});

  final String wishId;

  @override
  ConsumerState<WishDetailPage> createState() => _WishDetailPageState();
}

class _WishDetailPageState extends ConsumerState<WishDetailPage> {
  bool _loadingLatest = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshLatest);
  }

  Future<void> _refreshLatest() async {
    setState(() => _loadingLatest = true);
    try {
      await ref
          .read(wishPoolControllerProvider.notifier)
          .refreshWish(widget.wishId);
    } catch (_) {
      // Keep the cached detail available if the network is temporarily down.
    } finally {
      if (mounted) {
        setState(() => _loadingLatest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishPoolControllerProvider);
    final controller = ref.read(wishPoolControllerProvider.notifier);
    final wish = state.wishes.firstWhere((item) => item.id == widget.wishId);
    final creator = state.users.firstWhere((user) => user.id == wish.creatorId);
    final currentUserId = state.me.id;

    return Scaffold(
      bottomNavigationBar: _DetailBottomBar(
        wish: wish,
        controller: controller,
        currentUserId: currentUserId,
        state: state,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            WarmTopBar(
              title: '愿望详情',
              subtitle: _loadingLatest ? '正在同步最新状态...' : '愿望怎么被回应，这里都能看见。',
              leading: IconButton(
                tooltip: '返回',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 19),
              ),
              actions: [
                IconButton(
                  tooltip: '刷新',
                  onPressed: _loadingLatest ? null : _refreshLatest,
                  icon: const Icon(Icons.sync, size: 19),
                ),
                IconButton(
                  tooltip: '更多',
                  onPressed: () =>
                      _showWishActions(context, controller, wish, state.me.id),
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _WishMainCard(wish: wish, creatorName: creator.nickname),
            if (wish.status == WishStatus.pendingConfirmation &&
                wish.currentResponse != null) ...[
              const SizedBox(height: 14),
              _PendingConfirmCard(
                wish: wish,
                controller: controller,
                currentUserId: currentUserId,
                creatorName: creator.nickname,
                responderName:
                    _userName(state, wish.currentResponse!.responderId),
              ),
            ],
            const SizedBox(height: 22),
            Text('状态流转', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _Timeline(wish: wish, state: state),
          ],
        ),
      ),
    );
  }

  void _showWishActions(
    BuildContext context,
    WishPoolController controller,
    Wish wish,
    String currentUserId,
  ) {
    final canDelete =
        wish.creatorId == currentUserId && wish.status != WishStatus.fulfilled;
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('管理愿望', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  canDelete ? '还没兑现的自己许下的愿望可以撤回。' : '已兑现或对方许下的愿望不能删除。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  onPressed: !canDelete
                      ? null
                      : () {
                          controller.deleteWish(wish.id);
                          Navigator.of(context).pop();
                          context.go('/');
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除愿望'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WishMainCard extends StatelessWidget {
  const _WishMainCard({required this.wish, required this.creatorName});

  final Wish wish;
  final String creatorName;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 92, child: FoodImageTile(title: wish.title, height: 92)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$creatorName许的 · ${wish.intensity}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    SoftChip(
                        label: _wishStatusText(wish.status), selected: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(wish.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '如果家里没有原本想吃的，换个温柔一点的版本也可以。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SoftChip(label: '希望${wish.desiredTime}'),
                    if (wish.helperTasks.isNotEmpty)
                      for (final task in wish.helperTasks.take(2))
                        SoftChip(label: task),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingConfirmCard extends StatelessWidget {
  const _PendingConfirmCard({
    required this.wish,
    required this.controller,
    required this.currentUserId,
    required this.creatorName,
    required this.responderName,
  });

  final Wish wish;
  final WishPoolController controller;
  final String currentUserId;
  final String creatorName;
  final String responderName;

  @override
  Widget build(BuildContext context) {
    final response = wish.currentResponse!;
    final isCreator = wish.creatorId == currentUserId;
    final title = isCreator
        ? '$responderName建议：${response.proposedTitle ?? _responseText(response)}'
        : '你建议：${response.proposedTitle ?? _responseText(response)}';
    return SoftCard(
      color: AppColors.surfaceLow,
      borderColor: AppColors.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            response.reasonText ??
                (isCreator
                    ? '$responderName觉得这个安排更合适，你可以同意，也可以换一个继续商量。'
                    : '已经发给$creatorName确认了，等对方决定就好。'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (isCreator) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => controller.confirmResponse(wish.id),
                    child: const Text('同意'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.reopenResponse(wish.id),
                    child: const Text('换一个'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            const SoftChip(
              label: '等待对方确认',
              icon: Icons.hourglass_top,
              selected: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.wish, required this.state});

  final Wish wish;
  final WishPoolState state;

  @override
  Widget build(BuildContext context) {
    final creatorName = _userName(state, wish.creatorId);
    final items = _timelineItems(wish, state, creatorName);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(item: items[i], isLast: i == items.length - 1),
      ],
    );
  }

  List<_TimelineItem> _timelineItems(
    Wish wish,
    WishPoolState state,
    String creatorName,
  ) {
    final sortedResponses = [...wish.responses]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final items = <_TimelineItem>[
      _TimelineItem(_formatTimelineTime(wish.createdAt),
          '$creatorName许下愿望：${wish.title}', false),
    ];

    for (final response in sortedResponses) {
      final responderName = _userName(state, response.responderId);
      final isCurrent = response.id == wish.currentResponseId;
      final isConfirmed = response.confirmedAt != null;

      items.add(
        _TimelineItem(
          _formatTimelineTime(response.createdAt),
          '$responderName回应了愿望：${_responseText(response)}',
          false,
        ),
      );

      if (isConfirmed) {
        items.add(
          _TimelineItem(
            _formatTimelineTime(response.confirmedAt!),
            '$creatorName确认了这个安排',
            true,
          ),
        );
      } else if (!isCurrent) {
        items.add(
          _TimelineItem(
            _formatTimelineTime(wish.updatedAt),
            '$creatorName想再换一个，愿望回到池中继续商量',
            false,
          ),
        );
      }
    }

    if (wish.status == WishStatus.pendingConfirmation) {
      items.add(_TimelineItem('当前状态', '等待$creatorName确认', true));
    } else if (wish.status == WishStatus.inPool && sortedResponses.isNotEmpty) {
      items.add(_TimelineItem('当前状态', '等待继续回应', true));
    }

    if (wish.status == WishStatus.fulfilled) {
      items.add(
          _TimelineItem(_formatTimelineTime(wish.updatedAt), '已经记录兑现', true));
    }

    return items;
  }
}

class _TimelineItem {
  const _TimelineItem(this.time, this.text, this.active);

  final String time;
  final String text;
  final bool active;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final _TimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: item.active ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryContainer),
              ),
              child: item.active
                  ? const Icon(Icons.check,
                      size: 11, color: AppColors.onPrimary)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 46,
                color: AppColors.outline.withValues(alpha: 0.6),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.time, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 3),
                Text(item.text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailBottomBar extends StatelessWidget {
  const _DetailBottomBar({
    required this.wish,
    required this.controller,
    required this.currentUserId,
    required this.state,
  });

  final Wish wish;
  final WishPoolController controller;
  final String currentUserId;
  final WishPoolState state;

  @override
  Widget build(BuildContext context) {
    final isMine = wish.creatorId == currentUserId;
    final canRespond = !isMine && _canRespond(wish.status);
    final canFulfill = _canFulfill(wish.status);
    return Container(
      color: AppColors.background,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (wish.status == WishStatus.pendingConfirmation) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.hourglass_top),
                  label: const Text('等点头'),
                ),
              ),
            ] else ...[
              if (canRespond) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showResponseSheet(context, controller, wish),
                    icon: const Icon(Icons.edit_square),
                    label: const Text('我接住'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: canFulfill
                      ? () => _showFulfillmentSheet(context, controller, wish)
                      : null,
                  icon: const Icon(Icons.local_dining),
                  label: const Text('吃完啦'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canFulfill(WishStatus status) {
    return {
      WishStatus.claimed,
      WishStatus.deferred,
      WishStatus.together,
    }.contains(status);
  }

  bool _canRespond(WishStatus status) {
    return {
      WishStatus.inPool,
      WishStatus.shelved,
    }.contains(status);
  }

  void _showResponseSheet(
    BuildContext context,
    WishPoolController controller,
    Wish wish,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) =>
          _ResponseSheet(controller: controller, wish: wish, state: state),
    );
  }

  void _showFulfillmentSheet(
    BuildContext context,
    WishPoolController controller,
    Wish wish,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) =>
          _FulfillmentSheet(controller: controller, wish: wish),
    );
  }
}

class _ResponseSheet extends StatefulWidget {
  const _ResponseSheet({
    required this.controller,
    required this.wish,
    required this.state,
  });

  final WishPoolController controller;
  final Wish wish;
  final WishPoolState state;

  @override
  State<_ResponseSheet> createState() => _ResponseSheetState();
}

class _ResponseSheetState extends State<_ResponseSheet> {
  final _titleController = TextEditingController(text: '红烧鸡腿');
  final _reasonController = TextEditingController();
  final _reasonTags = <String>{'家里没食材'};
  WishResponseType _type = WishResponseType.alternative;
  String _proposedTime = '周末';

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creator = widget.state.users.firstWhere(
      (user) => user.id == widget.wish.creatorId,
      orElse: () => widget.state.partner,
    );
    final creatorName = creator.nickname;
    final creatorPronoun =
        creator.isMe ? '我' : thirdPersonPronoun(creator.gender);
    final helperText = widget.wish.helperTasks.isEmpty
        ? ''
        : '，也愿意${widget.wish.helperTasks.join('和')}';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('回应$creatorName的愿望',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SoftCard(
              color: AppColors.surfaceLow,
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$creatorPronoun今天特别想吃${widget.wish.title}$helperText。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SheetTitle('你想怎么回应'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip('今晚我来实现', WishResponseType.fulfillTonight),
                _typeChip('做轻松版', WishResponseType.lightVersion),
                _typeChip('换成红烧鸡腿', WishResponseType.alternative),
                _typeChip('改天实现', WishResponseType.defer),
                _typeChip('一起做吧', WishResponseType.together),
                _typeChip('先搁着', WishResponseType.shelve),
              ],
            ),
            if (_needsProposedTitle) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _type == WishResponseType.lightVersion
                      ? '轻松版吃什么'
                      : '想换成什么',
                  prefixIcon: const Icon(Icons.swap_horiz),
                ),
              ),
            ],
            if (_type == WishResponseType.defer) ...[
              const SizedBox(height: 14),
              _SheetTitle('如果改天，想安排到'),
              Wrap(
                spacing: 8,
                children: [
                  for (final time in const ['明天', '这周', '周末', '有空再做'])
                    SoftChip(
                      label: time,
                      selected: _proposedTime == time,
                      onTap: () => setState(() => _proposedTime = time),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _SheetTitle('补充原因（可选）'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in const [
                  '家里没食材',
                  '今天有点累',
                  '时间不够',
                  '这道菜太麻烦',
                  '今天想吃清淡点'
                ])
                  SoftChip(
                    label: tag,
                    selected: _reasonTags.contains(tag),
                    onTap: () => setState(() {
                      if (!_reasonTags.add(tag)) {
                        _reasonTags.remove(tag);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '写点什么...'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.controller.respondToWish(
                        wishId: widget.wish.id,
                        type: _type,
                        proposedTitle: _needsProposedTitle
                            ? _titleController.text.trim()
                            : null,
                        proposedTime: _type == WishResponseType.defer
                            ? _proposedTime
                            : null,
                        reasonTags: _reasonTags.toList(),
                        reasonText: _reasonController.text.trim(),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.send),
                    label: Text('发给$creatorName'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, WishResponseType type) {
    return SoftChip(
      label: label,
      selected: _type == type,
      onTap: () => setState(() {
        _type = type;
        if (type == WishResponseType.lightVersion &&
            _titleController.text.trim().isEmpty) {
          _titleController.text = '番茄鸡蛋面';
        }
        if (type == WishResponseType.alternative &&
            _titleController.text.trim().isEmpty) {
          _titleController.text = '红烧鸡腿';
        }
      }),
      dense: false,
    );
  }

  bool get _needsProposedTitle {
    return _type == WishResponseType.lightVersion ||
        _type == WishResponseType.alternative;
  }
}

class _FulfillmentSheet extends StatefulWidget {
  const _FulfillmentSheet({required this.controller, required this.wish});

  final WishPoolController controller;
  final Wish wish;

  @override
  State<_FulfillmentSheet> createState() => _FulfillmentSheetState();
}

class _FulfillmentSheetState extends State<_FulfillmentSheet> {
  final _dishController = TextEditingController();
  final _feedbackTags = <String>{'今天很好吃'};
  late final Set<String> _helperTasksDone;
  bool _addToDishes = true;

  @override
  void initState() {
    super.initState();
    _dishController.text =
        widget.wish.currentResponse?.proposedTitle ?? widget.wish.title;
    _helperTasksDone = {...widget.wish.helperTasks};
  }

  @override
  void dispose() {
    _dishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('记录这次兑现', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('不用打分，只留下对下次有用的记忆。',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            TextField(
              controller: _dishController,
              decoration: const InputDecoration(
                labelText: '实际吃了什么',
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            if (widget.wish.helperTasks.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SheetTitle('这次完成了哪些搭手'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final task in widget.wish.helperTasks)
                    SoftChip(
                      label: task,
                      selected: _helperTasksDone.contains(task),
                      onTap: () => setState(() {
                        if (!_helperTasksDone.add(task)) {
                          _helperTasksDone.remove(task);
                        }
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in const ['今天很好吃', '有点淡', '有点辣', '不够辣', '下次周末做'])
                  SoftChip(
                    label: tag,
                    selected: _feedbackTags.contains(tag),
                    onTap: () => setState(() {
                      if (!_feedbackTags.add(tag)) {
                        _feedbackTags.remove(tag);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SoftCard(
              color: AppColors.surfaceLow,
              child: Row(
                children: [
                  const Icon(Icons.bookmark_border, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('加入我们家的常吃菜')),
                  Switch(
                    value: _addToDishes,
                    onChanged: (value) => setState(() => _addToDishes = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                widget.controller.fulfillWish(
                  wishId: widget.wish.id,
                  actualDishName: _dishController.text,
                  helperTasksDone: _helperTasksDone.toList(),
                  feedbackTags: _feedbackTags.toList(),
                  addToDishes: _addToDishes,
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('记录兑现'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

String _wishStatusText(WishStatus status) {
  return switch (status) {
    WishStatus.inPool => '池中',
    WishStatus.pendingConfirmation => '待她确认',
    WishStatus.claimed => '已认领',
    WishStatus.deferred => '改天',
    WishStatus.together => '一起做',
    WishStatus.shelved => '先搁着',
    WishStatus.fulfilled => '已兑现',
  };
}

String _responseText(WishResponse response) {
  return switch (response.type) {
    WishResponseType.fulfillTonight => '今晚我来实现',
    WishResponseType.lightVersion => '做轻松版',
    WishResponseType.alternative => '换成${response.proposedTitle ?? '红烧鸡腿'}',
    WishResponseType.defer => '改到${response.proposedTime ?? '周末'}',
    WishResponseType.together => '一起做吧',
    WishResponseType.shelve => '先搁着',
  };
}

String _userName(WishPoolState state, String userId) {
  for (final user in state.users) {
    if (user.id == userId) {
      return user.nickname;
    }
  }
  return '对方';
}

String _formatTimelineTime(DateTime time) {
  final now = DateTime.now();
  final isToday =
      time.year == now.year && time.month == now.month && time.day == now.day;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  if (isToday) {
    return '今天 $hour:$minute';
  }
  return '${time.month}月${time.day}日 $hour:$minute';
}
