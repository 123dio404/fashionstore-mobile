import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/catalog_models.dart';

class CatalogRepository {
  final Dio _dio;

  CatalogRepository({ApiClient? client}) : _dio = (client ?? ApiClient()).dio;

  Future<List<ProductResponse>> products({int? tenantId}) async {
    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: tenantId != null ? {'tenant_id': tenantId} : null,
    );
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

  Future<List<AvailabilityResponse>> availability(
      int productId, int branchId) async {
    final response = await _dio.get(
      '${ApiConstants.products}/$productId${ApiConstants.availability}',
      queryParameters: {'branch_id': branchId},
    );
    return (response.data as List<dynamic>)
        .map((item) =>
            AvailabilityResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Consulta el stock real de todas las sucursales en la base de datos de la API
  Future<List<Map<String, dynamic>>> inventoryStock() async {
    final response = await _dio.get('/inventory/stock');
    return (response.data as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  /// Catálogo de tallas (`GET /products/parameters/sizes`), usado para mapear
  /// `size_id` de una variante al nombre que ve el cliente (S/M/L/38…).
  Future<List<Map<String, dynamic>>> sizes() async {
    final response = await _dio.get(ApiConstants.sizes);
    return (response.data as List<dynamic>)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
