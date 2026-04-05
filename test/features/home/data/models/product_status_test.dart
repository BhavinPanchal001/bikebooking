import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProductModel buildProduct({String? status}) {
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
      status: status ?? ProductStatus.active,
      fuelType: 'Petrol',
      kilometerDriven: 1200,
      numberOfOwners: 1,
      subCategory: 'Cruiser Bikes',
    );
  }

  test('missing status defaults to active when reading from Firestore maps',
      () {
    final product = ProductModel.fromMap(<String, dynamic>{
      'category': 'Bikes',
      'title': 'Hunter 350',
      'brand': 'Royal Enfield',
      'description': 'A well maintained bike with full service history.',
      'price': 150000,
      'location': 'Pune',
      'imageUrls': const ['https://example.com/bike.jpg'],
      'sellerId': 'seller-1',
      'sellerName': 'Seller One',
      'fuelType': 'Petrol',
      'kilometerDriven': 1200,
      'numberOfOwners': 1,
      'subCategory': 'Cruiser Bikes',
      'year': 2023,
    }, 'product-1');

    expect(product.status, ProductStatus.active);
    expect(product.isActive, isTrue);
    expect(product.allowsBuyerActions, isTrue);
  });

  test('sold status round-trips through the model helpers', () {
    final soldProduct = buildProduct(status: ProductStatus.sold);

    expect(soldProduct.toUpdateMap()['status'], ProductStatus.sold);
    expect(soldProduct.statusLabel, 'Sold');
    expect(soldProduct.isSold, isTrue);
    expect(soldProduct.allowsBuyerActions, isFalse);
  });

  test('legacy completed status is normalized to sold', () {
    final product = buildProduct(status: 'completed');

    expect(product.status, ProductStatus.sold);
    expect(product.statusLabel, 'Sold');
    expect(product.isSold, isTrue);
    expect(product.allowsBuyerActions, isFalse);
  });
}
