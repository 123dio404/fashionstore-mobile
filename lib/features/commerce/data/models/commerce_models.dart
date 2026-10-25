/// CU11 — modelos de la respuesta del carrito, la venta y la factura.
///
/// Los números llegan como string desde PostgreSQL (`Numeric`), así que se normalizan
/// con los helpers de `catalog_models.dart`.
library;

import '../../../catalog/data/models/catalog_models.dart' show asDouble, asInt;

class ApiCartItem {
  final int id, stockId, quantity;
  final double price;
  final String productName;
  final String? size, color;
  final bool? isWholesaleApplied;
  final int? wholesaleMinQty;

  const ApiCartItem({
    required this.id,
    required this.stockId,
    required this.quantity,
    required this.price,
    required this.productName,
    this.size,
    this.color,
    this.isWholesaleApplied,
    this.wholesaleMinQty,
  });

  factory ApiCartItem.fromJson(Map<String, dynamic> j) => ApiCartItem(
        id: asInt(j['id']),
        stockId: asInt(j['stock_id']),
        quantity: asInt(j['quantity']),
        price: asDouble(j['price']),
        productName: '${j['product_name'] ?? ''}',
        size: j['size']?.toString(),
        color: j['color']?.toString(),
        isWholesaleApplied: j['is_wholesale_applied'] as bool?,
        wholesaleMinQty: j['wholesale_min_qty'] == null ? null : asInt(j['wholesale_min_qty']),
      );
}

class ApiPayment {
  final String status;
  final String? reference;
  final double amount;

  const ApiPayment({
    required this.status,
    required this.amount,
    this.reference,
  });

  factory ApiPayment.fromJson(Map<String, dynamic> j) => ApiPayment(
        status: '${j['status'] ?? ''}',
        amount: asDouble(j['amount']),
        reference: j['reference']?.toString(),
      );
}

class ApiSale {
  final int id, branchId, clientId;
  final double total;
  final String saleType;
  final String deliveryStatus;
  final String? customerNotes, deliveredAt;
  final List<ApiPayment> payments;

  const ApiSale({
    required this.id,
    required this.branchId,
    required this.clientId,
    required this.total,
    required this.saleType,
    this.deliveryStatus = 'PAGADO',
    this.customerNotes,
    this.deliveredAt,
    this.payments = const [],
  });

  /// Referencia del último pago (la que genera la pasarela simulada).
  String? get reference =>
      payments.isEmpty ? null : payments.last.reference;

  factory ApiSale.fromJson(Map<String, dynamic> j) => ApiSale(
        id: asInt(j['id']),
        branchId: asInt(j['branch_id']),
        clientId: asInt(j['client_id']),
        total: asDouble(j['total']),
        saleType: '${j['sale_type'] ?? ''}',
        deliveryStatus: '${j['delivery_status'] ?? 'PAGADO'}',
        customerNotes: j['customer_notes']?.toString(),
        deliveredAt: j['delivered_at']?.toString(),
        payments: ((j['payments'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => ApiPayment.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ApiInvoice {
  final String invoiceNumber, issuerName, paymentStatus, disclaimer;
  final String? paymentReference, issuerTaxId;
  final double taxRate, subtotal, tax, total;

  const ApiInvoice({
    required this.invoiceNumber,
    required this.issuerName,
    required this.paymentStatus,
    required this.disclaimer,
    required this.taxRate,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.paymentReference,
    this.issuerTaxId,
  });

  /// IVA en porcentaje (0.19 → 19).
  String get taxPercent => (taxRate * 100).toStringAsFixed(
        (taxRate * 100) % 1 == 0 ? 0 : 2,
      );

  factory ApiInvoice.fromJson(Map<String, dynamic> j) => ApiInvoice(
        invoiceNumber: '${j['invoice_number'] ?? ''}',
        issuerName: '${j['issuer_name'] ?? ''}',
        paymentStatus: '${j['payment_status'] ?? ''}',
        disclaimer: '${j['disclaimer'] ?? ''}',
        taxRate: asDouble(j['tax_rate']),
        subtotal: asDouble(j['subtotal']),
        tax: asDouble(j['tax']),
        total: asDouble(j['total']),
        paymentReference: j['payment_reference']?.toString(),
        issuerTaxId: j['issuer_tax_id']?.toString(),
      );
}