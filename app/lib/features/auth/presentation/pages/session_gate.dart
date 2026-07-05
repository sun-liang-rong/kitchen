import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../couple/presentation/pages/binding_page.dart';
import '../../../wish_pool/presentation/pages/wish_pool_page.dart';
import 'auth_page.dart';
import '../providers/session_controller.dart';

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return session.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AuthPage(),
      data: (state) {
        if (!state.isLoggedIn) {
          return const AuthPage();
        }
        if (!state.isBound) {
          return const BindingPage();
        }
        return const WishPoolPage();
      },
    );
  }
}
