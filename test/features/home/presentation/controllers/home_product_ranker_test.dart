import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/home_product_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProductModel buildProduct({
    required String id,
    required String location,
    bool isBoosted = false,
    bool isEditorialFeatured = false,
    DateTime? boostExpiresAt,
  }) {
    return ProductModel(
      id: id,
      category: 'Bikes',
      title: 'Hunter 350',
      brand: 'Royal Enfield',
      year: 2023,
      price: 150000,
      location: location,
      sellerId: 'seller-$id',
      sellerName: 'Seller $id',
      isBoosted: isBoosted,
      boostExpiresAt: boostExpiresAt,
      isEditorialFeatured: isEditorialFeatured,
    );
  }

  test('promotes boosted listings only for the selected location', () {
    final future = DateTime.now().add(const Duration(days: 3));
    final products = <ProductModel>[
      buildProduct(
          id: 'other-boosted',
          location: 'Chennai',
          isBoosted: true,
          boostExpiresAt: future),
      buildProduct(id: 'same-regular', location: 'Kothrud, Pune'),
      buildProduct(
          id: 'same-boosted',
          location: 'Pune',
          isBoosted: true,
          boostExpiresAt: future),
      buildProduct(id: 'other-regular', location: 'Mumbai'),
    ];

    final ranked = rankJustAddedProductsByLocation(
      products: products,
      selectedLocationAddress: 'Kothrud, Pune, Maharashtra, India',
    );

    expect(
      ranked.map((product) => product.id).toList(growable: false),
      <String?>[
        'same-boosted',
        'same-regular',
        'other-boosted',
        'other-regular',
      ],
    );
  });

  test('keeps editorial listings above location boosted listings', () {
    final future = DateTime.now().add(const Duration(days: 3));
    final products = <ProductModel>[
      buildProduct(
          id: 'same-boosted',
          location: 'Pune',
          isBoosted: true,
          boostExpiresAt: future),
      buildProduct(
          id: 'editorial', location: 'Mumbai', isEditorialFeatured: true),
    ];

    final ranked = rankJustAddedProductsByLocation(
      products: products,
      selectedLocationAddress: 'Pune',
    );

    expect(
      ranked.map((product) => product.id).toList(growable: false),
      <String?>['editorial', 'same-boosted'],
    );
  });

  test('reports expired boosted listings for cleanup', () {
    final expired = DateTime.now().subtract(const Duration(days: 1));
    final cleanedProductIds = <String>[];
    final products = <ProductModel>[
      buildProduct(
          id: 'expired-boost',
          location: 'Pune',
          isBoosted: true,
          boostExpiresAt: expired),
      buildProduct(id: 'regular', location: 'Pune'),
    ];

    rankJustAddedProductsByLocation(
      products: products,
      selectedLocationAddress: 'Pune',
      onExpiredBoost: cleanedProductIds.add,
    );

    expect(cleanedProductIds, <String>['expired-boost']);
  });
}
