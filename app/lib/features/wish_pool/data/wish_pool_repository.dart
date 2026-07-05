import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/models/kitchen_models.dart';

class WishPoolSnapshot {
  const WishPoolSnapshot({
    required this.users,
    required this.wishes,
    required this.kitchenStatuses,
    required this.fulfillments,
    required this.dishes,
  });

  final List<AppUser> users;
  final List<Wish> wishes;
  final Map<String, KitchenStatusEntry> kitchenStatuses;
  final List<WishFulfillment> fulfillments;
  final List<HomeDish> dishes;
}

class WishPoolRepository {
  WishPoolRepository({Dio? dio, String? token})
      : _dio = dio ?? DioClient(token: token).dio;

  final Dio _dio;

  Future<WishPoolSnapshot> fetchSnapshot({
    AuthUser? me,
    AuthUser? partner,
    WishCreatorFilter creatorFilter = WishCreatorFilter.all,
    WishStatus? statusFilter,
    String dishQuery = '',
    DishFilters dishFilters = const DishFilters(),
  }) async {
    final wishQuery = <String, Object?>{
      if (creatorFilter == WishCreatorFilter.me) 'creator': 'me',
      if (creatorFilter == WishCreatorFilter.partner) 'creator': 'partner',
      if (statusFilter != null) 'status': _wishStatusToApi(statusFilter),
    };
    final responses = await Future.wait([
      _dio.get<Object?>('/wishes', queryParameters: wishQuery),
      _dio.get<Object?>('/kitchen-status'),
      _dio.get<Object?>('/wish-fulfillments'),
      _dio.get<Object?>(
        '/dishes',
        queryParameters: {
          if (dishQuery.trim().isNotEmpty) 'q': dishQuery.trim(),
          if (dishFilters.owner == DishOwnerFilter.me)
            'cookOwner': me?.id ?? 'me',
          if (dishFilters.owner == DishOwnerFilter.partner)
            'cookOwner': partner?.id ?? 'partner',
          if (dishFilters.difficulty != null)
            'difficulty': _difficultyToApi(dishFilters.difficulty!),
          if (dishFilters.favoriteOnly) 'isFavorite': 'true',
        },
      ),
    ]);

    return WishPoolSnapshot(
      users: [
        AppUser(
          id: me?.id ?? 'me',
          nickname: me?.nickname ?? '我',
          isMe: true,
          gender: me?.gender ?? UserGender.unspecified,
        ),
        AppUser(
          id: partner?.id ?? 'partner',
          nickname:
              partner?.nickname ?? thirdPersonPronoun(UserGender.unspecified),
          isMe: false,
          gender: partner?.gender ?? UserGender.unspecified,
        ),
      ],
      wishes: _parseList(responses[0]).map(_wishFromJson).toList(),
      kitchenStatuses: {
        for (final item in _parseList(responses[1]))
          _kitchenStatusFromJson(item).userId: _kitchenStatusFromJson(item),
      },
      fulfillments: _parseList(responses[2]).map(_fulfillmentFromJson).toList(),
      dishes: _parseList(responses[3]).map(_dishFromJson).toList(),
    );
  }

  Future<Wish> createWish({
    required String title,
    required String wishType,
    required List<String> feelingTags,
    required String desiredTime,
    required String intensity,
    required String substituteOption,
    required List<String> helperTasks,
  }) async {
    final response = await _dio.post<Object?>(
      '/wishes',
      data: {
        'title': title,
        'wishType': wishType,
        'feelingTags': feelingTags,
        'desiredTime': _desiredTimeToApi(desiredTime),
        'intensity': _intensityToApi(intensity),
        'substituteOption': _substituteOptionToApi(substituteOption),
        'helperTasks': helperTasks,
      },
    );
    return _wishFromJson(_parseData(response));
  }

  Future<Wish> fetchWish(String wishId) async {
    final response = await _dio.get<Object?>('/wishes/$wishId');
    return _wishFromJson(_parseData(response));
  }

  Future<void> deleteWish(String wishId) async {
    await _dio.delete<Object?>('/wishes/$wishId');
  }

  Future<Wish> respondToWish({
    required String wishId,
    required WishResponseType type,
    String? proposedTitle,
    String? proposedTime,
    required List<String> reasonTags,
    String? reasonText,
  }) async {
    final response = await _dio.post<Object?>(
      '/wish-responses/wishes/$wishId',
      data: {
        'responseType': _responseTypeToApi(type),
        if (proposedTitle != null && proposedTitle.isNotEmpty)
          'proposedTitle': proposedTitle,
        if (proposedTime != null && proposedTime.isNotEmpty)
          'proposedTime': _desiredTimeToApi(proposedTime),
        'reasonTags': reasonTags,
        if (reasonText != null && reasonText.isNotEmpty)
          'reasonText': reasonText,
      },
    );
    return _wishFromJson(_parseData(response));
  }

