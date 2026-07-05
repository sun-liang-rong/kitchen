import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<AuthSession> register({
    required String account,
    required String password,
    required String nickname,
    UserGender gender = UserGender.unspecified,
  }) async {
    final response = await _dio.post<Object?>(
      '/auth/register',
      data: {
        if (account.contains('@'))
          'email': account.trim()
        else
          'phone': account.trim(),
        'password': password,
        'nickname': nickname.trim(),
        'gender': userGenderToApi(gender),
      },
    );
    return _sessionFromJson(_parseData(response));
  }

  Future<AuthSession> login({
    required String account,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      '/auth/login',
      data: {
        if (account.contains('@'))
          'email': account.trim()
        else
          'phone': account.trim(),
        'password': password,
      },
    );
    return _sessionFromJson(_parseData(response));
  }

  Future<AuthUser> me(String token) async {
    final response = await _dio.get<Object?>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _userFromJson(_parseData(response));
  }
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

AuthSession _sessionFromJson(Object? value) {
  final json = _parseMap(value);
  return AuthSession(
    token: json['token']?.toString() ?? '',
    user: _userFromJson(json['user']),
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
