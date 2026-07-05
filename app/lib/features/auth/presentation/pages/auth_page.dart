import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../../../shared/widgets/soft_components.dart';
import '../../domain/auth_models.dart';
import '../providers/session_controller.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isRegister = false;
  UserGender _gender = UserGender.unspecified;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isLoading = session.isLoading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const WarmTopBar(
              title: '厨房许愿池',
              subtitle: '先认出你是谁，再把两个人的饭桌连起来。',
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceHigh,
                child: Icon(Icons.restaurant_menu, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('登录')),
                      ButtonSegment(value: true, label: Text('注册')),
                    ],
                    selected: {_isRegister},
                    onSelectionChanged: (value) {
                      setState(() => _isRegister = value.first);
                    },
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _accountController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱或手机号',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_isRegister) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
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
                      selected: {_gender},
                      onSelectionChanged: (value) {
                        setState(() => _gender = value.first);
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: isLoading ? null : _submit,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isRegister ? Icons.person_add_alt : Icons.login),
                    label: Text(_isRegister ? '注册并进入绑定' : '登录'),
                  ),
                  if (session.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      '账号信息没有通过，请检查后再试。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.coral,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text;
    final nickname = _nicknameController.text.trim();
    if (account.isEmpty ||
        password.length < 6 ||
        (_isRegister && nickname.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写账号、至少 6 位密码和必要资料')),
      );
      return;
    }

    final controller = ref.read(sessionControllerProvider.notifier);
    if (_isRegister) {
      await controller.register(account, password, nickname, gender: _gender);
    } else {
      await controller.login(account, password);
    }
  }
}
