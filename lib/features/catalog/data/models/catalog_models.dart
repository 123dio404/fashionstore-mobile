int asInt(dynamic value) => int.tryParse('$value') ?? 0;
double asDouble(dynamic value) => double.tryParse('$value') ?? 0;

class VariantResponse {
  final int id, productId;
  final int? sizeId, colorId;
  final String? barcode;
  const VariantResponse(
      {required this.id,
      required this.productId,
      this.sizeId,
      this.colorId,
      this.barcode});
  factory VariantResponse.fromJson(Map<String, dynamic> j) => VariantResponse(
      id: asInt(j['id']),
      productId: asInt(j['product_id']),
      sizeId: j['size_id'] == null ? null : asInt(j['size_id']),
      colorId: j['color_id'] == null ? null : asInt(j['color_id']),
      barcode: j['codigo']?.toString() ?? j['barcode']?.toString());
}

class ProductResponse {
  final int id, categoryId;
  final int? seasonId;
  final String name, sku;
  final String? description, technicalMetadata, model3dUrl;
  final double price;
  final bool isActive;
  final List<VariantResponse> variants;
  const ProductResponse(
      {required this.id,
      required this.categoryId,
      this.seasonId,
      required this.name,
      required this.sku,
      this.description,
      this.technicalMetadata,
      this.model3dUrl,
      required this.price,
      required this.isActive,
      required this.variants});
  factory ProductResponse.fromJson(Map<String, dynamic> j) => ProductResponse(
      id: asInt(j['id']),
      categoryId: asInt(j['category_id']),
      seasonId: j['season_id'] == null ? null : asInt(j['season_id']),
      name: '${j['name'] ?? ''}',
      sku: '${j['sku'] ?? j['id'] ?? ''}',
      description: j['description']?.toString(),
      technicalMetadata: j['technical_metadata']?.toString(),
      model3dUrl: j['model_3d_url']?.toString(),
      price: asDouble(j['price']),
      isActive: j['is_active'] as bool? ?? true,
      variants: ((j['variants'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => VariantResponse.fromJson(Map<String, dynamic>.from(e)))
          .toList());
}

class AvailabilityResponse {
  final int productId,
      variantId,
      branchId,
      physicalStock,
      reservedStock,
      availableStock;
  /// CU10/CU11: fila de inventario con la que el carrito y el checkout descuentan stock.
  final int stockId;
  const AvailabilityResponse(
      {required this.productId,
      required this.variantId,
      required this.branchId,
      required this.physicalStock,
      required this.reservedStock,
      required this.availableStock,
      this.stockId = 0});
  factory AvailabilityResponse.fromJson(Map<String, dynamic> j) =>
      AvailabilityResponse(
          productId: asInt(j['product_id']),
          variantId: asInt(j['variant_id']),
          branchId: asInt(j['branch_id']),
          physicalStock: asInt(j['physical_stock']),
          reservedStock: asInt(j['reserved_stock']),
          availableStock: asInt(j['available_stock']),
          stockId: asInt(j['stock_id']));
}

class BranchResponse {
  final int id, cityId;
  final String name, address;
  final bool isActive;
  const BranchResponse(
      {required this.id,
      required this.cityId,
      required this.name,
      required this.address,
      required this.isActive});
  factory BranchResponse.fromJson(Map<String, dynamic> j) => BranchResponse(
      id: asInt(j['id']),
      cityId: asInt(j['city_id']),
      name: '${j['name'] ?? ''}',
      address: '${j['address'] ?? ''}',
      isActive: j['is_active'] as bool? ?? true);
}
