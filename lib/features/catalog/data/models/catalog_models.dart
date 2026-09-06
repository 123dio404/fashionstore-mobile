class VariantResponse {
  final String id;
  final String productId;
  final String sizeId;
  final String colorId;
  final String? barcode;

  const VariantResponse({
    required this.id,
    required this.productId,
    required this.sizeId,
    required this.colorId,
    this.barcode,
  });

  factory VariantResponse.fromJson(Map<String, dynamic> json) => VariantResponse(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        sizeId: json['size_id'] as String,
        colorId: json['color_id'] as String,
        barcode: json['barcode'] as String?,
      );
}

class ProductResponse {
  final String id;
  final String categoryId;
  final String? seasonId;
  final String? supplierId;
  final String name;
  final String sku;
  final String? description;
  final String? technicalMetadata;
  final String? model3dUrl;
  final double price;
  final bool isActive;
  final List<VariantResponse> variants;

  const ProductResponse({
    required this.id,
    required this.categoryId,
    this.seasonId,
    this.supplierId,
    required this.name,
    required this.sku,
    this.description,
    this.technicalMetadata,
    this.model3dUrl,
    required this.price,
    required this.isActive,
    required this.variants,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) => ProductResponse(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        seasonId: json['season_id'] as String?,
        supplierId: json['supplier_id'] as String?,
        name: json['name'] as String,
        sku: json['sku'] as String,
        description: json['description'] as String?,
        technicalMetadata: json['technical_metadata'] as String?,
        model3dUrl: json['model_3d_url'] as String?,
        price: double.parse(json['price'].toString()),
        isActive: json['is_active'] as bool,
        variants: (json['variants'] as List<dynamic>? ?? [])
            .map((item) => VariantResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class AvailabilityResponse {
  final String productId;
  final String variantId;
  final String branchId;
  final int physicalStock;
  final int reservedStock;
  final int availableStock;

  const AvailabilityResponse({
    required this.productId,
    required this.variantId,
    required this.branchId,
    required this.physicalStock,
    required this.reservedStock,
    required this.availableStock,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) => AvailabilityResponse(
        productId: json['product_id'] as String,
        variantId: json['variant_id'] as String,
        branchId: json['branch_id'] as String,
        physicalStock: json['physical_stock'] as int,
        reservedStock: json['reserved_stock'] as int,
        availableStock: json['available_stock'] as int,
      );
}

class BranchResponse {
  final String id;
  final String cityId;
  final String? managerId;
  final String name;
  final String address;
  final int fittingRooms;
  final bool isActive;

  const BranchResponse({
    required this.id,
    required this.cityId,
    this.managerId,
    required this.name,
    required this.address,
    required this.fittingRooms,
    required this.isActive,
  });

  factory BranchResponse.fromJson(Map<String, dynamic> json) => BranchResponse(
        id: json['id'] as String,
        cityId: json['city_id'] as String,
        managerId: json['manager_id'] as String?,
        name: json['name'] as String,
        address: json['address'] as String,
        fittingRooms: json['fitting_rooms'] as int,
        isActive: json['is_active'] as bool,
      );
}
