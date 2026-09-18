import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class AppRepository {
  final Dio dio;
  AppRepository({ApiClient? client}) : dio = (client ?? ApiClient()).dio;
  Future<Map<String, dynamic>> cart() async =>
      Map<String, dynamic>.from((await dio.get(ApiConstants.cart)).data);
  Future<Map<String, dynamic>> addCart(int stockId, int quantity) async =>
      Map<String, dynamic>.from((await dio.post(ApiConstants.cartItems,
              data: {'stock_id': stockId, 'quantity': quantity}))
          .data);
  Future<Map<String, dynamic>> updateCart(int id, int quantity) async =>
      Map<String, dynamic>.from((await dio.patch(
              '${ApiConstants.cartItems}/$id',
              data: {'quantity': quantity}))
          .data);
  Future<void> removeCart(int id) async =>
      dio.delete('${ApiConstants.cartItems}/$id');
  Future<Map<String, dynamic>> checkout(int branchId) async =>
      Map<String, dynamic>.from((await dio.post(ApiConstants.checkout, data: {
        'branch_id': branchId,
        'payment_provider': 'stripe',
        'payment_status': 'pendiente',
        'idempotency_key': 'mobile-${DateTime.now().microsecondsSinceEpoch}'
      }))
          .data);
  Future<List<dynamic>> list(String path,
          {Map<String, dynamic>? query}) async =>
      List<dynamic>.from((await dio.get(path, queryParameters: query)).data);
  Future<Map<String, dynamic>> create(
          String path, Map<String, dynamic> data) async =>
      Map<String, dynamic>.from((await dio.post(path, data: data)).data);
  Future<void> delete(String path) async => dio.delete(path);
  Future<Map<String, dynamic>?> preferences() async {
    final r = await dio.get(ApiConstants.preferences);
    return r.data == null ? null : Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> savePreferences(
          Map<String, dynamic> data) async =>
      Map<String, dynamic>.from(
          (await dio.put(ApiConstants.preferences, data: data)).data);
  Future<Map<String, dynamic>> userUpdate(Map<String, dynamic> data) async =>
      Map<String, dynamic>.from(
          (await dio.put(ApiConstants.currentUser, data: data)).data);

  Future<Map<String, dynamic>> analyticalQueryVoice(
      List<int> bytes, String filename,
      {int? clientId}) async {
    final form = FormData.fromMap({
      'audio': MultipartFile.fromBytes(bytes, filename: filename),
      if (clientId != null) 'client_id': clientId,
    });
    return Map<String, dynamic>.from(
        (await dio.post(ApiConstants.analyticalQueryVoice, data: form)).data);
  }
}
