import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_controller.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../spirit/presentation/providers/spirit_controller.dart';
import '../../data/wish_pool_repository.dart';
import '../../domain/models/kitchen_models.dart';

final wishPoolControllerProvider =
    NotifierProvider<WishPoolController, WishPoolState>(WishPoolController.new);

final wishPoolRepositoryProvider =
    Provider.family<WishPoolRepository, String?>((ref, token) {
  return WishPoolRepository(token: token);
});

class WishPoolState {
  const WishPoolState({
    required this.users,
    required this.wishes,
    required this.kitchenStatuses,
    required this.fulfillments,
    required this.dishes,
    this.selectedStatus,
    this.creatorFilter = WishCreatorFilter.all,
    this.dishQuery = '',
    this.dishFilters = const DishFilters(),
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final List<AppUser> users;
  final List<Wish> wishes;
  final Map<String, KitchenStatusEntry> kitchenStatuses;
  final List<WishFulfillment> fulfillments;
  final List<HomeDish> dishes;
  final WishStatus? selectedStatus;
  final WishCreatorFilter creatorFilter;
  final String dishQuery;
  final DishFilters dishFilters;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  AppUser get me => users.firstWhere((user) => user.isMe);
  AppUser get partner => users.firstWhere((user) => !user.isMe);

  List<Wish> get visibleWishes {
    Iterable<Wish> items = wishes;
    if (creatorFilter == WishCreatorFilter.me) {
      items = items.where((wish) => wish.creatorId == me.id);
    } else if (creatorFilter == WishCreatorFilter.partner) {
      items = items.where((wish) => wish.creatorId == partner.id);
    }
    final selected = selectedStatus;
    if (selected != null) {
      items = items.where((wish) => wish.status == selected);
    }
    return items.toList();
  }

  WishPoolState copyWith({
    List<AppUser>? users,
    List<Wish>? wishes,
    Map<String, KitchenStatusEntry>? kitchenStatuses,
    List<WishFulfillment>? fulfillments,
    List<HomeDish>? dishes,
    Object? selectedStatus = _unchanged,
    WishCreatorFilter? creatorFilter,
    String? dishQuery,
    DishFilters? dishFilters,
    bool? isLoading,
    bool? isRefreshing,
    Object? errorMessage = _unchanged,
  }) {
    return WishPoolState(
      users: users ?? this.users,
      wishes: wishes ?? this.wishes,
      kitchenStatuses: kitchenStatuses ?? this.kitchenStatuses,
      fulfillments: fulfillments ?? this.fulfillments,
      dishes: dishes ?? this.dishes,
      selectedStatus: identical(selectedStatus, _unchanged)
          ? this.selectedStatus
          : selectedStatus as WishStatus?,
      creatorFilter: creatorFilter ?? this.creatorFilter,
      dishQuery: dishQuery ?? this.dishQuery,
      dishFilters: dishFilters ?? this.dishFilters,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _unchanged = Object();

class WishPoolController extends Notifier<WishPoolState> {
  int _counter = 0;
  late WishPoolRepository _repository;

  @override
  WishPoolState build() {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    _repository = ref.watch(wishPoolRepositoryProvider(session?.token));
    Future.microtask(_loadRemoteSnapshot);
    return _emptyState(
      meId: session?.user?.id ?? 'me',
      meName: session?.user?.nickname ?? '我',
      meGender: session?.user?.gender ?? UserGender.unspecified,
      partnerId: session?.binding.partner?.id ?? 'partner',
      partnerName: session?.binding.partner?.nickname ??
          thirdPersonPronoun(UserGender.unspecified),
      partnerGender: session?.binding.partner?.gender ?? UserGender.unspecified,
    );
  }

  WishPoolState _emptyState({
    required String meId,
    required String meName,
    required UserGender meGender,
    required String partnerId,
    required String partnerName,
    required UserGender partnerGender,
  }) {
    final users = [
      AppUser(id: meId, nickname: meName, isMe: true, gender: meGender),
      AppUser(
          id: partnerId,
          nickname: partnerName,
          isMe: false,
          gender: partnerGender),
    ];

    return WishPoolState(
      users: users,
      kitchenStatuses: const {},
      wishes: const [],
      fulfillments: const [],
      dishes: const [],
    );
  }

  Future<void> _loadRemoteSnapshot() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final snapshot = await _fetchSnapshot();
      _applySnapshot(snapshot, isLoading: false);
    } catch (error) {
      _handleFailure(error, fallback: state.copyWith(isLoading: false));
    }
  }

  Future<void> retry() => _loadRemoteSnapshot();

  Future<void> _refreshRemote({bool showRefreshing = true}) async {
    try {
      if (showRefreshing) {
        state = state.copyWith(isRefreshing: true, errorMessage: null);
      }
      final snapshot = await _fetchSnapshot();
      _applySnapshot(snapshot, isRefreshing: false);
    } catch (error) {
      _handleFailure(error, fallback: state.copyWith(isRefreshing: false));
    }
  }

  void selectStatus(WishStatus? status) {
    state = state.copyWith(selectedStatus: status);
    _refreshRemote();
  }

  void selectCreator(WishCreatorFilter filter) {
    state = state.copyWith(creatorFilter: filter);
    _refreshRemote();
  }

  void searchDishes(String query) {
    state = state.copyWith(dishQuery: query);
    _refreshRemote();
  }

  void applyDishFilters(DishFilters filters) {
    state = state.copyWith(dishFilters: filters);
    _refreshRemote();
  }

  void clearDishFilters() {
    state = state.copyWith(dishFilters: const DishFilters());
    _refreshRemote();
  }

  Wish createWish({
    required String title,
    String wishType = 'DISH',
    List<String> feelingTags = const [],
    String desiredTime = '今晚',
    String intensity = '今天想吃',
    String substituteOption = '可以换类似的',
    List<String> helperTasks = const [],
    String? creatorId,
  }) {
    final now = DateTime.now();
    final wish = Wish(
      id: _nextId('wish'),
      creatorId: creatorId ?? state.me.id,
      title: title.trim(),
      wishType: wishType,
      feelingTags: feelingTags,
      desiredTime: desiredTime,
      intensity: intensity,
      substituteOption: substituteOption,
      helperTasks: helperTasks,
      status: WishStatus.inPool,
      createdAt: now,
      updatedAt: now,
      responses: const [],
    );
    final previous = state;
    state = state.copyWith(wishes: [wish, ...state.wishes]);
    _runWrite(previous, () async {
      await _repository.createWish(
        title: title,
        wishType: wishType,
        feelingTags: feelingTags,
        desiredTime: desiredTime,
        intensity: intensity,
        substituteOption: substituteOption,
        helperTasks: helperTasks,
      );
      await _refreshRemote(showRefreshing: false);
      await _refreshSpirit();
    });
    return wish;
  }

  void deleteWish(String wishId) {
    final wish = wishById(wishId);
    if (wish.status == WishStatus.fulfilled) {
      throw StateError('已兑现的愿望不能删除');
    }
    final previous = state;
    state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id != wishId) item,
      ],
    );
    _repository
        .deleteWish(wishId)
        .then((_) => _refreshRemote(showRefreshing: false))
        .catchError(
            (Object error) => _handleFailure(error, fallback: previous));
  }

