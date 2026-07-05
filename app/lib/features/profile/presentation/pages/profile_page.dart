import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

    return MagazineScaffold(
      bottomNavigationBar: const AppBottomNav(current: 'profile'),
      children: [
        const MagazineHeader(
          title: '我的',
          kicker: 'Profile',
          subtitle: '账号、绑定和厨房入口都在这里。',
          leadingIcon: Icons.person_outline_rounded,
          center: true,
        ),
        SoftCard(
          radius: AppRadius.xl,
          padding: const EdgeInsets.all(20),
          gradient: AppColors.paperGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    radius: 34,
                    avatarUrl: user?.avatarUrl,
                    gender: user?.gender ?? UserGender.unspecified,
                    backgroundColor: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 16),
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
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 18, color: AppColors.primaryDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '性别：${userGenderLabel(user?.gender ?? UserGender.unspecified)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SoftCard(
          radius: AppRadius.xl,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(
                    label: binding?.status == CoupleBindingStatus.bound
                        ? '已绑定'
                        : '未绑定',
                    icon: Icons.favorite_border,
                    color: binding?.status == CoupleBindingStatus.bound
                        ? AppColors.primaryDeep
                        : AppColors.textLight,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(sessionControllerProvider.notifier)
                        .refreshBinding(),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('刷新'),
                  ),
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
          radius: AppRadius.xl,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              _ProfileAction(
                icon: Icons.settings_outlined,
                label: '设置',
                onTap: () => _showSettingsSheet(context, ref),
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
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(sessionControllerProvider).valueOrNull?.user;
    final nicknameController = TextEditingController(text: user?.nickname);
    String? avatarUrl = user?.avatarUrl;
    XFile? selectedAvatar;
    var selectedGender = user?.gender ?? UserGender.unspecified;
    var saving = false;

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
                    _AvatarPicker(
                      avatarUrl: avatarUrl,
                      selectedImage: selectedAvatar,
                      gender: selectedGender,
                      onPickFromGallery: () async {
                        final picked = await _pickAvatar(ImageSource.gallery);
                        if (picked != null) {
                          setSheetState(() => selectedAvatar = picked);
                        }
                      },
                      onTakePhoto: () async {
                        final picked = await _pickAvatar(ImageSource.camera);
                        if (picked != null) {
                          setSheetState(() => selectedAvatar = picked);
                        }
                      },
                      onRemove: () => setSheetState(() {
                        selectedAvatar = null;
                        avatarUrl = null;
                      }),
                    ),
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
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final nickname = nicknameController.text.trim();
                              if (nickname.isEmpty) {
                                return;
                              }
                              setSheetState(() => saving = true);
                              var nextAvatarUrl = avatarUrl;
                              if (selectedAvatar != null) {
                                try {
                                  nextAvatarUrl = await ref
                                      .read(sessionControllerProvider.notifier)
                                      .uploadAvatar(
                                        bytes:
                                            await selectedAvatar!.readAsBytes(),
                                        filename: selectedAvatar!.name,
                                      );
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('头像上传失败，请稍后再试')),
                                    );
                                  }
                                  setSheetState(() => saving = false);
                                  return;
                                }
                              }
                              await ref
                                  .read(sessionControllerProvider.notifier)
                                  .updateProfile(
                                    nickname: nickname,
                                    avatarUrl: nextAvatarUrl,
                                    gender: selectedGender,
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(saving ? '保存中' : '保存'),
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

  Future<XFile?> _pickAvatar(ImageSource source) {
    return ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 86,
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(sessionControllerProvider).valueOrNull;
    final user = state?.user;
    final binding = state?.binding;
    final isBound = binding?.status == CoupleBindingStatus.bound;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('设置',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            user?.nickname ?? '管理账号和本地偏好',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SettingsTile(
                  icon: Icons.account_circle_outlined,
                  title: '账号资料',
                  subtitle: '修改昵称、头像和性别',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showProfileSheet(context, ref);
                  },
                ),
                _SettingsTile(
                  icon: Icons.favorite_border,
                  title: '双人绑定',
                  subtitle: isBound
                      ? '管理和${binding?.partner?.nickname ?? '对方'}的绑定'
                      : '生成邀请码或刷新绑定状态',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _manageBinding(context, ref);
                  },
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: '消息通知',
                  subtitle: '查看愿望和绑定提醒',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/notifications');
                  },
                ),
                _SettingsTile(
                  icon: Icons.cleaning_services_outlined,
                  title: '清理图片缓存',
                  subtitle: '释放本地临时图片占用',
                  onTap: () {
                    imageCache.clear();
                    imageCache.clearLiveImages();
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('图片缓存已清理')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.logout,
                  title: '退出登录',
                  subtitle: '回到登录页',
                  destructive: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(sessionControllerProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.coral : AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border:
                  Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: destructive
                                  ? AppColors.coral.withValues(alpha: 0.82)
                                  : AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
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

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.gender,
    required this.onPickFromGallery,
    required this.onTakePhoto,
    required this.onRemove,
    this.avatarUrl,
    this.selectedImage,
  });

  final UserGender gender;
  final String? avatarUrl;
  final XFile? selectedImage;
  final VoidCallback onPickFromGallery;
  final VoidCallback onTakePhoto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = selectedImage != null || (avatarUrl?.isNotEmpty ?? false);
    return SoftCard(
      color: AppColors.surfaceLow,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (selectedImage == null)
            UserAvatar(
              radius: 38,
              avatarUrl: avatarUrl,
              gender: gender,
              backgroundColor: AppColors.primaryContainer,
            )
          else
            FutureBuilder<Uint8List>(
              future: selectedImage!.readAsBytes(),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  return UserAvatar(
                    radius: 38,
                    avatarUrl: avatarUrl,
                    gender: gender,
                    backgroundColor: AppColors.primaryContainer,
                  );
                }
                return CircleAvatar(
                  radius: 38,
                  backgroundImage: MemoryImage(bytes),
                );
              },
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasAvatar ? '更换头像' : '上传头像'),
                ),
                OutlinedButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('拍照'),
                ),
                if (hasAvatar)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    label: const Text('使用默认头像'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
