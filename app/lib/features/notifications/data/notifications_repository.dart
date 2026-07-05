import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/notification_models.dart';

class NotificationsRepository {
  NotificationsRepository({Dio? dio, String? token})
      : _dio = dio ?? DioClient(token: token).dio;

  final Dio _dio;

  Future<List<AppNotification>> list({bool unreadOnly = false}) async {
    final response = await _dio.get<Object?>(
      '/notifications',
      queryParameters: {'unreadOnly': unreadOnly.toString()},
    );
    return _parseList(response).map(_notificationFromJson).toList();
  }

  Future<int> unreadCount() async {
    final response = await _dio.get<Object?>('/notifications/unread-count');
    final data = _parseMap(_parseData(response));
    return int.tryParse(data['count']?.toString() ?? '') ?? 0;
  }

  Future<void> markRead(String id) async {
    await _dio.patch<Object?>('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch<Object?>('/notifications/read-all');
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

AppNotification _notificationFromJson(Object? value) {
  final json = _parseMap(value);
  return AppNotification(
    id: json['id']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
    relatedId: json['relatedId']?.toString(),
    readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}