  Future<Wish> refreshWish(String wishId) async {
    try {
      final wish = await _repository.fetchWish(wishId);
      _replaceWish(wish);
      state = state.copyWith(errorMessage: null);
      return wish;
    } catch (error) {
      _handleFailure(error, fallback: state);
      rethrow;
    }
  }

  Wish respondToWish({
    required String wishId,
    required WishResponseType type,
    String? responderId,
    String? proposedTitle,
    String? proposedTime,
    List<String> reasonTags = const [],
    String? reasonText,
  }) {
    final wish = wishById(wishId);
    if (wish.creatorId == state.me.id) {
      throw StateError('只能回应对方许下的愿望');
    }
    final response = WishResponse(
      id: _nextId('response'),
      wishId: wishId,
      responderId: responderId ?? state.me.id,
      type: type,
      proposedTitle: proposedTitle,
      proposedTime: proposedTime,
      reasonTags: reasonTags,
      reasonText: reasonText,
      needsConfirmation: _needsConfirmation(type),
      createdAt: DateTime.now(),
    );

    final updated = wish.copyWith(
      status: response.needsConfirmation
          ? WishStatus.pendingConfirmation
          : type == WishResponseType.shelve
              ? WishStatus.shelved
              : WishStatus.claimed,
      currentResponseId: response.id,
      updatedAt: DateTime.now(),
      responses: [...wish.responses, response],
    );

    final previous = state;
    _replaceWish(updated);
    _runWrite(
      previous,
      () async {
        final saved = await _repository.respondToWish(
          wishId: wishId,
          type: type,
          proposedTitle: proposedTitle,
          proposedTime: proposedTime,
          reasonTags: reasonTags,
          reasonText: reasonText,
        );
        _replaceWish(saved);
        state = state.copyWith(errorMessage: null);
        await _refreshSpirit();
      },
    );
    return updated;
  }

