import 'package:dio/dio.dart';

import '../config/app_config.dart';

class DioClient {
  DioClient({String? token})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: token == null ? null : {'Authorization': 'Bearer $token'},
          ),
        );

  final Dio dio;
}