  Future<Wish> confirmResponse(String responseId) async {
    final response =
        await _dio.patch<Object?>('/wish-responses/$responseId/confirm');
    return _wishFromJson(_parseData(response));
  }

  Future<Wish> reopenResponse(String responseId) async {
    final response =
        await _dio.patch<Object?>('/wish-responses/$responseId/reopen');
    return _wishFromJson(_parseData(response));
  }

  Future<WishFulfillment> fulfillWish({
    required String wishId,
    required String actualDishName,
    required List<String> helperTasksDone,
    required List<String> feedbackTags,
    String? note,
    required bool addToDishes,
  }) async {
    final response = await _dio.post<Object?>(
      '/wish-fulfillments/wishes/$wishId',
      data: {
        'actualDishName': actualDishName,
        'helperTasksDone': helperTasksDone,
        'feedbackTags': feedbackTags,
        if (note != null && note.isNotEmpty) 'note': note,
        'addToDishes': addToDishes,
      },
    );
    final data = _parseMap(_parseData(response));
    return _fulfillmentFromJson(data['fulfillment']);
  }

  Future<HomeDish> addDish({
    required String name,
    String? cookOwner,
    required List<String> suitableTimeTags,
    required String difficulty,
    required List<String> tasteTags,
    required bool isFavorite,
  }) async {
    final response = await _dio.post<Object?>(
      '/dishes',
      data: {
        'name': name,
        if (cookOwner != null) 'cookOwner': cookOwner,
        'suitableTimeTags': suitableTimeTags.map(_dishTagToApi).toList(),
        'difficulty': _difficultyToApi(difficulty),
        'tasteTags': tasteTags,
        'isFavorite': isFavorite,
      },
    );
    return _dishFromJson(_parseData(response));
  }

  Future<HomeDish> updateDish(String id, HomeDish dish) async {
    final response = await _dio.patch<Object?>(
      '/dishes/$id',
      data: {
        'name': dish.name,
        if (dish.cookOwner != null) 'cookOwner': dish.cookOwner,
        'suitableTimeTags': dish.suitableTimeTags.map(_dishTagToApi).toList(),
        if (dish.difficulty != null)
          'difficulty': _difficultyToApi(dish.difficulty!),
        'tasteTags': dish.tasteTags,
        'isFavorite': dish.isFavorite,
        if (dish.lastFeedback != null) 'lastFeedback': dish.lastFeedback,
      },
    );
    return _dishFromJson(_parseData(response));
  }

  Future<KitchenStatusEntry> setKitchenStatus(
    String userId,
    KitchenStatusValue status, {
    String? note,
  }) async {
    final response = await _dio.put<Object?>(
      '/kitchen-status',
      data: {
        'userId': userId,
        'status': _kitchenStatusToApi(status),
        if (note != null) 'note': note,
      },
    );
    return _kitchenStatusFromJson(_parseData(response));
  }
}

String _wishStatusToApi(WishStatus status) {
  return switch (status) {
    WishStatus.inPool => 'IN_POOL',
    WishStatus.pendingConfirmation => 'PENDING_CONFIRMATION',
    WishStatus.claimed => 'CLAIMED',
    WishStatus.deferred => 'DEFERRED',
    WishStatus.together => 'TOGETHER',
    WishStatus.shelved => 'SHELVED',
    WishStatus.fulfilled => 'FULFILLED',
  };
}

Object? _parseData(Response<Object?> response) {
  final body = response.data;
  if (body is Map<String, dynamic> && body.containsKey('data')) {
    return body['data'];
  }
  return body;
}

List<Object?> _parseList(Response<Object?> response) {
  final data = _parseData(response);
  if (data is List) {
    return data.cast<Object?>();
  }
  return const [];
}

Map<String, dynamic> _parseMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

KitchenStatusEntry _kitchenStatusFromJson(Object? value) {
  final json = _parseMap(value);
  final status = _parseMap(json['status']);
  final user = _parseMap(json['user']);
  final userId =
      (status['userId'] ?? json['userId'] ?? user['id'] ?? 'me').toString();

  return KitchenStatusEntry(
    userId: userId,
    status:
        _kitchenStatusFromApi((status['status'] ?? json['status']).toString()),
    note: (status['note'] ?? json['note'])?.toString(),
  );
}