  Wish confirmResponse(String wishId) {
    final wish = wishById(wishId);
    if (wish.creatorId != state.me.id) {
      throw StateError('只有许愿人可以确认回应');
    }
    final current = wish.currentResponse;
    if (current == null) {
      throw StateError('没有可确认的回应');
    }
    final confirmed = current.copyWith(
      needsConfirmation: false,
      confirmedAt: DateTime.now(),
    );
    final responses = [
      for (final response in wish.responses)
        if (response.id == confirmed.id) confirmed else response,
    ];
    final updated = wish.copyWith(
      status: _confirmedStatus(current.type),
      updatedAt: DateTime.now(),
      responses: responses,
    );
    final previous = state;
    _replaceWish(updated);
    _runWrite(
      previous,
      () async {
        final saved = await _repository.confirmResponse(current.id);
        _replaceWish(saved);
        state = state.copyWith(errorMessage: null);
        await _refreshSpirit();
      },
    );
    return updated;
  }

  Wish reopenResponse(String wishId) {
    final wish = wishById(wishId);
    if (wish.creatorId != state.me.id) {
      throw StateError('只有许愿人可以让愿望继续商量');
    }
    final current = wish.currentResponse;
    if (current == null) {
      throw StateError('没有可继续商量的回应');
    }
    final updated = wish.copyWith(
      status: WishStatus.inPool,
      currentResponseId: null,
      updatedAt: DateTime.now(),
    );
    final previous = state;
    _replaceWish(updated);
    _runWrite(
      previous,
      () async {
        final saved = await _repository.reopenResponse(current.id);
        _replaceWish(saved);
        state = state.copyWith(errorMessage: null);
      },
    );
    return updated;
  }

