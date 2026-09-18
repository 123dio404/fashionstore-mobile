import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  final Dio dio;

  ApiClient({SecureStorage? storage})
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    final secureStorage = storage ?? SecureStorage();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final detail = error.response?.data is Map
              ? error.response?.data['detail']
              : null;
          final message = detail is String
              ? detail
              : 'No fue posible conectar con el servidor.';
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: message,
              message: message,
            ),
          );
        },
      ),
    );
  }
}
