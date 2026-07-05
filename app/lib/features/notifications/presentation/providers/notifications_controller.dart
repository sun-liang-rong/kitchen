import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_controller.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_models.dart';

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsState>(
        NotificationsController.new);

class NotificationsState {
  const NotificationsState({
    required this.items,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int unreadCount;
}

class NotificationsController extends AsyncNotifier<NotificationsState> {
  late NotificationsRepository _repository;
  Timer? _pollingTimer;

  @override
  Future<NotificationsState> build() async {
    final token = ref.watch(sessionControllerProvider).valueOrNull?.token;
    _repository = NotificationsRepository(token: token);
    _pollingTimer?.cancel();
    ref.onDispose(() => _pollingTimer?.cancel());
    if (token == null) {
      return const NotificationsState(items: [], unreadCount: 0);
    }
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      poll();
    });
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> poll() async {
    try {
      state = AsyncData(await _load());
    } catch (_) {
      // Keep the last visible notification state if polling fails.
    }
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final now = DateTime.now();
    final items = [
      for (final item in current.items)
        if (item.id == id) item.copyWith(readAt: now) else item,
    ];
    state = AsyncData(
      NotificationsState(
        items: items,
        unreadCount: items.where((item) => item.isUnread).length,
      ),
    );
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final now = DateTime.now();
    state = AsyncData(
      NotificationsState(
        items: [for (final item in current.items) item.copyWith(readAt: now)],
        unreadCount: 0,
      ),
    );
  }

  Future<NotificationsState> _load() async {
    final items = await _repository.list();
    final count = await _repository.unreadCount();
    return NotificationsState(items: items, unreadCount: count);
  }
}