  WishFulfillment fulfillWish({
    required String wishId,
    required String actualDishName,
    String? fulfillerId,
    List<String> helperTasksDone = const [],
    List<String> feedbackTags = const [],
    String? note,
    bool addToDishes = false,
    String? imageUrl,
  }) {
    final wish = wishById(wishId);
    if (!_canFulfill(wish.status)) {
      throw StateError('只有已确认安排的愿望可以记录兑现');
    }
    final fulfillment = WishFulfillment(
      id: _nextId('fulfillment'),
      wishId: wishId,
      fulfillerId: fulfillerId ?? state.me.id,
      actualDishName: actualDishName.trim(),
      helperTasksDone: helperTasksDone,
      feedbackTags: feedbackTags,
      note: note,
      addToDishes: addToDishes,
      createdAt: DateTime.now(),
    );

    final updatedWish = wish.copyWith(
      status: WishStatus.fulfilled,
      updatedAt: DateTime.now(),
    );
    final nextFulfillments = [
      fulfillment,
      ...state.fulfillments.where((item) => item.wishId != wishId),
    ];
    final nextDishes = addToDishes
        ? [
            _dishFromFulfillment(wish, fulfillment, imageUrl: imageUrl),
            ...state.dishes.where((dish) => dish.name != actualDishName.trim()),
          ]
        : state.dishes;

    final previous = state;
    state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id == wishId) updatedWish else item,
      ],
      fulfillments: nextFulfillments,
      dishes: nextDishes,
    );
    _runWrite(previous, () async {
      await _repository.fulfillWish(
        wishId: wishId,
        actualDishName: actualDishName,
        helperTasksDone: helperTasksDone,
        feedbackTags: feedbackTags,
        note: note,
        addToDishes: addToDishes,
        imageUrl: imageUrl,
      );
      await _refreshRemote(showRefreshing: false);
      await _refreshSpirit();
    });
    return fulfillment;
  }

  HomeDish addDish({
    required String name,
    String? cookOwner,
    List<String> suitableTimeTags = const [],
    String difficulty = '普通',
    List<String> tasteTags = const [],
    bool isFavorite = false,
    String? imageUrl,
  }) {
    final now = DateTime.now();
    final dish = HomeDish(
      id: _nextId('dish'),
      name: name.trim(),
      cookOwner: cookOwner,
      suitableTimeTags: suitableTimeTags,
      difficulty: difficulty,
      tasteTags: tasteTags,
      isFavorite: isFavorite,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );
    final previous = state;
    state = state.copyWith(dishes: [dish, ...state.dishes]);
    _runWrite(previous, () async {
      await _repository.addDish(
        name: name,
        cookOwner: cookOwner,
        suitableTimeTags: suitableTimeTags,
        difficulty: difficulty,
        tasteTags: tasteTags,
        isFavorite: isFavorite,
        imageUrl: imageUrl,
      );
      await _refreshRemote(showRefreshing: false);
      await _refreshSpirit();
    });
    return dish;
  }

  void updateDish(String id, HomeDish Function(HomeDish dish) update) {
    HomeDish? updatedDish;
    final previous = state;
    state = state.copyWith(
      dishes: [
        for (final dish in state.dishes)
          if (dish.id == id) updatedDish = update(dish) else dish,
      ],
    );
    final dish = updatedDish;
    if (dish != null) {
      _repository
          .updateDish(id, dish)
          .then((_) => _refreshRemote(showRefreshing: false))
          .catchError(
              (Object error) => _handleFailure(error, fallback: previous));
    }
  }

  void deleteDish(String id) {
    final previous = state;
    state = state.copyWith(
      dishes: [
        for (final dish in state.dishes)
          if (dish.id != id) dish,
      ],
    );
    _repository
        .deleteDish(id)
        .then((_) => _refreshRemote(showRefreshing: false))
        .catchError(
            (Object error) => _handleFailure(error, fallback: previous));
  }

  void setKitchenStatus(
    String userId,
    KitchenStatusValue status, {
    String? note,
  }) {
    final previous = state;
    state = state.copyWith(
      kitchenStatuses: {
        ...state.kitchenStatuses,
        userId: KitchenStatusEntry(userId: userId, status: status, note: note),
      },
    );
    _repository
        .setKitchenStatus(userId, status, note: note)
        .then((_) => _refreshRemote(showRefreshing: false))
        .catchError(
            (Object error) => _handleFailure(error, fallback: previous));
  }

  Wish wishById(String id) {
    return state.wishes.firstWhere((wish) => wish.id == id);
  }

  String _nextId(String prefix) {
    _counter += 1;
    return '$prefix-$_counter';
  }

  void _replaceWish(Wish wish) {
    state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id == wish.id) wish else item,
      ],
    );
  }

  Future<WishPoolSnapshot> _fetchSnapshot() {
    final session = ref.read(sessionControllerProvider).valueOrNull;
    return _repository.fetchSnapshot(
      me: session?.user,
      partner: session?.binding.partner,
      creatorFilter: state.creatorFilter,
      statusFilter: state.selectedStatus,
      dishQuery: state.dishQuery,
      dishFilters: state.dishFilters,
    );
  }

  void _applySnapshot(
    WishPoolSnapshot snapshot, {
    bool? isLoading,
    bool? isRefreshing,
  }) {
    state = state.copyWith(
      users: snapshot.users.isEmpty ? state.users : snapshot.users,
      wishes: snapshot.wishes,
      kitchenStatuses: snapshot.kitchenStatuses,
      fulfillments: snapshot.fulfillments,
      dishes: snapshot.dishes,
      isLoading: isLoading,
      isRefreshing: isRefreshing,
      errorMessage: null,
    );
  }

  void _handleFailure(Object error, {required WishPoolState fallback}) {
    if (_isUnauthorized(error)) {
      ref.read(sessionControllerProvider.notifier).logout();
    }
    state = fallback.copyWith(
      isLoading: false,
      isRefreshing: false,
      errorMessage: _errorMessage(error),
    );
  }

  void _runWrite(WishPoolState previous, Future<void> Function() action) {
    unawaited(
      action().catchError(
        (Object error) => _handleFailure(error, fallback: previous),
      ),
    );
  }

  Future<void> _refreshSpirit() async {
    await ref.read(spiritControllerProvider.notifier).refreshAfterReward();
  }

  bool _isUnauthorized(Object error) {
    return error is DioException && error.response?.statusCode == 401;
  }

  String _errorMessage(Object error) {
    if (_isUnauthorized(error)) {
      return '登录已失效，请重新登录';
    }
    if (error is DioException) {
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
    return '同步失败，请稍后重试';
  }

  bool _needsConfirmation(WishResponseType type) {
    return {
      WishResponseType.lightVersion,
      WishResponseType.alternative,
      WishResponseType.defer,
      WishResponseType.together,
    }.contains(type);
  }

  WishStatus _confirmedStatus(WishResponseType type) {
    return switch (type) {
      WishResponseType.defer => WishStatus.deferred,
      WishResponseType.together => WishStatus.together,
      _ => WishStatus.claimed,
    };
  }

  bool _canFulfill(WishStatus status) {
    return {
      WishStatus.claimed,
      WishStatus.deferred,
      WishStatus.together,
    }.contains(status);
  }

  HomeDish _dishFromFulfillment(
    Wish wish,
    WishFulfillment fulfillment, {
    String? imageUrl,
  }) {
    final now = DateTime.now();
    return HomeDish(
      id: _nextId('dish'),
      name: fulfillment.actualDishName,
      cookOwner: fulfillment.fulfillerId,
      suitableTimeTags: [wish.desiredTime],
      difficulty: '普通',
      tasteTags: fulfillment.feedbackTags,
      isFavorite: true,
      sourceWishId: wish.id,
      lastFeedback: fulfillment.feedbackTags.join('、'),
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<String> uploadDishImage({
    required List<int> bytes,
    required String filename,
  }) {
    return _repository.uploadDishImage(bytes: bytes, filename: filename);
  }
}
