import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../couple/domain/couple_models.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final state = session.valueOrNull;
    final user = state?.user;
    final binding = state?.binding;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: 'profile'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            WarmTopBar(
              title: '我的',
              subtitle: '管理账号资料、绑定关系和这口小锅的入口。',
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceHigh,
                child: Icon(Icons.person_outline,
                    size: 16, color: AppColors.primary),
              ),
              centerTitle: true,
            ),
            const SizedBox(height: 14),
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.surfaceContainer,
                    backgroundImage: user?.avatarUrl == null
                        ? null
                        : NetworkImage(user!.avatarUrl!),
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.primary, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nickname ?? '未登录',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? user?.phone ?? '账号信息',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '性别：${userGenderLabel(user?.gender ?? UserGender.unspecified)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '编辑资料',
                    onPressed: user == null
                        ? null
                        : () => _showProfileSheet(context, ref),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SoftChip(
                        label: binding?.status == CoupleBindingStatus.bound
                            ? '已绑定'
                            : '未绑定',
                        icon: Icons.favorite_border,
                        selected: binding?.status == CoupleBindingStatus.bound,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _manageBinding(context, ref),
                        icon: const Icon(Icons.settings, size: 17),
                        label: const Text('管理'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    binding?.status == CoupleBindingStatus.bound
                        ? '你和${binding?.partner?.nickname ?? '对方'}正在共享厨房许愿池。'
                        : '完成绑定后才能共享许愿池。',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (binding?.inviteCode != null) ...[
                    const SizedBox(height: 10),
                    SoftChip(
                      label: '邀请码 ${binding!.inviteCode!}',
                      icon: Icons.qr_code_2,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _ProfileAction(
                    icon: Icons.sync,
                    label: '刷新绑定状态',
                    onTap: () => ref
                        .read(sessionControllerProvider.notifier)
                        .refreshBinding(),
                  ),
                  _ProfileAction(
                    icon: Icons.logout,
                    label: '退出登录',
                    destructive: true,
                    onTap: () =>
                        ref.read(sessionControllerProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(sessionControllerProvider).valueOrNull?.user;
    final nicknameController = TextEditingController(text: user?.nickname);
    final avatarController = TextEditingController(text: user?.avatarUrl);
    var selectedGender = user?.gender ?? UserGender.unspecified;

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
                    Text('编辑资料', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<UserGender>(
                      segments: const [
                        ButtonSegment(
                          value: UserGender.female,
                          label: Text('女'),
                          icon: Icon(Icons.female),
                        ),
                        ButtonSegment(
                          value: UserGender.male,
                          label: Text('男'),
                          icon: Icon(Icons.male),
                        ),
                        ButtonSegment(
                          value: UserGender.unspecified,
                          label: Text('暂不选'),
                          icon: Icon(Icons.person_outline),
                        ),
                      ],
                      selected: {selectedGender},
                      onSelectionChanged: (value) {
                        setSheetState(() => selectedGender = value.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: avatarController,
                      decoration: const InputDecoration(
                        labelText: '头像 URL',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final nickname = nicknameController.text.trim();
                        if (nickname.isEmpty) {
                          return;
                        }
                        await ref
                            .read(sessionControllerProvider.notifier)
                            .updateProfile(
                              nickname: nickname,
                              avatarUrl: avatarController.text.trim().isEmpty
                                  ? null
                                  : avatarController.text.trim(),
                              gender: selectedGender,
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
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

  void _manageBinding(BuildContext context, WidgetRef ref) {
    final binding = ref.read(sessionControllerProvider).valueOrNull?.binding;
    final isBound = binding?.status == CoupleBindingStatus.bound;
    final inviteCode = binding?.inviteCode;

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
                  isBound
                      ? '解绑后不会删除历史记录，但新的许愿池不会继续共享。'
                      : '把邀请码发给对方，或等待对方同意你的绑定申请。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    inviteCode ?? '还没有邀请码',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(sessionControllerProvider.notifier)
                              .generateCode();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('邀请码已更新')),
                            );
                          }
                        },
                        icon: const Icon(Icons.qr_code_2),
                        label: Text(inviteCode == null ? '生成邀请码' : '刷新邀请码'),
                      ),
                    ),
                    if (inviteCode != null) ...[
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: '复制邀请码',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('邀请码已复制')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(sessionControllerProvider.notifier)
                        .refreshBinding();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('刷新绑定状态'),
                ),
                if (isBound) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral,
                      side: const BorderSide(color: AppColors.coral),
                    ),
                    onPressed: () async {
                      await ref
                          .read(sessionControllerProvider.notifier)
                          .unbind();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.link_off),
                    label: const Text('解除绑定'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.coral : AppColors.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: color))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
