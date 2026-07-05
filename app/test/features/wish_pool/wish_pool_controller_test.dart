import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_wish_well/features/wish_pool/data/wish_pool_repository.dart';
import 'package:kitchen_wish_well/features/wish_pool/domain/models/kitchen_models.dart';
import 'package:kitchen_wish_well/features/wish_pool/presentation/providers/wish_pool_controller.dart';

void main() {
  test('runs wish pool state loop', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final partner = container.read(wishPoolControllerProvider).partner;
    final wish = notifier.createWish(
      title: '糖醋排骨',
      desiredTime: '周末',
      intensity: '周末认真安排',
      helperTasks: ['买菜', '洗碗'],
      creatorId: partner.id,
    );

    expect(notifier.wishById(wish.id).status, WishStatus.inPool);

    final responded = notifier.respondToWish(
      wishId: wish.id,
      type: WishResponseType.fulfillTonight,
      reasonTags: ['今天有点累'],
    );

    expect(responded.status, WishStatus.claimed);
    expect(responded.currentResponse?.needsConfirmation, false);
    expect(responded.currentResponse?.responderId,
        container.read(wishPoolControllerProvider).me.id);

    final fulfillment = notifier.fulfillWish(
      wishId: wish.id,
      actualDishName: '可乐鸡翅',
      helperTasksDone: ['洗碗'],
      feedbackTags: ['今天很好吃'],
      addToDishes: true,
    );

    final state = container.read(wishPoolControllerProvider);
    expect(fulfillment.fulfillerId, state.me.id);
    expect(notifier.wishById(wish.id).status, WishStatus.fulfilled);
    expect(state.fulfillments, hasLength(1));
    expect(state.dishes.any((dish) => dish.name == '可乐鸡翅'), true);
  });

  test('filters wishes by creator and status', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final partner = container.read(wishPoolControllerProvider).partner;
    notifier.createWish(title: '我想喝汤');
    notifier.createWish(title: '她想吃面', creatorId: partner.id);

    expect(container.read(wishPoolControllerProvider).visibleWishes.length, 2);

    notifier.selectCreator(WishCreatorFilter.me);
    final mine = container.read(wishPoolControllerProvider);
    expect(
        mine.visibleWishes.every((wish) => wish.creatorId == mine.me.id), true);

    notifier.selectCreator(WishCreatorFilter.partner);
    final partners = container.read(wishPoolControllerProvider);
    expect(
        partners.visibleWishes
            .every((wish) => wish.creatorId == partners.partner.id),
        true);

    notifier.selectStatus(WishStatus.fulfilled);
    expect(container.read(wishPoolControllerProvider).visibleWishes, isEmpty);
  });

  test('updates my kitchen status locally', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final me = container.read(wishPoolControllerProvider).me;

    notifier.setKitchenStatus(
      me.id,
      KitchenStatusValue.simpleOnly,
      note: '今天简单吃也可以',
    );

    final entry =
        container.read(wishPoolControllerProvider).kitchenStatuses[me.id];
    expect(entry?.status, KitchenStatusValue.simpleOnly);
    expect(entry?.note, '今天简单吃也可以');
  });

  test('deletes an unfulfilled wish from state', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final wish = notifier.createWish(title: '临时想吃');
    expect(
        container
            .read(wishPoolControllerProvider)
            .wishes
            .any((item) => item.id == wish.id),
        true);

    notifier.deleteWish(wish.id);
    expect(
        container
            .read(wishPoolControllerProvider)
            .wishes
            .any((item) => item.id == wish.id),
        false);
  });

  test('deletes a home dish from state', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final dish = notifier.addDish(
      name: '酸辣土豆丝',
      suitableTimeTags: const ['今晚'],
      difficulty: '简单',
      isFavorite: true,
      imageUrl: '/uploads/dishes/potato.webp',
    );
    expect(dish.imageUrl, '/uploads/dishes/potato.webp');
    expect(
      container
          .read(wishPoolControllerProvider)
          .dishes
          .any((item) => item.id == dish.id),
      true,
    );

    notifier.deleteDish(dish.id);
    expect(
      container
          .read(wishPoolControllerProvider)
          .dishes
          .any((item) => item.id == dish.id),
      false,
    );
  });

  test('does not confirm or reopen another user wish', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final partner = container.read(wishPoolControllerProvider).partner;
    final wish = notifier.createWish(title: '想吃水煮肉片', creatorId: partner.id);
    final responded = notifier.respondToWish(
      wishId: wish.id,
      type: WishResponseType.lightVersion,
      proposedTitle: '青椒肉丝',
    );
    expect(responded.status, WishStatus.pendingConfirmation);

    expect(() => notifier.confirmResponse(wish.id), throwsStateError);
    expect(() => notifier.reopenResponse(wish.id), throwsStateError);
  });

  test('keeps response history when creator asks to discuss again', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final wish = notifier.createWish(title: '想吃糖醋排骨');
    final state = container.read(wishPoolControllerProvider);
    final partner = state.partner;
    final response = WishResponse(
      id: 'response-test',
      wishId: wish.id,
      responderId: partner.id,
      type: WishResponseType.alternative,
      proposedTitle: '可乐鸡翅',
      reasonTags: const ['家里没食材'],
      createdAt: DateTime.now(),
      needsConfirmation: true,
    );
    final responded = wish.copyWith(
      status: WishStatus.pendingConfirmation,
      currentResponseId: response.id,
      responses: [response],
    );
    notifier.state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id == wish.id) responded else item,
      ],
    );

    expect(responded.status, WishStatus.pendingConfirmation);
    expect(responded.responses, hasLength(1));

    final reopened = notifier.reopenResponse(wish.id);

    expect(reopened.status, WishStatus.inPool);
    expect(reopened.currentResponse, isNull);
    expect(reopened.responses, hasLength(1));
    expect(reopened.responses.single.proposedTitle, '可乐鸡翅');
  });

  test('does not fulfill wishes before arrangement is confirmed', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final partner = container.read(wishPoolControllerProvider).partner;
    final inPoolWish =
        notifier.createWish(title: '想吃糖醋排骨', creatorId: partner.id);

    expect(
      () => notifier.fulfillWish(
        wishId: inPoolWish.id,
        actualDishName: '糖醋排骨',
      ),
      throwsStateError,
    );

    final pending = notifier.respondToWish(
      wishId: inPoolWish.id,
      type: WishResponseType.alternative,
      proposedTitle: '可乐鸡翅',
    );
    expect(pending.status, WishStatus.pendingConfirmation);
    expect(
      () => notifier.fulfillWish(
        wishId: inPoolWish.id,
        actualDishName: '可乐鸡翅',
      ),
      throwsStateError,
    );
  });

  test('does not respond to my own wish', () {
    final controller = WishPoolController();
    final container = ProviderContainer(
      overrides: [
        wishPoolControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    final wish = notifier.createWish(title: '想吃水煮肉片');

    expect(
      () => notifier.respondToWish(
        wishId: wish.id,
        type: WishResponseType.lightVersion,
      ),
      throwsStateError,
    );
  });

  test('rolls back optimistic create when the API write fails', () async {
    final repository = _FailingCreateWishRepository();
    final container = ProviderContainer(
      overrides: [
        wishPoolRepositoryProvider.overrideWith((ref, token) => repository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishPoolControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(wishPoolControllerProvider).wishes, isEmpty);

    notifier.createWish(title: '会失败的愿望');
    expect(container.read(wishPoolControllerProvider).wishes, hasLength(1));

    await Future<void>.delayed(Duration.zero);
    final state = container.read(wishPoolControllerProvider);
    expect(state.wishes, isEmpty);
    expect(state.errorMessage, '同步失败，请稍后重试');
  });
}

class _FailingCreateWishRepository extends WishPoolRepository {
  _FailingCreateWishRepository() : super(token: 'test-token');

  @override
  Future<WishPoolSnapshot> fetchSnapshot({
    dynamic me,
    dynamic partner,
    WishCreatorFilter creatorFilter = WishCreatorFilter.all,
    WishStatus? statusFilter,
    String dishQuery = '',
    DishFilters dishFilters = const DishFilters(),
  }) async {
    return const WishPoolSnapshot(
      users: [],
      wishes: [],
      kitchenStatuses: {},
      fulfillments: [],
      dishes: [],
    );
  }

  @override
  Future<Wish> createWish({
    required String title,
    required String wishType,
    required List<String> feelingTags,
    required String desiredTime,
    required String intensity,
    required String substituteOption,
    required List<String> helperTasks,
  }) async {
    throw Exception('api failed');
  }
}
