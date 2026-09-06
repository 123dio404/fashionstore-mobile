import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/catalog_models.dart';

class CatalogRepository {
  final Dio _dio;

  CatalogRepository({ApiClient? client}) : _dio = (client ?? ApiClient()).dio;

  Future<List<ProductResponse>> products() async {
    final response = await _dio.get(ApiConstants.products);
    return (response.data as List<dynamic>)
        .map((item) => ProductResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<BranchResponse>> branches() async {
    final response = await _dio.get(ApiConstants.branches);
    return (response.data as List<dynamic>)
        .map((item) => BranchResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AvailabilityResponse>> availability(String productId, String branchId) async {
    final response = await _dio.get(
      '${ApiConstants.products}/$productId${ApiConstants.availability}',
      queryParameters: {'branch_id': branchId},
    );
    return (response.data as List<dynamic>)
        .map((item) => AvailabilityResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
