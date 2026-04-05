import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
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

  test('submitProduct preserves status while editing an existing listing',
      () async {
    ProductModel? updatedProduct;

    final controller = ListProductController(
      firestoreService: ProductFirestoreService.withOverrides(
        updateProductOverride: (id, product) async {
          expect(id, 'product-1');
          updatedProduct = product;
        },
      ),
      sellerIdProvider: () => 'seller-1',
      sellerNameProvider: () => 'Seller One',
    );

    controller.loadProductForEditing(
      buildProduct(status: ProductStatus.sold),
    );

    final success = await controller.submitProduct();

    expect(success, isTrue);
    expect(updatedProduct, isNotNull);
    expect(updatedProduct!.status, ProductStatus.sold);
    expect(updatedProduct!.isSold, isTrue);
  });
}
