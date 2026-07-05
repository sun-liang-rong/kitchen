import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../providers/wish_pool_controller.dart';

class CreateWishPage extends ConsumerStatefulWidget {
  const CreateWishPage({super.key});

  @override
  ConsumerState<CreateWishPage> createState() => _CreateWishPageState();
}

class _CreateWishPageState extends ConsumerState<CreateWishPage> {
  final _titleController = TextEditingController(text: '可乐鸡翅');
  final _noteController = TextEditingController();
  final _feelings = <String>{'下饭一点'};
  final _helperTasks = <String>{'洗碗'};
  String _desiredTime = '今晚';
  String _intensity = '今天想吃';
  String _substituteOption = '可以换类似的';

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishPoolControllerProvider);
    final partnerStatus = state.kitchenStatuses[state.partner.id];

    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.local_fire_department_outlined),
          label: const Text('丢进许愿池'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            WarmTopBar(
              title: '许愿',
              leading: IconButton(
                tooltip: '关闭',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, size: 18),
              ),
              centerTitle: true,
            ),
            const SizedBox(height: 12),
            Text(
              '说出想吃的，',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '也带上一点搭把手。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            SoftCard(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '想吃什么',
                  hintText: '可乐鸡翅',
                  prefixIcon: Icon(Icons.restaurant),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.mood,
              title: '想要的感觉',
              options: const [
                '下饭一点',
                '热乎一点',
                '清淡一点',
                '有汤',
                '有肉',
                '简单点',
                '想吃面',
                '不想吃米饭'
              ],
              selected: _feelings,
              onChanged: (value) => setState(() => _toggle(_feelings, value)),
            ),
            _SingleChoiceCard(
              icon: Icons.calendar_month,
              title: '希望什么时候吃',
              options: const ['今晚', '明天', '这周', '周末', '有空再说'],
              selected: _desiredTime,
              onSelected: (value) => setState(() => _desiredTime = value),
            ),
            _SingleChoiceCard(
              icon: Icons.favorite_border,
              title: '愿望强度',
              options: const ['随口一想', '今天想吃', '这周想吃', '今天特别想吃', '周末认真安排'],
              selected: _intensity,
              onSelected: (value) => setState(() => _intensity = value),
            ),
            _SingleChoiceCard(
              icon: Icons.handshake_outlined,
              title: '如果不好做',
              options: const ['可以换类似的', '可以做轻松版', '家里有什么就做什么', '不太想换'],
              selected: _substituteOption,
              onSelected: (value) => setState(() => _substituteOption = value),
              highlighted: true,
            ),
            _OptionCard(
              icon: Icons.volunteer_activism_outlined,
              title: '我愿意搭把手',
              options: const [
                '洗碗',
                '拖地',
                '买菜',
                '洗菜',
                '备菜',
                '收拾厨房',
                '倒垃圾',
                '饭后收桌',
                '陪你一起做',
                '给你买杯喝的',
              ],
              selected: _helperTasks,
              onChanged: (value) =>
                  setState(() => _toggle(_helperTasks, value)),
              highlighted: true,
            ),
            SoftCard(
              child: TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '写一句话',
                  hintText: partnerStatus?.note ?? '如果今天累了，简单吃也可以。',
                  prefixIcon: const Icon(Icons.edit_note),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(Set<String> target, String value) {
    if (!target.add(value)) {
      target.remove(value);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先写下想吃什么')),
      );
      return;
    }

    ref.read(wishPoolControllerProvider.notifier).createWish(
          title: title,
          wishType: _feelings.isEmpty ? 'DISH' : 'FEELING',
          feelingTags: _feelings.toList(),
          desiredTime: _desiredTime,
          intensity: _intensity,
          substituteOption: _substituteOption,
          helperTasks: _helperTasks.toList(),
        );
    context.pop();
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onChanged;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: icon,
      title: title,
      highlighted: highlighted,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            SoftChip(
              label: option,
              selected: selected.contains(option),
              onTap: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _SingleChoiceCard extends StatelessWidget {
  const _SingleChoiceCard({
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: icon,
      title: title,
      highlighted: highlighted,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            SoftChip(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        color: highlighted ? AppColors.surfaceLow : AppColors.surface,
        borderColor: highlighted ? AppColors.outline : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