Wish _wishFromJson(Object? value) {
  final json = _parseMap(value);
  final responses = [
    ..._asList(json['responses']).map(_responseFromJson),
    if (json['currentResponse'] != null)
      _responseFromJson(json['currentResponse']),
  ];
  final dedupedResponses = <String, WishResponse>{
    for (final response in responses) response.id: response,
  }.values.toList();

  return Wish(
    id: json['id']?.toString() ?? '',
    creatorId: json['creatorId']?.toString() ?? 'me',
    title: json['title']?.toString() ?? '',
    wishType: json['wishType']?.toString() ?? 'DISH',
    feelingTags: _stringList(json['feelingTags']),
    desiredTime: _desiredTimeFromApi(json['desiredTime']?.toString()),
    intensity: _intensityFromApi(json['intensity']?.toString()),
    substituteOption:
        _substituteOptionFromApi(json['substituteOption']?.toString()),
    helperTasks: _stringList(json['helperTasks']),
    status: _wishStatusFromApi(json['status']?.toString()),
    currentResponseId: json['currentResponseId']?.toString(),
    createdAt: _dateFromJson(json['createdAt']),
    updatedAt: _dateFromJson(json['updatedAt']),
    responses: dedupedResponses,
  );
}

WishResponse _responseFromJson(Object? value) {
  final json = _parseMap(value);
  final type = _responseTypeFromApi(json['responseType']?.toString());
  final confirmedAt = _nullableDateFromJson(json['confirmedAt']);
  return WishResponse(
    id: json['id']?.toString() ?? '',
    wishId: json['wishId']?.toString() ?? '',
    responderId: json['responderId']?.toString() ?? 'partner',
    type: type,
    proposedTitle: json['proposedTitle']?.toString(),
    proposedTime: _nullableDesiredTimeFromApi(json['proposedTime']?.toString()),
    reasonTags: _stringList(json['reasonTags']),
    reasonText: json['reasonText']?.toString(),
    needsConfirmation: _needsConfirmation(type) && confirmedAt == null,
    createdAt: _dateFromJson(json['createdAt']),
    confirmedAt: confirmedAt,
  );
}

WishFulfillment _fulfillmentFromJson(Object? value) {
  final json = _parseMap(value);
  return WishFulfillment(
    id: json['id']?.toString() ?? '',
    wishId: json['wishId']?.toString() ?? '',
    fulfillerId: json['fulfillerId']?.toString() ?? 'partner',
    actualDishName: json['actualDishName']?.toString() ?? '',
    helperTasksDone: _stringList(json['helperTasksDone']),
    feedbackTags: _stringList(json['feedbackTags']),
    addToDishes: json['addToDishes'] == true,
    createdAt: _dateFromJson(json['createdAt']),
    note: json['note']?.toString(),
  );
}

HomeDish _dishFromJson(Object? value) {
  final json = _parseMap(value);
  return HomeDish(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    cookOwner: json['cookOwner']?.toString(),
    suitableTimeTags:
        _stringList(json['suitableTimeTags']).map(_dishTagFromApi).toList(),
    difficulty: _difficultyFromApi(json['difficulty']?.toString()),
    tasteTags: _stringList(json['tasteTags']),
    isFavorite: json['isFavorite'] == true,
    sourceWishId: json['sourceWishId']?.toString(),
    lastFeedback: json['lastFeedback']?.toString(),
    createdAt: _dateFromJson(json['createdAt']),
    updatedAt: _dateFromJson(json['updatedAt']),
  );
}

List<Object?> _asList(Object? value) =>
    value is List ? value.cast<Object?>() : const [];

List<String> _stringList(Object? value) =>
    _asList(value).map((item) => item.toString()).toList();

DateTime _dateFromJson(Object? value) =>
    _nullableDateFromJson(value) ?? DateTime.now();

DateTime? _nullableDateFromJson(Object? value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '');
}

WishStatus _wishStatusFromApi(String? value) {
  return switch (value) {
    'PENDING_CONFIRMATION' => WishStatus.pendingConfirmation,
    'CLAIMED' => WishStatus.claimed,
    'ALTERNATIVE_PROPOSED' => WishStatus.pendingConfirmation,
    'DEFERRED' => WishStatus.deferred,
    'TOGETHER' => WishStatus.together,
    'SHELVED' => WishStatus.shelved,
    'FULFILLED' => WishStatus.fulfilled,
    _ => WishStatus.inPool,
  };
}

WishResponseType _responseTypeFromApi(String? value) {
  return switch (value) {
    'LIGHT_VERSION' => WishResponseType.lightVersion,
    'ALTERNATIVE' => WishResponseType.alternative,
    'DEFER' => WishResponseType.defer,
    'TOGETHER' => WishResponseType.together,
    'SHELVE' => WishResponseType.shelve,
    _ => WishResponseType.fulfillTonight,
  };
}

