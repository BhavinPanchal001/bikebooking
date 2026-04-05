import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProductModel buildProduct({
    required String id,
    required String status,
  }) {
    return ProductModel(
      id: id,
      category: 'Bikes',
      title: 'Hunter 350',
      brand: 'Royal Enfield',
      year: 2023,
      description: 'A well maintained bike with full service history.',
      price: 150000,
      location: 'Pune',
      imageUrls: const ['https://example.com/bike.jpg'],
      sellerId: 'seller-1',
      sellerName: 'Seller One',
      status: status,
      fuelType: 'Petrol',
      kilometerDriven: 1200,
      numberOfOwners: 1,
      subCategory: 'Cruiser Bikes',
    );
  }

  test('seller fetch can include sold listings while public fetch hides them',
      () async {
    final service = ProductFirestoreService.withOverrides(
      getUserProductsOverride: (_) async => <ProductModel>[
        buildProduct(id: 'active-1', status: ProductStatus.active),
        buildProduct(id: 'sold-1', status: ProductStatus.sold),
      ],
    );

    final publicProducts = await service.getUserProducts('seller-1');
    final sellerProducts = await service.getUserProducts(
      'seller-1',
      includeInactive: true,
    );

    expect(publicProducts.map((product) => product.id), <String>['active-1']);
    expect(
      sellerProducts.map((product) => product.id),
      <String>['active-1', 'sold-1'],
    );
  });
}
