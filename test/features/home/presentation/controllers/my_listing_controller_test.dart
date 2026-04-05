import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/my_listing_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  ProductModel buildProduct({String status = ProductStatus.active}) {
    return ProductModel(
      id: 'product-1',
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

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test('updates listing status and keeps local state in sync', () async {
    String? updatedStatus;

    final controller = MyListingController(
      firestoreService: ProductFirestoreService.withOverrides(
        getUserProductsOverride: (userId) async {
          expect(userId, 'seller-1');
          return <ProductModel>[buildProduct()];
        },
        updateProductStatusOverride: (id, status) async {
          expect(id, 'product-1');
          updatedStatus = status;
        },
      ),
      currentSellerIdProvider: () => 'seller-1',
    );

    await controller.loadProducts();
    final success = await controller.updateProductStatus(
      productId: 'product-1',
      status: ProductStatus.sold,
    );

    expect(success, isTrue);
    expect(updatedStatus, ProductStatus.sold);
    expect(controller.products.single.status, ProductStatus.sold);
    expect(controller.products.single.isSold, isTrue);
  });

  test('deleteProduct removes the listing from local state on success',
      () async {
    String? deletedProductId;

    final controller = MyListingController(
      firestoreService: ProductFirestoreService.withOverrides(
        getUserProductsOverride: (_) async => <ProductModel>[buildProduct()],
        deleteProductOverride: (id) async => deletedProductId = id,
      ),
      currentSellerIdProvider: () => 'seller-1',
    );

    await controller.loadProducts();
    final success = await controller.deleteProduct('product-1');

    expect(success, isTrue);
    expect(deletedProductId, 'product-1');
    expect(controller.products, isEmpty);
  });

  test('loadProducts keeps sold listings visible for the seller', () async {
    final controller = MyListingController(
      firestoreService: ProductFirestoreService.withOverrides(
        getUserProductsOverride: (_) async => <ProductModel>[
          buildProduct(status: ProductStatus.active),
          buildProduct(status: ProductStatus.sold).copyWith(id: 'product-2'),
        ],
      ),
      currentSellerIdProvider: () => 'seller-1',
    );

    await controller.loadProducts();

    expect(controller.products.length, 2);
    expect(controller.products.last.isSold, isTrue);
  });
}