String _responseTypeToApi(WishResponseType type) {
  return switch (type) {
    WishResponseType.fulfillTonight => 'FULFILL_TONIGHT',
    WishResponseType.lightVersion => 'LIGHT_VERSION',
    WishResponseType.alternative => 'ALTERNATIVE',
    WishResponseType.defer => 'DEFER',
    WishResponseType.together => 'TOGETHER',
    WishResponseType.shelve => 'SHELVE',
  };
}

bool _needsConfirmation(WishResponseType type) {
  return {
    WishResponseType.lightVersion,
    WishResponseType.alternative,
    WishResponseType.defer,
    WishResponseType.together,
  }.contains(type);
}

String _desiredTimeFromApi(String? value) {
  return switch (value) {
    'TOMORROW' => '明天',
    'THIS_WEEK' => '这周',
    'WEEKEND' => '周末',
    'SOMEDAY' => '有空再说',
    _ => '今晚',
  };
}

String? _nullableDesiredTimeFromApi(String? value) =>
    value == null ? null : _desiredTimeFromApi(value);

String _desiredTimeToApi(String value) {
  return switch (value) {
    '明天' => 'TOMORROW',
    '这周' => 'THIS_WEEK',
    '周末' => 'WEEKEND',
    '有空再说' || '有空再做' => 'SOMEDAY',
    _ => 'TONIGHT',
  };
}

String _intensityFromApi(String? value) {
  return switch (value) {
    'CASUAL' => '随口一想',
    'THIS_WEEK' => '这周想吃',
    'VERY_TODAY' => '今天特别想吃',
    'WEEKEND_PLAN' => '周末认真安排',
    _ => '今天想吃',
  };
}

String _intensityToApi(String value) {
  return switch (value) {
    '随口一想' => 'CASUAL',
    '这周想吃' => 'THIS_WEEK',
    '今天特别想吃' => 'VERY_TODAY',
    '周末认真安排' => 'WEEKEND_PLAN',
    _ => 'TODAY',
  };
}

String _substituteOptionFromApi(String? value) {
  return switch (value) {
    'LIGHT_VERSION_OK' => '可以做轻松版',
    'WHAT_WE_HAVE_OK' => '家里有什么就做什么',
    'NO_SUBSTITUTE' => '不太想换',
    _ => '可以换类似的',
  };
}

String _substituteOptionToApi(String value) {
  return switch (value) {
    '可以做轻松版' => 'LIGHT_VERSION_OK',
    '家里有什么就做什么' => 'WHAT_WE_HAVE_OK',
    '不太想换' => 'NO_SUBSTITUTE',
    _ => 'SIMILAR_OK',
  };
}

KitchenStatusValue _kitchenStatusFromApi(String? value) {
  return switch (value) {
    'SERIOUS_COOK' => KitchenStatusValue.seriousCook,
    'TIRED' => KitchenStatusValue.tired,
    'SIMPLE_ONLY' => KitchenStatusValue.simpleOnly,
    'NO_COOKING' => KitchenStatusValue.noCooking,
    'COOK_TOGETHER' => KitchenStatusValue.cookTogether,
    _ => KitchenStatusValue.normal,
  };
}

String _kitchenStatusToApi(KitchenStatusValue value) {
  return switch (value) {
    KitchenStatusValue.seriousCook => 'SERIOUS_COOK',
    KitchenStatusValue.normal => 'NORMAL',
    KitchenStatusValue.tired => 'TIRED',
    KitchenStatusValue.simpleOnly => 'SIMPLE_ONLY',
    KitchenStatusValue.noCooking => 'NO_COOKING',
    KitchenStatusValue.cookTogether => 'COOK_TOGETHER',
  };
}

String _difficultyFromApi(String? value) {
  return switch (value) {
    'EASY' => '简单',
    'HARD' => '费事',
    _ => '普通',
  };
}

String _difficultyToApi(String value) {
  return switch (value) {
    '简单' => 'EASY',
    '费事' => 'HARD',
    _ => 'NORMAL',
  };
}

String _dishTagFromApi(String value) {
  return switch (value) {
    'TONIGHT' => '今晚',
    'WEEKEND' => '周末',
    'SIMPLE_ONLY' => '快手',
    'SERIOUS_COOK' => '认真做',
    _ => value,
  };
}

String _dishTagToApi(String value) {
  return switch (value) {
    '今晚' => 'TONIGHT',
    '周末' => 'WEEKEND',
    '快手' => 'SIMPLE_ONLY',
    '认真做' => 'SERIOUS_COOK',
    _ => value,
  };
}
