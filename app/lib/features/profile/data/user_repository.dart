import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_models.dart';

class UserRepository {
  UserRepository({Dio? dio, String? token})
      : _dio = dio ?? DioClient(token: token).dio;

  final Dio _dio;

  Future<AuthUser> updateMe({
    String? nickname,
    String? avatarUrl,
    UserGender? gender,
  }) async {
    final response = await _dio.patch<Object?>(
      '/users/me',
      data: {
        if (nickname != null) 'nickname': nickname,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (gender != null) 'gender': userGenderToApi(gender),
      },
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
