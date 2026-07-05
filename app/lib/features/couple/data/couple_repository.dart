import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/couple_models.dart';

class CoupleRepository {
  CoupleRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<CoupleBinding> status(String token) async {
    final response = await _dio.get<Object?>(
      '/couples/status',
      options: _authOptions(token),
    );
    return _bindingFromJson(_parseData(response));
  }

  Future<CoupleInvite> generateCode(String token) async {
    final response = await _dio.post<Object?>(
      '/couples/generate-code',
      options: _authOptions(token),
    );
    return _inviteFromJson(_parseData(response));
  }

  Future<CoupleInvite> applyByCode(String token, String code) async {
    final response = await _dio.post<Object?>(
      '/couples/apply-by-code',
      options: _authOptions(token),
      data: {'code': code},
    );
    return _inviteFromJson(_parseData(response));
  }

  Future<CoupleBinding> accept(String token, String inviteId) async {
    final response = await _dio.post<Object?>(
      '/couples/accept/$inviteId',
      options: _authOptions(token),
    );
    return _bindingFromJson(_parseData(response));
  }

  Future<void> reject(String token, String inviteId) async {
    await _dio.post<Object?>('/couples/reject/$inviteId',
        options: _authOptions(token));
  }

  Future<void> cancel(String token, String inviteId) async {
    await _dio.post<Object?>('/couples/cancel/$inviteId',
        options: _authOptions(token));
  }

  Future<void> unbind(String token) async {
    await _dio.post<Object?>('/couples/unbind', options: _authOptions(token));
  }

  Options _authOptions(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});
}

Object? _parseData(Response<Object?> response) {
  final body = response.data;
  if (body is Map<String, dynamic> && body.containsKey('data')) {
    return body['data'];
  }
  return body;
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

CoupleBinding _bindingFromJson(Object? value) {
  final json = _parseMap(value);
  final status = switch (json['status']?.toString()) {
    'BOUND' => CoupleBindingStatus.bound,
    'PENDING' => CoupleBindingStatus.pending,
    'WAITING_FOR_ME' => CoupleBindingStatus.waitingForMe,
    'UNBOUND' => CoupleBindingStatus.unbound,
    _ => CoupleBindingStatus.unknown,
  };
  final couple = _parseMap(json['couple']);
  return CoupleBinding(
    status: status,
    invite: json['invite'] == null ? null : _inviteFromJson(json['invite']),
    activeInvite:
        json['invite'] == null ? null : _inviteFromJson(json['invite']),
    partner: json['partner'] == null ? null : _userFromJson(json['partner']),
    coupleId: couple['id']?.toString(),
  );
}

CoupleInvite _inviteFromJson(Object? value) {
  final json = _parseMap(value);
  return CoupleInvite(
    id: json['id']?.toString() ?? '',
    code: json['code']?.toString() ?? '',
    expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
        DateTime.now(),
    inviter: json['inviter'] == null ? null : _userFromJson(json['inviter']),
    inviteeId: json['inviteeId']?.toString(),
  );
}

AuthUser _userFromJson(Object? value) {
  final json = _parseMap(value);
  return AuthUser(
    id: json['id']?.toString() ?? '',
    nickname: json['nickname']?.toString() ?? '',
    email: json['email']?.toString(),
    phone: json['phone']?.toString(),
    avatarUrl: json['avatarUrl']?.toString(),
    gender: userGenderFromApi(json['gender']?.toString()),
  );
}
