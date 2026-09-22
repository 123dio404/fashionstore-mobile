import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/commerce_models.dart';

/// CU10 / CU11 — carrito, checkout y factura contra la API real.
///
/// El checkout del móvil usa la **pasarela simulada** (`payment_provider=simulado`)
/// mientras no haya claves de Stripe vigentes; el contrato es el mismo que usará
/// Stripe, así que solo cambia el nombre del proveedor.
class CommerceRepository {
  final Dio _dio;

  CommerceRepository({ApiClient? client}) : _dio = (client ?? ApiClient()).dio;

  /// Carrito activo del usuario autenticado.
  Future<List<ApiCartItem>> cart() async {
    final response = await _dio.get(ApiConstants.cart);
    final items = (response.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items
        .whereType<Map>()
        .map((item) => ApiCartItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Agrega una variante de la sucursal (fila de inventario) al carrito.
  Future<void> addItem(int stockId, int quantity) async {
    await _dio.post(
      ApiConstants.cartItems,
      data: {'stock_id': stockId, 'quantity': quantity},
    );
  }

  /// Cobra el carrito del backend y registra la venta con su pago.
  Future<ApiSale> checkout({
    required int branchId,
    String provider = 'simulado',
  }) async {
    final response = await _dio.post(
      ApiConstants.checkout,
      data: {
        'branch_id': branchId,
        'payment_provider': provider,
        'payment_status': 'completado',
        'idempotency_key': 'app-${DateTime.now().millisecondsSinceEpoch}',
      },
    );
    return ApiSale.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Documento fiscal simulado de la venta (número, IVA y descargo).
  Future<ApiInvoice> invoice(int saleId) async {
    final response = await _dio.post('${ApiConstants.sales}/$saleId/invoice');
    return ApiInvoice.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// La misma factura en PDF, como bytes.
  Future<List<int>> invoicePdf(int saleId) async {
    final response = await _dio.get<List<int>>(
      '${ApiConstants.sales}/$saleId/invoice.pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }
}