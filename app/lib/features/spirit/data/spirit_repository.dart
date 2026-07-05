import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/spirit_models.dart';

class SpiritRepository {
  SpiritRepository({Dio? dio, String? token})
      : _dio = dio ?? DioClient(token: token).dio;

  final Dio _dio;

  Future<SpiritHome> fetchHome() async {
    final response = await _dio.get<Object?>('/spirit');
    return _homeFromJson(_parseData(response));
  }

  Future<CoupleSpirit> renameSpirit(String name) async {
    final response = await _dio.patch<Object?>(
      '/spirit/name',
      data: {'name': name},
    );
    return _spiritFromJson(_parseData(response));
  }

  Future<CoupleSpirit> updateStyle(SpiritStyle style) async {
    final response = await _dio.patch<Object?>(
      '/spirit/style',
      data: {'style': spiritStyleToApi(style)},
    );
    return _spiritFromJson(_parseData(response));
  }

  Future<SpiritFeedResult> feed(FeedType type) async {
    final response = await _dio.post<Object?>(
      '/spirit/feed',
      data: {'feedType': feedTypeToApi(type)},
    );
    final json = _parseMap(_parseData(response));
    return SpiritFeedResult(
      spirit: _spiritFromJson(json['spirit']),
      points: _pointsFromJson(json['points']),
      levelUp: json['levelUp'] == true,
      stageChanged: json['stageChanged'] == true,
    );
  }

  Future<List<SpiritGrowthLog>> fetchLogs() async {
    final response = await _dio.get<Object?>('/spirit/logs');
    return _parseList(response).map(_logFromJson).toList();
  }

  Future<PointAccount> fetchPoints() async {
    final response = await _dio.get<Object?>('/points');
    return _pointsFromJson(_parseData(response));
  }

  Future<List<PointTransaction>> fetchTransactions() async {
    final response = await _dio.get<Object?>('/points/transactions');
    return _parseList(response).map(_transactionFromJson).toList();
  }

  Future<CheckinStatus> fetchCheckinStatus() async {
    final response = await _dio.get<Object?>('/checkins/status');
    return _checkinStatusFromJson(_parseData(response));
  }

  Future<CheckinResult> checkin() async {
    final response = await _dio.post<Object?>('/checkins');
    final json = _parseMap(_parseData(response));
    return CheckinResult(
      alreadyCheckedIn: json['alreadyCheckedIn'] == true,
      points: _pointsFromJson(json['points']),
      status: _checkinStatusFromJson(json['status']),
      spirit: json['spirit'] == null ? null : _spiritFromJson(json['spirit']),
    );
  }
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

SpiritHome _homeFromJson(Object? value) {
  final json = _parseMap(value);
  return SpiritHome(
    spirit: _spiritFromJson(json['spirit']),
    points: _pointsFromJson(json['points']),
    checkin: _checkinStatusFromJson(json['checkin']),
  );
}

CoupleSpirit _spiritFromJson(Object? value) {
  final json = _parseMap(value);
  return CoupleSpirit(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '饭团精灵').toString(),
    level: _intValue(json['level'], fallback: 1),
    exp: _intValue(json['exp']),
    stage: _stageFromApi(json['stage']?.toString()),
    mood: _moodFromApi(json['mood']?.toString()),
    style: _styleFromApi(json['style']?.toString()),
    appearance: (json['appearance'] ?? 'spirit_baby').toString(),
    expToNextLevel: _intValue(json['expToNextLevel'], fallback: 50),
    createdAt: _dateValue(json['createdAt']),
    updatedAt: _dateValue(json['updatedAt']),
    lastFedAt: _nullableDateValue(json['lastFedAt']),
  );
}

PointAccount _pointsFromJson(Object? value) {
  final json = _parseMap(value);
  return PointAccount(
    id: (json['id'] ?? '').toString(),
    coupleId: (json['coupleId'] ?? '').toString(),
    balance: _intValue(json['balance']),
    totalEarned: _intValue(json['totalEarned']),
    totalSpent: _intValue(json['totalSpent']),
    createdAt: _dateValue(json['createdAt']),
    updatedAt: _dateValue(json['updatedAt']),
  );
}

CheckinStatus _checkinStatusFromJson(Object? value) {
  final json = _parseMap(value);
  return CheckinStatus(
    checkedInToday: json['checkedInToday'] == true,
    streakDays: _intValue(json['streakDays']),
    todayPoints: _intValue(json['todayPoints']),
    checkinDate: _dateValue(json['checkinDate']),
  );
}

PointTransaction _transactionFromJson(Object? value) {
  final json = _parseMap(value);
  return PointTransaction(
    id: (json['id'] ?? '').toString(),
    type: _transactionTypeFromApi(json['type']?.toString()),
    reason: _pointReasonFromApi(json['reason']?.toString()),
    amount: _intValue(json['amount']),
    balanceAfter: _intValue(json['balanceAfter']),
    relatedId: json['relatedId']?.toString(),
    description: json['description']?.toString(),
    createdAt: _dateValue(json['createdAt']),
  );
}

SpiritGrowthLog _logFromJson(Object? value) {
  final json = _parseMap(value);
  return SpiritGrowthLog(
    id: (json['id'] ?? '').toString(),
    type: _logTypeFromApi(json['type']?.toString()),
    content: (json['content'] ?? '').toString(),
    metadata: _parseMap(json['metadata']),
    createdAt: _dateValue(json['createdAt']),
  );
}

SpiritStage _stageFromApi(String? value) {
  return switch (value) {
    'GROWING' => SpiritStage.growing,
    'INTIMATE' => SpiritStage.intimate,
    _ => SpiritStage.baby,
  };
}

SpiritMood _moodFromApi(String? value) {
  return switch (value) {
    'HAPPY' => SpiritMood.happy,
    'HUNGRY' => SpiritMood.hungry,
    'EXCITED' => SpiritMood.excited,
    _ => SpiritMood.normal,
  };
}

SpiritStyle _styleFromApi(String? value) {
  return switch (value) {
    'SHADOW' => SpiritStyle.shadow,
    'CELESTIAL' => SpiritStyle.celestial,
    _ => SpiritStyle.flame,
  };
}

PointTransactionType _transactionTypeFromApi(String? value) {
  return switch (value) {
    'SPEND' => PointTransactionType.spend,
    _ => PointTransactionType.earn,
  };
}

PointReason _pointReasonFromApi(String? value) {
  return switch (value) {
    'CREATE_WISH' => PointReason.createWish,
    'RESPOND_WISH' => PointReason.respondWish,
    'CONFIRM_RESPONSE' => PointReason.confirmResponse,
    'FULFILL_WISH' => PointReason.fulfillWish,
    'ADD_DISH' => PointReason.addDish,
    'FEED_SPIRIT' => PointReason.feedSpirit,
    _ => PointReason.checkin,
  };
}

SpiritLogType _logTypeFromApi(String? value) {
  return switch (value) {
    'FEED' => SpiritLogType.feed,
    'LEVEL_UP' => SpiritLogType.levelUp,
    'STAGE_CHANGED' => SpiritLogType.stageChanged,
    'WISH_FULFILLED' => SpiritLogType.wishFulfilled,
    _ => SpiritLogType.checkin,
  };
}

DateTime _dateValue(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _nullableDateValue(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
