import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bikebooking/features/home/data/models/product_status.dart';

class ProductModel {
  final String? id;
  final String category;
  final String title;
  final String brand;
  final int? year;
  final String description;
  final double? price;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status;

  // Bikes / Scooter specific
  final String? fuelType;
  final int? kilometerDriven;
  final int? numberOfOwners;

  // Accessories / Spare Parts specific
  final String? subCategory;
  final String? condition;
  final String? sellerType;

  // Boost fields
  final bool isBoosted;
  final String? boostPlanId;
  final DateTime? boostStartedAt;
  final DateTime? boostExpiresAt;
  final String? boostPaymentId;

  // Editorial featured (admin hand-picked, independent of paid boosts).
  final bool isEditorialFeatured;
  final DateTime? editorialFeaturedAt;

  ProductModel({
    this.id,
    required this.category,
    required this.title,
    required this.brand,
    this.year,
    this.description = '',
    this.price,
    this.location,
    this.latitude,
    this.longitude,
    this.imageUrls = const [],
    this.sellerId = '',
    this.sellerName = '',
    this.createdAt,
    this.updatedAt,
    String status = ProductStatus.active,
    this.fuelType,
    this.kilometerDriven,
    this.numberOfOwners,
    this.subCategory,
    this.condition,
    this.sellerType,
    this.isBoosted = false,
    this.boostPlanId,
    this.boostStartedAt,
    this.boostExpiresAt,
    this.boostPaymentId,
    this.isEditorialFeatured = false,
    this.editorialFeaturedAt,
  }) : status = ProductStatus.normalize(status);

  bool get isActive => ProductStatus.isActive(status);

  bool get isSold => ProductStatus.isSold(status);

  bool get allowsBuyerActions => ProductStatus.allowsBuyerActions(status);

  String get statusLabel => ProductStatus.label(status);

  /// Returns `true` when the product has an active, non-expired boost.
  bool get isCurrentlyBoosted => isBoosted && boostExpiresAt != null && boostExpiresAt!.isAfter(DateTime.now());

  /// Returns `true` when the admin has editorially featured this product.
  /// Editorial feature has no expiry — admins must un-feature explicitly.
  bool get isCurrentlyEditorialFeatured => isEditorialFeatured;

  ProductModel copyWith({
    String? id,
    String? category,
    String? title,
    String? brand,
    int? year,
    String? description,
    double? price,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? fuelType,
    int? kilometerDriven,
    int? numberOfOwners,
    String? subCategory,
    String? condition,
    String? sellerType,
    bool? isBoosted,
    String? boostPlanId,
    DateTime? boostStartedAt,
    DateTime? boostExpiresAt,
    String? boostPaymentId,
    bool? isEditorialFeatured,
    DateTime? editorialFeaturedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      year: year ?? this.year,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      fuelType: fuelType ?? this.fuelType,
      kilometerDriven: kilometerDriven ?? this.kilometerDriven,
      numberOfOwners: numberOfOwners ?? this.numberOfOwners,
      subCategory: subCategory ?? this.subCategory,
      condition: condition ?? this.condition,
      sellerType: sellerType ?? this.sellerType,
      isBoosted: isBoosted ?? this.isBoosted,
      boostPlanId: boostPlanId ?? this.boostPlanId,
      boostStartedAt: boostStartedAt ?? this.boostStartedAt,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      boostPaymentId: boostPaymentId ?? this.boostPaymentId,
      isEditorialFeatured: isEditorialFeatured ?? this.isEditorialFeatured,
      editorialFeaturedAt: editorialFeaturedAt ?? this.editorialFeaturedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'title': title,
      'brand': brand,
      'year': year,
      'description': description,
      'price': price,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': status,
      'fuelType': fuelType,
      'kilometerDriven': kilometerDriven,
      'numberOfOwners': numberOfOwners,
      'subCategory': subCategory,
      'condition': condition,
      'sellerType': sellerType,
      'isBoosted': isBoosted,
      'boostPlanId': boostPlanId,
      'boostStartedAt': boostStartedAt != null ? Timestamp.fromDate(boostStartedAt!) : null,
      'boostExpiresAt': boostExpiresAt != null ? Timestamp.fromDate(boostExpiresAt!) : null,
      'boostPaymentId': boostPaymentId,
    };
  }

  /// Fields safe for the seller to write on update.
  ///
  /// Payment-gated fields (`isBoosted`, `boostPlanId`, `boostStartedAt`,
  /// `boostExpiresAt`, `boostPaymentId`, `listingFeePaid`) are deliberately
  /// omitted — they are owned exclusively by Cloud Functions using the
  /// admin SDK. Including them here would cause the Firestore rules to
  /// reject edits on boosted products (stale default values would violate
  /// the "must not change" invariants in `firestore.rules`).
  Map<String, dynamic> toUpdateMap() {
    return {
      'category': category,
      'title': title,
      'brand': brand,
      'year': year,
      'description': description,
      'price': price,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': status,
      'fuelType': fuelType,
      'kilometerDriven': kilometerDriven,
      'numberOfOwners': numberOfOwners,
      'subCategory': subCategory,
      'condition': condition,
      'sellerType': sellerType,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      brand: map['brand'] ?? '',
      year: map['year'],
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble(),
      location: map['location'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      status: ProductStatus.normalize(map['status']?.toString()),
      fuelType: map['fuelType'],
      kilometerDriven: map['kilometerDriven'],
      numberOfOwners: map['numberOfOwners'],
      subCategory: map['subCategory'],
      condition: map['condition'],
      sellerType: map['sellerType'],
      isBoosted: map['isBoosted'] == true,
      boostPlanId: map['boostPlanId'],
      boostStartedAt: (map['boostStartedAt'] as Timestamp?)?.toDate(),
      boostExpiresAt: (map['boostExpiresAt'] as Timestamp?)?.toDate(),
      boostPaymentId: map['boostPaymentId'],
      isEditorialFeatured: map['isEditorialFeatured'] == true,
      editorialFeaturedAt: (map['editorialFeaturedAt'] as Timestamp?)?.toDate(),
    );
  }
}
