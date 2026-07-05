import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../domain/couple_models.dart';

class BindingPage extends ConsumerStatefulWidget {
  const BindingPage({super.key});

  @override
  ConsumerState<BindingPage> createState() => _BindingPageState();
}

class _BindingPageState extends ConsumerState<BindingPage> {
  final _codeController = TextEditingController();
  CoupleInvite? _generatedInvite;
  Timer? _pollingTimer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final binding = ref.read(sessionControllerProvider).valueOrNull?.binding;
      if (binding == null || binding.status == CoupleBindingStatus.bound) {
        return;
      }
      ref.read(sessionControllerProvider.notifier).refreshBinding();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    final binding = session?.binding ??
        const CoupleBinding(status: CoupleBindingStatus.unbound);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const KitchenIllustrationBackground(),
            RefreshIndicator(
              onRefresh: () =>
                  ref.read(sessionControllerProvider.notifier).refreshBinding(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  MagazineHeader(
                    title: '绑定另一半',
                    kicker: 'Shared Kitchen',
                    subtitle: session?.user == null
                        ? '完成登录后继续绑定。'
                        : '${session!.user!.nickname}，把厨房许愿池交给两个人。',
                    leadingIcon: Icons.favorite_border_rounded,
                    actions: [
                      IconButton(
                        tooltip: '退出登录',
                        onPressed: () => ref
                            .read(sessionControllerProvider.notifier)
                            .logout(),
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  MagazineCoverCard(
                    label: binding.status == CoupleBindingStatus.bound
                        ? '双人饭桌已连线'
                        : '把邀请码递给对方',
                    icon: Icons.favorite_rounded,
                    child: Text(
                      binding.status == CoupleBindingStatus.bound
                          ? '现在可以一起许愿、一起接住晚饭灵感。'
                          : '生成或输入邀请码，让两个人进入同一本厨房日记。',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _statusCard(binding),
                  if (binding.status != CoupleBindingStatus.bound) ...[
                    const SizedBox(height: 14),
                    _generateCard(),
                    const SizedBox(height: 14),
                    _applyCard(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(CoupleBinding binding) {
    final title = switch (binding.status) {
      CoupleBindingStatus.bound => '已经绑定',
      CoupleBindingStatus.pending => '等待对方确认',
      CoupleBindingStatus.waitingForMe => '有人想和你绑定',
      _ => '还没有绑定',
    };
    final subtitle = switch (binding.status) {
      CoupleBindingStatus.bound => '现在可以进入共享许愿池。',
      CoupleBindingStatus.pending => '申请已发出，对方同意后会自动进入同一个许愿池。',
      CoupleBindingStatus.waitingForMe =>
        '${binding.invite?.inviter?.nickname ?? '对方'} 发来了绑定申请。',
      _ => '生成邀请码给对方，或输入对方的邀请码。',
    };

    return SoftCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftChip(
            label: title,
            icon: binding.status == CoupleBindingStatus.bound
                ? Icons.favorite
                : Icons.link,
            selected: binding.status == CoupleBindingStatus.bound,
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
          if (binding.status == CoupleBindingStatus.bound) ...[
            const SizedBox(height: 16),
            _BoundPartnerCard(binding: binding),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _showUnbindSheet,
              icon: const Icon(Icons.link_off),
              label: const Text('解除绑定'),
            ),
          ],
          if (binding.status == CoupleBindingStatus.waitingForMe &&
              binding.invite != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _accept(binding.invite!.id),
                    icon: const Icon(Icons.check),
                    label: const Text('同意绑定'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _reject(binding.invite!.id),
                    icon: const Icon(Icons.close),
                    label: const Text('先不绑定'),
                  ),
                ),
              ],
            ),
          ],
          if (binding.status == CoupleBindingStatus.pending &&
              binding.invite != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _cancel(binding.invite!.id),
              icon: const Icon(Icons.undo),
              label: const Text('取消申请'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _generateCard() {
    final binding = ref.watch(sessionControllerProvider).valueOrNull?.binding;
    final code = _generatedInvite?.code ?? binding?.activeInvite?.code;
    return SoftCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('我的邀请码', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '发给对方输入。对方提交后，你需要在这里同意绑定。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              code ?? '还没有生成',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _generateCode,
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(code == null ? '生成邀请码' : '刷新邀请码'),
                ),
              ),
              if (code != null) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: '复制邀请码',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('邀请码已复制')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _applyCard() {
    return SoftCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('输入对方邀请码', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '邀请码',
              prefixIcon: Icon(Icons.password),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _applyByCode,
            icon: const Icon(Icons.link),
            label: const Text('发起绑定'),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作没有成功，请稍后再试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _generateCode() => _run(() async {
        final invite =
            await ref.read(sessionControllerProvider.notifier).generateCode();
        setState(() => _generatedInvite = invite);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('邀请码已生成，发给对方输入后再回来同意绑定')),
          );
        }
      });

  Future<void> _applyByCode() => _run(() async {
        await ref
            .read(sessionControllerProvider.notifier)
            .applyByCode(_codeController.text);
        _codeController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('绑定申请已发出，等对方同意后会进入主页')),
          );
        }
      });

  Future<void> _accept(String inviteId) => _run(() async {
        await ref.read(sessionControllerProvider.notifier).accept(inviteId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('绑定成功，正在进入许愿池')),
          );
        }
      });

  Future<void> _reject(String inviteId) => _run(() {
        return ref.read(sessionControllerProvider.notifier).reject(inviteId);
      });

  Future<void> _cancel(String inviteId) => _run(() {
        return ref.read(sessionControllerProvider.notifier).cancel(inviteId);
      });

  void _showUnbindSheet() {
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
                Text('确认解除绑定吗', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '解绑后不会删除历史愿望和兑现记录，但新的许愿池不会继续共享。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  onPressed: _busy
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await _run(() => ref
                              .read(sessionControllerProvider.notifier)
                              .unbind());
                        },
                  icon: const Icon(Icons.link_off),
                  label: const Text('确认解绑'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BoundPartnerCard extends StatelessWidget {
  const _BoundPartnerCard({required this.binding});

  final CoupleBinding binding;

  @override
  Widget build(BuildContext context) {
    final partner = binding.partner;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          UserAvatar(
            radius: 24,
            avatarUrl: partner?.avatarUrl,
            gender: partner?.gender ?? UserGender.unspecified,
            backgroundColor: AppColors.surfaceHigh,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner?.nickname ?? '另一半',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '共享厨房已开启',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
