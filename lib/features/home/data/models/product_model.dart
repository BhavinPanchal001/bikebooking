import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String? id;
  final String category;
  final String title;
  final String brand;
  final int? year;
  final String description;
  final double? price;
  final String? location;
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

  ProductModel({
    this.id,
    required this.category,
    required this.title,
    required this.brand,
    this.year,
    this.description = '',
    this.price,
    this.location,
    this.imageUrls = const [],
    this.sellerId = '',
    this.sellerName = '',
    this.createdAt,
    this.updatedAt,
    this.status = 'active',
    this.fuelType,
    this.kilometerDriven,
    this.numberOfOwners,
    this.subCategory,
    this.condition,
    this.sellerType,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'title': title,
      'brand': brand,
      'year': year,
      'description': description,
      'price': price,
      'location': location,
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
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'category': category,
      'title': title,
      'brand': brand,
      'year': year,
      'description': description,
      'price': price,
      'location': location,
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
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'active',
      fuelType: map['fuelType'],
      kilometerDriven: map['kilometerDriven'],
      numberOfOwners: map['numberOfOwners'],
      subCategory: map['subCategory'],
      condition: map['condition'],
      sellerType: map['sellerType'],
    );
  }
}
