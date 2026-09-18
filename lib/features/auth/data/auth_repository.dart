import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/auth_models.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository({ApiClient? client, SecureStorage? storage})
      : _dio = (client ?? ApiClient()).dio,
        _storage = storage ?? SecureStorage();

  Future<UserResponse> register(RegisterRequest request) async {
    final response =
        await _dio.post(ApiConstants.register, data: request.toJson());
    return UserResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoginResponse> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final result =
        LoginResponse.fromJson(response.data as Map<String, dynamic>);
    await _storage.saveToken(result.accessToken);
    return result;
  }

  Future<UserResponse> currentUser() async {
    final response = await _dio.get(ApiConstants.currentUser);
    return UserResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserResponse> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConstants.currentUser, data: data);
    return UserResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.deleteToken();
}
