import '../../../auth/domain/auth_models.dart';

enum WishStatus {
  inPool,
  pendingConfirmation,
  claimed,
  deferred,
  together,
  shelved,
  fulfilled,
}

enum WishResponseType {
  fulfillTonight,
  lightVersion,
  alternative,
  defer,
  together,
  shelve,
}

enum WishCreatorFilter {
  all,
  me,
  partner,
}

enum KitchenStatusValue {
  seriousCook,
  normal,
  tired,
  simpleOnly,
  noCooking,
  cookTogether,
}

enum DishOwnerFilter {
  all,
  me,
  partner,
}

class DishFilters {
  const DishFilters({
    this.owner = DishOwnerFilter.all,
    this.difficulty,
    this.favoriteOnly = false,
  });

  final DishOwnerFilter owner;
  final String? difficulty;
  final bool favoriteOnly;

  bool get isActive =>
      owner != DishOwnerFilter.all || difficulty != null || favoriteOnly;

  DishFilters copyWith({
    DishOwnerFilter? owner,
    Object? difficulty = _unchangedDishDifficulty,
    bool? favoriteOnly,
  }) {
    return DishFilters(
      owner: owner ?? this.owner,
      difficulty: identical(difficulty, _unchangedDishDifficulty)
          ? this.difficulty
          : difficulty as String?,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
    );
  }
}

const _unchangedDishDifficulty = Object();

class AppUser {
  const AppUser({
    required this.id,
    required this.nickname,
    required this.isMe,
    this.gender = UserGender.unspecified,
  });

  final String id;
  final String nickname;
  final bool isMe;
  final UserGender gender;
}

class KitchenStatusEntry {
  const KitchenStatusEntry({
    required this.userId,
    required this.status,
    this.note,
  });

  final String userId;
  final KitchenStatusValue status;
  final String? note;

  KitchenStatusEntry copyWith({
    KitchenStatusValue? status,
    String? note,
  }) {
    return KitchenStatusEntry(
      userId: userId,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}

class WishResponse {
  const WishResponse({
    required this.id,
    required this.wishId,
    required this.responderId,
    required this.type,
    required this.reasonTags,
    required this.createdAt,
    this.proposedTitle,
    this.proposedTime,
    this.reasonText,
    this.needsConfirmation = false,
    this.confirmedAt,
  });

  final String id;
  final String wishId;
  final String responderId;
  final WishResponseType type;
  final String? proposedTitle;
  final String? proposedTime;
  final List<String> reasonTags;
  final String? reasonText;
  final bool needsConfirmation;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  WishResponse copyWith({
    bool? needsConfirmation,
    DateTime? confirmedAt,
  }) {
    return WishResponse(
      id: id,
      wishId: wishId,
      responderId: responderId,
      type: type,
      proposedTitle: proposedTitle,
      proposedTime: proposedTime,
      reasonTags: reasonTags,
      reasonText: reasonText,
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt,
    );
  }
}

class Wish {
  const Wish({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.wishType,
    required this.feelingTags,
    required this.desiredTime,
    required this.intensity,
    required this.substituteOption,
    required this.helperTasks,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.responses,
    this.currentResponseId,
  });

  final String id;
  final String creatorId;
  final String title;
  final String wishType;
  final List<String> feelingTags;
  final String desiredTime;
  final String intensity;
  final String substituteOption;
  final List<String> helperTasks;
  final WishStatus status;
  final String? currentResponseId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WishResponse> responses;

  WishResponse? get currentResponse {
    for (final response in responses) {
      if (response.id == currentResponseId) {
        return response;
      }
    }
    return null;
  }

  Wish copyWith({
    String? title,
    WishStatus? status,
    Object? currentResponseId = _unchangedWishResponseId,
    DateTime? updatedAt,
    List<WishResponse>? responses,
  }) {
    return Wish(
      id: id,
      creatorId: creatorId,
      title: title ?? this.title,
      wishType: wishType,
      feelingTags: feelingTags,
      desiredTime: desiredTime,
      intensity: intensity,
      substituteOption: substituteOption,
      helperTasks: helperTasks,
      status: status ?? this.status,
      currentResponseId: identical(currentResponseId, _unchangedWishResponseId)
          ? this.currentResponseId
          : currentResponseId as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      responses: responses ?? this.responses,
    );
  }
}

const _unchangedWishResponseId = Object();

class WishFulfillment {
  const WishFulfillment({
    required this.id,
    required this.wishId,
    required this.fulfillerId,
    required this.actualDishName,
    required this.helperTasksDone,
    required this.feedbackTags,
    required this.addToDishes,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String wishId;
  final String fulfillerId;
  final String actualDishName;
  final List<String> helperTasksDone;
  final List<String> feedbackTags;
  final bool addToDishes;
  final DateTime createdAt;
  final String? note;
}

class HomeDish {
  const HomeDish({
    required this.id,
    required this.name,
    required this.suitableTimeTags,
    required this.tasteTags,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.cookOwner,
    this.difficulty,
    this.sourceWishId,
    this.lastFeedback,
  });

  final String id;
  final String name;
  final String? cookOwner;
  final List<String> suitableTimeTags;
  final String? difficulty;
  final List<String> tasteTags;
  final bool isFavorite;
  final String? sourceWishId;
  final String? lastFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  HomeDish copyWith({
    String? name,
    String? cookOwner,
    List<String>? suitableTimeTags,
    String? difficulty,
    List<String>? tasteTags,
    bool? isFavorite,
    String? lastFeedback,
  }) {
    return HomeDish(
      id: id,
      name: name ?? this.name,
      cookOwner: cookOwner ?? this.cookOwner,
      suitableTimeTags: suitableTimeTags ?? this.suitableTimeTags,
      difficulty: difficulty ?? this.difficulty,
      tasteTags: tasteTags ?? this.tasteTags,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceWishId: sourceWishId,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
