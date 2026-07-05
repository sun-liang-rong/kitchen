import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../../wish_pool/domain/models/kitchen_models.dart';
import '../../../wish_pool/presentation/providers/wish_pool_controller.dart';

class HomeDishesPage extends ConsumerStatefulWidget {
  const HomeDishesPage({super.key});

  @override
  ConsumerState<HomeDishesPage> createState() => _HomeDishesPageState();
}

class _HomeDishesPageState extends ConsumerState<HomeDishesPage> {
  bool _searching = false;
  int _recommendationIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishPoolControllerProvider);
    final controller = ref.read(wishPoolControllerProvider.notifier);
    final query = state.dishQuery.trim();
    final filters = state.dishFilters;
    final dishes = state.dishes.where((dish) {
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        final haystack = [
          dish.name,
          dish.lastFeedback ?? '',
          ...dish.tasteTags,
          ...dish.suitableTimeTags,
        ].join(' ').toLowerCase();
        if (!haystack.contains(lowerQuery)) {
          return false;
        }
      }
      if (filters.owner == DishOwnerFilter.me &&
          dish.cookOwner != state.me.id) {
        return false;
      }
      if (filters.owner == DishOwnerFilter.partner &&
          dish.cookOwner != state.partner.id) {
        return false;
      }
      if (filters.difficulty != null && dish.difficulty != filters.difficulty) {
        return false;
      }
      if (filters.favoriteOnly && !dish.isFavorite) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: 'dishes'),
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
              actions: const [NotificationBell(color: AppColors.text)],
              centerTitle: true,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text('我们家的菜',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                FilledButton.icon(
                  onPressed: () => _showDishSheet(context, controller),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新增'),
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(74, 36)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RecommendationCard(
              dishes: state.dishes,
              index: _recommendationIndex,
              onUseTonight: (title) {
                controller.createWish(
                  title: title,
                  desiredTime: '今晚',
                  intensity: '今天想吃',
                  substituteOption: '可以换类似的',
                  helperTasks: const ['饭后收桌'],
                );
                context.go('/');
              },
              onShuffle: () {
                setState(() {
                  _recommendationIndex += 1;
                });
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('全部菜品', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: '筛选',
                  onPressed: () =>
                      _showFilterSheet(context, controller, state.dishFilters),
                  icon: Icon(
                    Icons.filter_list,
                    color: state.dishFilters.isActive
                        ? AppColors.primaryContainer
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: '搜索',
                  onPressed: () => setState(() => _searching = !_searching),
                  icon: Icon(_searching ? Icons.close : Icons.search),
                ),
              ],
            ),
            if (_searching) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '搜索菜名、标签或反馈',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空',
                          onPressed: () {
                            _searchController.clear();
                            controller.searchDishes('');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: controller.searchDishes,
              ),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter
                      in _activeFilterLabels(state.dishFilters)) ...[
                    SoftChip(
                      label: filter,
                      selected: filter != '全部',
                      onTap:
                          filter == '全部' ? null : controller.clearDishFilters,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (dishes.isEmpty)
              const SoftCard(
                padding: EdgeInsets.symmetric(vertical: 46),
                child: Center(child: Text('还没有符合筛选的菜')),
              )
            else
              for (final dish in dishes) ...[
                _DishCard(
                  name: dish.name,
                  subtitle: [
                    if (dish.difficulty != null) dish.difficulty!,
                    if (dish.lastFeedback != null) dish.lastFeedback!,
                  ].join(' · '),
                  tags: [
                    ...dish.suitableTimeTags.take(2),
                    dish.cookOwner == state.partner.id ? '她会做' : '我会做',
                  ],
                  onEdit: () =>
                      _showDishSheet(context, controller, dishId: dish.id),
                ),
                const SizedBox(height: 12),
              ],
            _AddDishDashedCard(
                onTap: () => _showDishSheet(context, controller)),
          ],
        ),
      ),
    );
  }

  List<String> _activeFilterLabels(DishFilters filters) {
    if (!filters.isActive) {
      return const ['全部'];
    }
    return [
      if (filters.owner == DishOwnerFilter.me) '我会做',
      if (filters.owner == DishOwnerFilter.partner) '她会做',
      if (filters.difficulty != null) filters.difficulty!,
      if (filters.favoriteOnly) '常吃',
    ];
  }

  void _showFilterSheet(
    BuildContext context,
    WishPoolController controller,
    DishFilters current,
  ) {
    var filters = current;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('筛选菜品', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    _FilterTitle('谁会做'),
                    Wrap(
                      spacing: 8,
                      children: [
                        SoftChip(
                          label: '不限',
                          selected: filters.owner == DishOwnerFilter.all,
                          onTap: () => setSheetState(
                            () => filters =
                                filters.copyWith(owner: DishOwnerFilter.all),
                          ),
                        ),
                        SoftChip(
                          label: '我会做',
                          selected: filters.owner == DishOwnerFilter.me,
                          onTap: () => setSheetState(
                            () => filters =
                                filters.copyWith(owner: DishOwnerFilter.me),
                          ),
                        ),
                        SoftChip(
                          label: '她会做',
                          selected: filters.owner == DishOwnerFilter.partner,
                          onTap: () => setSheetState(
                            () => filters = filters.copyWith(
                                owner: DishOwnerFilter.partner),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FilterTitle('难度'),
                    Wrap(
                      spacing: 8,
                      children: [
                        SoftChip(
                          label: '不限',
                          selected: filters.difficulty == null,
                          onTap: () => setSheetState(() =>
                              filters = filters.copyWith(difficulty: null)),
                        ),
                        for (final difficulty in const ['简单', '普通', '费事'])
                          SoftChip(
                            label: difficulty,
                            selected: filters.difficulty == difficulty,
                            onTap: () => setSheetState(
                              () => filters =
                                  filters.copyWith(difficulty: difficulty),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('只看常吃菜'),
                      value: filters.favoriteOnly,
                      onChanged: (value) => setSheetState(
                        () => filters = filters.copyWith(favoriteOnly: value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              controller.clearDishFilters();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('重置'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              controller.applyDishFilters(filters);
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('应用'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDishSheet(
    BuildContext context,
    WishPoolController controller, {
    String? dishId,
  }) {
    final state = ref.read(wishPoolControllerProvider);
    final dish = dishId == null
        ? null
        : state.dishes.firstWhere((item) => item.id == dishId);
    final nameController = TextEditingController(text: dish?.name);
    var cookOwner = dish?.cookOwner ?? state.me.id;
    var difficulty = dish?.difficulty ?? '普通';
    final tags = {...?dish?.suitableTimeTags};

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(dish == null ? '录入拿手好菜' : '编辑这道菜',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '菜名'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        SoftChip(
                          label: '我会做',
                          selected: cookOwner == state.me.id,
                          onTap: () =>
                              setSheetState(() => cookOwner = state.me.id),
                        ),
                        SoftChip(
                          label: '她会做',
                          selected: cookOwner == state.partner.id,
                          onTap: () =>
                              setSheetState(() => cookOwner = state.partner.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in const ['今晚', '周末', '快手', '认真做'])
                          SoftChip(
                            label: tag,
                            selected: tags.contains(tag),
                            onTap: () => setSheetState(() {
                              if (!tags.add(tag)) {
                                tags.remove(tag);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: difficulty,
                      decoration: const InputDecoration(labelText: '难度'),
                      items: const [
                        DropdownMenuItem(value: '简单', child: Text('简单')),
                        DropdownMenuItem(value: '普通', child: Text('普通')),
                        DropdownMenuItem(value: '费事', child: Text('费事')),
                      ],
                      onChanged: (value) => difficulty = value ?? difficulty,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          return;
                        }
                        if (dish == null) {
                          controller.addDish(
                            name: name,
                            cookOwner: cookOwner,
                            suitableTimeTags: tags.toList(),
                            difficulty: difficulty,
                            isFavorite: true,
                          );
                        } else {
                          controller.updateDish(
                            dish.id,
                            (item) => item.copyWith(
                              name: name,
                              cookOwner: cookOwner,
                              suitableTimeTags: tags.toList(),
                              difficulty: difficulty,
                            ),
                          );
                        }
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('保存'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.dishes,
    required this.index,
    required this.onUseTonight,
    required this.onShuffle,
  });

  final List<HomeDish> dishes;
  final int index;
  final ValueChanged<String> onUseTonight;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 154,
            child: Stack(
              children: [
                FoodImageTile(
                    title: recommendation.title,
                    height: 154,
                    icon: Icons.ramen_dining),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('适合今天',
                            style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('今晚灵感', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(recommendation.title,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            recommendation.reason,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                  onPressed: () => onUseTonight(recommendation.title),
                  child: const Text('今晚就吃')),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onShuffle,
                icon: const Icon(Icons.autorenew),
                label: const Text('换一换'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _DishRecommendation _recommendation() {
    final favorites = dishes.where((dish) => dish.isFavorite).toList();
    final pool = favorites.isNotEmpty ? favorites : dishes;
    if (pool.isEmpty) {
      return const _DishRecommendation(
        title: '番茄鸡蛋面 + 凉拌黄瓜',
        reason: '下班回家的首选，酸甜开胃的番茄汤底配上清爽的凉拌黄瓜，15分钟就能搞定。',
      );
    }

    final first = pool[index.abs() % pool.length];
    final secondCandidates = pool.where((dish) => dish.id != first.id).toList();
    final second = secondCandidates.isEmpty
        ? null
        : secondCandidates[(index + 1).abs() % secondCandidates.length];
    final title =
        second == null ? first.name : '${first.name} + ${second.name}';
    final tags = [
      if (first.difficulty != null) first.difficulty!,
      ...first.suitableTimeTags.take(1),
      ...first.tasteTags.take(1),
    ];
    return _DishRecommendation(
      title: title,
      reason: tags.isEmpty
          ? '从我们家的菜里挑一个今晚能安排的组合。'
          : '根据 ${tags.join('、')} 这些记忆挑出来，适合今晚少纠结一点。',
    );
  }
}

class _DishRecommendation {
  const _DishRecommendation({required this.title, required this.reason});

  final String title;
  final String reason;
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.name,
    required this.subtitle,
    required this.tags,
    required this.onEdit,
  });

  final String name;
  final String subtitle;
  final List<String> tags;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoodImageTile(title: name, height: 120, icon: Icons.local_dining),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: Text(name,
                      style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                tooltip: '编辑',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final tag in tags) SoftChip(label: tag)],
          ),
        ],
      ),
    );
  }
}

class _AddDishDashedCard extends StatelessWidget {
  const _AddDishDashedCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:
              Border.all(color: AppColors.outline, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.surfaceContainer,
                child: Icon(Icons.add, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text('录入拿手好菜', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
