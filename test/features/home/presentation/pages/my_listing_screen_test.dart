import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/my_listing_controller.dart';
import 'package:bikebooking/features/home/presentation/pages/my_listing_screen.dart';
import 'package:flutter/material.dart';
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
      imageUrls: const [],
      sellerId: 'seller-1',
      sellerName: 'Seller One',
      status: status,
      fuelType: 'Petrol',
      kilometerDriven: 1200,
      numberOfOwners: 1,
      subCategory: 'Cruiser Bikes',
    );
  }

  Widget buildTestApp(MyListingController controller) {
    Get.put<MyListingController>(controller);
    return const GetMaterialApp(home: MyListingScreen());
  }

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('active listings show only mark sold action', (tester) async {
    final controller = MyListingController(
      firestoreService: ProductFirestoreService.withOverrides(
        getUserProductsOverride: (_) async => <ProductModel>[buildProduct()],
      ),
      currentSellerIdProvider: () => 'seller-1',
    );

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mark sold'), findsOneWidget);
    expect(find.text('Mark completed'), findsNothing);
  });

  testWidgets('inactive listings show reactivate management and disable edit',
      (tester) async {
    final controller = MyListingController(
      firestoreService: ProductFirestoreService.withOverrides(
        getUserProductsOverride: (_) async => <ProductModel>[
          buildProduct(status: ProductStatus.sold),
        ],
      ),
      currentSellerIdProvider: () => 'seller-1',
    );

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sold'), findsOneWidget);
    expect(find.text('Reactivate to edit'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reactivate'), findsOneWidget);
  });
}
