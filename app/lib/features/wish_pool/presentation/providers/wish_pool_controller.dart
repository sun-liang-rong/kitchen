import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_controller.dart';
import '../../../auth/domain/auth_models.dart';
import '../../data/wish_pool_repository.dart';
import '../../domain/models/kitchen_models.dart';

final wishPoolControllerProvider =
    NotifierProvider<WishPoolController, WishPoolState>(WishPoolController.new);

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
    _repository = WishPoolRepository(token: session?.token);
    Future.microtask(_loadRemoteSnapshot);
    return _seedState(
      meId: session?.user?.id ?? 'me',
      meName: session?.user?.nickname ?? '我',
      meGender: session?.user?.gender ?? UserGender.unspecified,
      partnerId: session?.binding.partner?.id ?? 'partner',
      partnerName: session?.binding.partner?.nickname ??
          thirdPersonPronoun(UserGender.unspecified),
      partnerGender: session?.binding.partner?.gender ?? UserGender.unspecified,
    );
  }

  WishPoolState _seedState({
    required String meId,
    required String meName,
    required UserGender meGender,
    required String partnerId,
    required String partnerName,
    required UserGender partnerGender,
  }) {
    final now = DateTime.now();
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
      kitchenStatuses: {
        meId: KitchenStatusEntry(
          userId: meId,
          status: KitchenStatusValue.normal,
          note: '今天正常做饭',
        ),
        partnerId: KitchenStatusEntry(
          userId: partnerId,
          status: KitchenStatusValue.tired,
          note: '她今天有点累，适合简单点',
        ),
      },
      wishes: [
        Wish(
          id: _nextId('wish'),
          creatorId: partnerId,
          title: '可乐鸡翅',
          wishType: 'DISH',
          feelingTags: const [],
          desiredTime: '今晚',
          intensity: '今天特别想吃',
          substituteOption: '可以做轻松版',
          helperTasks: const ['洗菜', '饭后收桌'],
          status: WishStatus.inPool,
          createdAt: now,
          updatedAt: now,
          responses: const [],
        ),
        Wish(
          id: _nextId('wish'),
          creatorId: meId,
          title: '今晚想喝汤',
          wishType: 'FEELING',
          feelingTags: const ['有汤', '热乎一点'],
          desiredTime: '这周',
          intensity: '这周想吃',
          substituteOption: '家里有什么就做什么',
          helperTasks: const ['洗碗'],
          status: WishStatus.inPool,
          createdAt: now,
          updatedAt: now,
          responses: const [],
        ),
      ],
      fulfillments: const [],
      dishes: [
        HomeDish(
          id: _nextId('dish'),
          name: '番茄鸡蛋面',
          cookOwner: meId,
          suitableTimeTags: const ['今晚', '快手'],
          difficulty: '简单',
          tasteTags: const ['热乎', '快手'],
          isFavorite: true,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  Future<void> _loadRemoteSnapshot() async {
    try {
      final session = ref.read(sessionControllerProvider).valueOrNull;
      final snapshot = await _repository.fetchSnapshot(
        me: session?.user,
        partner: session?.binding.partner,
        creatorFilter: state.creatorFilter,
        statusFilter: state.selectedStatus,
        dishQuery: state.dishQuery,
        dishFilters: state.dishFilters,
      );
      state = state.copyWith(
        users: snapshot.users.isEmpty ? state.users : snapshot.users,
        wishes: snapshot.wishes,
        kitchenStatuses: snapshot.kitchenStatuses,
        fulfillments: snapshot.fulfillments,
        dishes: snapshot.dishes,
      );
    } catch (_) {
      // Keep the local seed data available when the API is not running.
    }
  }

  Future<void> _refreshRemote() async {
    try {
      final session = ref.read(sessionControllerProvider).valueOrNull;
      final snapshot = await _repository.fetchSnapshot(
        me: session?.user,
        partner: session?.binding.partner,
        creatorFilter: state.creatorFilter,
        statusFilter: state.selectedStatus,
        dishQuery: state.dishQuery,
        dishFilters: state.dishFilters,
      );
      state = state.copyWith(
        users: snapshot.users.isEmpty ? state.users : snapshot.users,
        wishes: snapshot.wishes,
        kitchenStatuses: snapshot.kitchenStatuses,
        fulfillments: snapshot.fulfillments,
        dishes: snapshot.dishes,
      );
    } catch (_) {
      // The optimistic local update remains visible if the refresh fails.
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
    state = state.copyWith(wishes: [wish, ...state.wishes]);
    _repository
        .createWish(
          title: title,
          wishType: wishType,
          feelingTags: feelingTags,
          desiredTime: desiredTime,
          intensity: intensity,
          substituteOption: substituteOption,
          helperTasks: helperTasks,
        )
        .then((_) => _refreshRemote())
        .catchError((_) {});
    return wish;
  }

  void deleteWish(String wishId) {
    final wish = wishById(wishId);
    if (wish.status == WishStatus.fulfilled) {
      throw StateError('已兑现的愿望不能删除');
    }
    state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id != wishId) item,
      ],
    );
    _repository
        .deleteWish(wishId)
        .then((_) => _refreshRemote())
        .catchError((_) {});
  }

  Future<Wish> refreshWish(String wishId) async {
    final wish = await _repository.fetchWish(wishId);
    _replaceWish(wish);
    return wish;
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

    _replaceWish(updated);
    _repository
        .respondToWish(
          wishId: wishId,
          type: type,
          proposedTitle: proposedTitle,
          proposedTime: proposedTime,
          reasonTags: reasonTags,
          reasonText: reasonText,
        )
        .then((wish) => _replaceWish(wish))
        .catchError((_) {});
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
    _replaceWish(updated);
    _repository
        .confirmResponse(current.id)
        .then((wish) => _replaceWish(wish))
        .catchError((_) {});
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
    _replaceWish(updated);
    _repository
        .reopenResponse(current.id)
        .then((wish) => _replaceWish(wish))
        .catchError((_) {});
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
            _dishFromFulfillment(wish, fulfillment),
            ...state.dishes.where((dish) => dish.name != actualDishName.trim()),
          ]
        : state.dishes;

    state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id == wishId) updatedWish else item,
      ],
      fulfillments: nextFulfillments,
      dishes: nextDishes,
    );
    _repository
        .fulfillWish(
          wishId: wishId,
          actualDishName: actualDishName,
          helperTasksDone: helperTasksDone,
          feedbackTags: feedbackTags,
          note: note,
          addToDishes: addToDishes,
        )
        .then((_) => _refreshRemote())
        .catchError((_) {});
    return fulfillment;
  }

  HomeDish addDish({
    required String name,
    String? cookOwner,
    List<String> suitableTimeTags = const [],
    String difficulty = '普通',
    List<String> tasteTags = const [],
    bool isFavorite = false,
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
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(dishes: [dish, ...state.dishes]);
    _repository
        .addDish(
          name: name,
          cookOwner: cookOwner,
          suitableTimeTags: suitableTimeTags,
          difficulty: difficulty,
          tasteTags: tasteTags,
          isFavorite: isFavorite,
        )
        .then((_) => _refreshRemote())
        .catchError((_) {});
    return dish;
  }

  void updateDish(String id, HomeDish Function(HomeDish dish) update) {
    HomeDish? updatedDish;
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
          .then((_) => _refreshRemote())
          .catchError((_) {});
    }
  }

  void setKitchenStatus(
    String userId,
    KitchenStatusValue status, {
    String? note,
  }) {
    state = state.copyWith(
      kitchenStatuses: {
        ...state.kitchenStatuses,
        userId: KitchenStatusEntry(userId: userId, status: status, note: note),
      },
    );
    _repository
        .setKitchenStatus(userId, status, note: note)
        .then((_) => _refreshRemote())
        .catchError((_) {});
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

  HomeDish _dishFromFulfillment(Wish wish, WishFulfillment fulfillment) {
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
      createdAt: now,
      updatedAt: now,
    );
  }
}
