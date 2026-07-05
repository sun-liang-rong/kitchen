import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_wish_well/features/auth/domain/auth_models.dart';
import 'package:kitchen_wish_well/features/auth/presentation/providers/session_controller.dart';
import 'package:kitchen_wish_well/features/couple/domain/couple_models.dart';
import 'package:kitchen_wish_well/features/notifications/domain/notification_models.dart';
import 'package:kitchen_wish_well/features/notifications/presentation/providers/notifications_controller.dart';
import 'package:kitchen_wish_well/features/wish_pool/domain/models/kitchen_models.dart';
import 'package:kitchen_wish_well/features/wish_pool/presentation/providers/wish_pool_controller.dart';

final boundSessionOverride =
    sessionControllerProvider.overrideWith(() => _TestSessionController());
final signedOutSessionOverride =
    sessionControllerProvider.overrideWith(() => _SignedOutSessionController());
final notificationsOverride = notificationsControllerProvider
    .overrideWith(() => _TestNotificationsController());
final seededWishPoolOverride =
    wishPoolControllerProvider.overrideWith(() => _SeededWishPoolController());

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
          relatedId: 'seed-wish-1',
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
    Object? avatarUrl = _unchangedAvatarUrl,
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
          avatarUrl: identical(avatarUrl, _unchangedAvatarUrl)
              ? current.user!.avatarUrl
              : avatarUrl as String?,
          gender: gender,
        ),
      ),
    );
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    return '/uploads/avatars/$filename';
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

const _unchangedAvatarUrl = Object();

class _SeededWishPoolController extends WishPoolController {
  @override
  WishPoolState build() {
    final now = DateTime(2026, 7, 4);
    return WishPoolState(
      users: const [
        AppUser(id: 'me', nickname: '我', isMe: true),
        AppUser(id: 'partner', nickname: '她', isMe: false),
      ],
      kitchenStatuses: const {
        'me': KitchenStatusEntry(
          userId: 'me',
          status: KitchenStatusValue.normal,
          note: '今天正常做饭',
        ),
        'partner': KitchenStatusEntry(
          userId: 'partner',
          status: KitchenStatusValue.tired,
          note: '她今天有点累，适合简单点',
        ),
      },
      wishes: [
        Wish(
          id: 'seed-wish-1',
          creatorId: 'partner',
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
          id: 'seed-wish-2',
          creatorId: 'me',
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
          id: 'seed-dish-1',
          name: '番茄鸡蛋面',
          cookOwner: 'me',
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

  @override
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
      id: 'test-wish-${state.wishes.length + 1}',
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
    return wish;
  }

  @override
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
    final response = WishResponse(
      id: 'test-response-${wish.responses.length + 1}',
      wishId: wishId,
      responderId: responderId ?? state.me.id,
      type: type,
      proposedTitle: proposedTitle,
      proposedTime: proposedTime,
      reasonTags: reasonTags,
      reasonText: reasonText,
      needsConfirmation: {
        WishResponseType.lightVersion,
        WishResponseType.alternative,
        WishResponseType.defer,
        WishResponseType.together,
      }.contains(type),
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
    return updated;
  }

  @override
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
    final fulfillment = WishFulfillment(
      id: 'test-fulfillment-${state.fulfillments.length + 1}',
      wishId: wishId,
      fulfillerId: fulfillerId ?? state.me.id,
      actualDishName: actualDishName.trim(),
      helperTasksDone: helperTasksDone,
      feedbackTags: feedbackTags,
      addToDishes: addToDishes,
      createdAt: DateTime.now(),
      note: note,
    );
    final updatedWish = wish.copyWith(
      status: WishStatus.fulfilled,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id == wishId) updatedWish else item,
      ],
      fulfillments: [
        fulfillment,
        ...state.fulfillments.where((item) => item.wishId != wishId),
      ],
      dishes: addToDishes
          ? [
              HomeDish(
                id: 'test-dish-${state.dishes.length + 1}',
                name: fulfillment.actualDishName,
                cookOwner: fulfillment.fulfillerId,
                suitableTimeTags: [wish.desiredTime],
                difficulty: '普通',
                tasteTags: fulfillment.feedbackTags,
                isFavorite: true,
                sourceWishId: wish.id,
                lastFeedback: fulfillment.feedbackTags.join('、'),
                imageUrl: imageUrl,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              ...state.dishes
                  .where((dish) => dish.name != fulfillment.actualDishName),
            ]
          : state.dishes,
    );
    return fulfillment;
  }

  @override
  HomeDish addDish({
    required String name,
    String? cookOwner,
    List<String> suitableTimeTags = const [],
    String difficulty = '普通',
    List<String> tasteTags = const [],
    bool isFavorite = false,
    String? imageUrl,
  }) {
    final dish = HomeDish(
      id: 'test-dish-${state.dishes.length + 1}',
      name: name.trim(),
      cookOwner: cookOwner,
      suitableTimeTags: suitableTimeTags,
      difficulty: difficulty,
      tasteTags: tasteTags,
      isFavorite: isFavorite,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(dishes: [dish, ...state.dishes]);
    return dish;
  }

  @override
  void deleteDish(String id) {
    state = state.copyWith(
      dishes: [
        for (final dish in state.dishes)
          if (dish.id != id) dish,
      ],
    );
  }

  @override
  Future<String> uploadDishImage({
    required List<int> bytes,
    required String filename,
  }) async {
    return '/uploads/dishes/$filename';
  }

  void _replaceWish(Wish wish) {
    state = state.copyWith(
      wishes: [
        for (final item in state.wishes)
          if (item.id == wish.id) wish else item,
      ],
    );
  }
}
