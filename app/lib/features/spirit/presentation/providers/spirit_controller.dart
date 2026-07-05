import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_controller.dart';
import '../../data/spirit_repository.dart';
import '../../domain/spirit_models.dart';

final spiritRepositoryProvider =
    Provider.family<SpiritRepository, String?>((ref, token) {
  return SpiritRepository(token: token);
});

final spiritControllerProvider =
    AsyncNotifierProvider<SpiritController, SpiritState>(SpiritController.new);

class SpiritState {
  const SpiritState({
    this.home,
    this.logs = const [],
    this.transactions = const [],
    this.isBound = false,
    this.isRefreshing = false,
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  final SpiritHome? home;
  final List<SpiritGrowthLog> logs;
  final List<PointTransaction> transactions;
  final bool isBound;
  final bool isRefreshing;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  CoupleSpirit? get spirit => home?.spirit;
  PointAccount? get points => home?.points;
  CheckinStatus? get checkin => home?.checkin;

  SpiritState copyWith({
    SpiritHome? home,
    List<SpiritGrowthLog>? logs,
    List<PointTransaction>? transactions,
    bool? isBound,
    bool? isRefreshing,
    bool? isMutating,
    Object? feedbackMessage = _unchanged,
    Object? errorMessage = _unchanged,
  }) {
    return SpiritState(
      home: home ?? this.home,
      logs: logs ?? this.logs,
      transactions: transactions ?? this.transactions,
      isBound: isBound ?? this.isBound,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage: identical(feedbackMessage, _unchanged)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _unchanged = Object();

class SpiritController extends AsyncNotifier<SpiritState> {
  late SpiritRepository _repository;

  @override
  Future<SpiritState> build() async {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    _repository = ref.watch(spiritRepositoryProvider(session?.token));
    if (session?.token == null || session?.isBound != true) {
      return const SpiritState(isBound: false);
    }

    try {
      final home = await _repository.fetchHome();
      return SpiritState(home: home, isBound: true);
    } catch (error) {
      _handleUnauthorized(error);
      return SpiritState(
        isBound: true,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> refresh({bool showRefreshing = true}) async {
    final current = state.valueOrNull;
    if (current?.isBound != true) {
      return;
    }
    if (showRefreshing) {
      state = AsyncData(current!.copyWith(
        isRefreshing: true,
        errorMessage: null,
        feedbackMessage: null,
      ));
    }
    try {
      final home = await _repository.fetchHome();
      state = AsyncData(
        (state.valueOrNull ?? const SpiritState(isBound: true)).copyWith(
          home: home,
          isBound: true,
          isRefreshing: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> refreshAfterReward() => refresh(showRefreshing: false);

  Future<void> loadDetails() async {
    final current = state.valueOrNull;
    if (current?.isBound != true) {
      return;
    }
    try {
      final results = await Future.wait<Object>([
        _repository.fetchLogs(),
        _repository.fetchTransactions(),
      ]);
      state = AsyncData(current!.copyWith(
        logs: results[0] as List<SpiritGrowthLog>,
        transactions: results[1] as List<PointTransaction>,
        errorMessage: null,
      ));
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> checkin() async {
    final current = state.valueOrNull;
    if (current?.isBound != true || current!.isMutating) {
      return;
    }
    state = AsyncData(current.copyWith(
      isMutating: true,
      errorMessage: null,
      feedbackMessage: null,
    ));
    try {
      final result = await _repository.checkin();
      final previousHome = current.home;
      if (previousHome == null) {
        await refresh(showRefreshing: false);
      } else {
        state = AsyncData(current.copyWith(
          home: SpiritHome(
            spirit: result.spirit ?? previousHome.spirit,
            points: result.points,
            checkin: result.status,
          ),
          isMutating: false,
          feedbackMessage: result.alreadyCheckedIn ? '今天已经签到过啦' : '签到成功，积分到账',
          errorMessage: null,
        ));
      }
      await loadDetails();
    } catch (error) {
      _fail(error, mutating: true);
    }
  }

  Future<void> feed(FeedType type) async {
    final current = state.valueOrNull;
    if (current?.isBound != true || current!.isMutating) {
      return;
    }
    state = AsyncData(current.copyWith(
      isMutating: true,
      errorMessage: null,
      feedbackMessage: null,
    ));
    try {
      final result = await _repository.feed(type);
      final nextHome = SpiritHome(
        spirit: result.spirit,
        points: result.points,
        checkin: current.home!.checkin,
      );
      final message = result.stageChanged
          ? '精灵进入了${spiritStageLabel(result.spirit.stage)}'
          : result.levelUp
              ? '精灵升级到 Lv.${result.spirit.level}'
              : '${feedTypeLabel(type)}完成，经验增加';
      state = AsyncData(current.copyWith(
        home: nextHome,
        isMutating: false,
        feedbackMessage: message,
        errorMessage: null,
      ));
      await loadDetails();
    } catch (error) {
      _fail(error, mutating: true);
    }
  }

  Future<void> rename(String name) async {
    final trimmed = name.trim();
    final current = state.valueOrNull;
    if (trimmed.isEmpty || current?.home == null || current!.isMutating) {
      return;
    }
    state = AsyncData(current.copyWith(
      isMutating: true,
      errorMessage: null,
      feedbackMessage: null,
    ));
    try {
      final spirit = await _repository.renameSpirit(trimmed);
      state = AsyncData(current.copyWith(
        home: SpiritHome(
          spirit: spirit,
          points: current.home!.points,
          checkin: current.home!.checkin,
        ),
        isMutating: false,
        feedbackMessage: '名字更新好了',
        errorMessage: null,
      ));
    } catch (error) {
      _fail(error, mutating: true);
    }
  }

  Future<void> updateStyle(SpiritStyle style) async {
    final current = state.valueOrNull;
    if (current?.home == null || current!.isMutating) {
      return;
    }
    if (current.home!.spirit.style == style) {
      return;
    }
    state = AsyncData(current.copyWith(
      isMutating: true,
      errorMessage: null,
      feedbackMessage: null,
    ));
    try {
      final spirit = await _repository.updateStyle(style);
      state = AsyncData(current.copyWith(
        home: SpiritHome(
          spirit: spirit,
          points: current.home!.points,
          checkin: current.home!.checkin,
        ),
        isMutating: false,
        feedbackMessage: '精灵款式已切换为${spiritStyleLabel(style)}',
        errorMessage: null,
      ));
    } catch (error) {
      _fail(error, mutating: true);
    }
  }

  void _fail(Object error, {bool mutating = false}) {
    _handleUnauthorized(error);
    final current = state.valueOrNull ?? const SpiritState(isBound: true);
    state = AsyncData(current.copyWith(
      isRefreshing: false,
      isMutating: mutating ? false : current.isMutating,
      errorMessage: _errorMessage(error),
    ));
  }

  void _handleUnauthorized(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      ref.read(sessionControllerProvider.notifier).logout();
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return '登录已失效，请重新登录';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return '网络超时，请稍后重试';
      }
    }
    return '精灵状态同步失败，请稍后重试';
  }
}
