import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_wish_well/features/auth/domain/auth_models.dart';
import 'package:kitchen_wish_well/features/auth/presentation/providers/session_controller.dart';
import 'package:kitchen_wish_well/features/couple/domain/couple_models.dart';
import 'package:kitchen_wish_well/features/notifications/domain/notification_models.dart';
import 'package:kitchen_wish_well/features/notifications/presentation/providers/notifications_controller.dart';

final boundSessionOverride =
    sessionControllerProvider.overrideWith(() => _TestSessionController());
final signedOutSessionOverride =
    sessionControllerProvider.overrideWith(() => _SignedOutSessionController());
final notificationsOverride = notificationsControllerProvider
    .overrideWith(() => _TestNotificationsController());

class _SignedOutSessionController extends SessionController {
  @override
  Future<SessionState> build() async {
    return const SessionState();
  }
}

class _TestNotificationsController extends NotificationsController {
  @override
  Future<NotificationsState> build() async {
    return NotificationsState(
      unreadCount: 1,
      items: [
        AppNotification(
          id: 'notice-1',
          type: 'WISH_CREATED',
          title: '有新的吃饭愿望',
          content: '她许愿：可乐鸡翅',
          createdAt: DateTime(2026, 7, 4),
        ),
      ],
    );
  }

  @override
  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      NotificationsState(
        unreadCount: 0,
        items: [
          for (final item in current.items)
            if (item.id == id)
              item.copyWith(readAt: DateTime(2026, 7, 4))
            else
              item,
        ],
      ),
    );
  }
}

class _TestSessionController extends SessionController {
  @override
  Future<SessionState> build() async {
    return const SessionState(
      token: 'test-token',
      user: AuthUser(id: 'me', nickname: '我', email: 'me@example.com'),
      binding: CoupleBinding(
        status: CoupleBindingStatus.bound,
        partner: AuthUser(
            id: 'partner', nickname: '她', email: 'partner@example.com'),
        coupleId: 'demo-couple',
      ),
    );
  }

  @override
  Future<void> updateProfile({
    required String nickname,
    String? avatarUrl,
    UserGender? gender,
  }) async {
    final current = state.value;
    if (current == null || current.user == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        user: current.user!.copyWith(
          nickname: nickname,
          avatarUrl: avatarUrl,
          gender: gender,
        ),
      ),
    );
  }

  @override
  Future<void> unbind() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        binding: const CoupleBinding(status: CoupleBindingStatus.unbound),
      ),
    );
  }
}
