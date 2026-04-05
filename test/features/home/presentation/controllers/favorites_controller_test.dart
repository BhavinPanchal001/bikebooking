import 'dart:async';

import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/favorites_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProductModel buildProduct({
    required String id,
    String sellerId = 'seller-1',
    String status = ProductStatus.active,
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
      sellerId: sellerId,
      sellerName: 'Seller One',
      status: status,
      fuelType: 'Petrol',
      kilometerDriven: 1200,
      numberOfOwners: 1,
      subCategory: 'Cruiser Bikes',
    );
  }

  Future<void> flushStreams() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('binds favorites from Firestore and reacts to product updates',
      () async {
    final favoriteIdsController = StreamController<List<String>>.broadcast();
    final productControllers = <String, StreamController<ProductModel?>>{
      'product-1': StreamController<ProductModel?>.broadcast(),
      'product-2': StreamController<ProductModel?>.broadcast(),
    };

    final controller = FavoritesController(
      favoritesService: FavoritesFirestoreService.withOverrides(
        watchFavoriteProductIdsOverride: (userId) {
          expect(userId, 'user-1');
          return favoriteIdsController.stream;
        },
      ),
      productFirestoreService: ProductFirestoreService.withOverrides(
        watchProductByIdOverride: (id, includeInactive) {
          expect(includeInactive, isTrue);
          return productControllers[id]!.stream;
        },
      ),
      currentUserIdProvider: () => 'user-1',
      hiddenUserIdsLoader: (_) async => const <String>{},
    );

    controller.onInit();
    await flushStreams();

    favoriteIdsController.add(const <String>['product-1', 'product-2']);
    await flushStreams();
    productControllers['product-1']!.add(buildProduct(id: 'product-1'));
    productControllers['product-2']!.add(
      buildProduct(
        id: 'product-2',
        status: ProductStatus.sold,
      ),
    );
    await flushStreams();

    expect(controller.isFavorite(buildProduct(id: 'product-1')), isTrue);
    expect(controller.isFavorite(buildProduct(id: 'product-2')), isTrue);
    expect(
      controller.favorites.map((product) => product.id).toList(growable: false),
      <String?>['product-1'],
    );

    productControllers['product-2']!.add(buildProduct(id: 'product-2'));
    await flushStreams();

    expect(
      controller.favorites.map((product) => product.id).toList(growable: false),
      <String?>['product-1', 'product-2'],
    );

    controller.onClose();
    await favoriteIdsController.close();
    for (final streamController in productControllers.values) {
      await streamController.close();
    }
  });

  test('rebinds to the active user and persists toggle actions', () async {
    var currentUserId = 'user-1';
    final user1FavoriteIds = StreamController<List<String>>.broadcast();
    final user2FavoriteIds = StreamController<List<String>>.broadcast();
    final productControllers = <String, StreamController<ProductModel?>>{
      'product-1': StreamController<ProductModel?>.broadcast(),
      'product-2': StreamController<ProductModel?>.broadcast(),
    };
    final watchedUsers = <String>[];
    final addedFavorites = <String>[];
    final removedFavorites = <String>[];

    final controller = FavoritesController(
      favoritesService: FavoritesFirestoreService.withOverrides(
        watchFavoriteProductIdsOverride: (userId) {
          watchedUsers.add(userId);
          return userId == 'user-1'
              ? user1FavoriteIds.stream
              : user2FavoriteIds.stream;
        },
        addFavoriteOverride: (userId, product) async {
          addedFavorites.add('$userId:${product.id}');
        },
        removeFavoriteOverride: (userId, productId) async {
          removedFavorites.add('$userId:$productId');
        },
      ),
      productFirestoreService: ProductFirestoreService.withOverrides(
        watchProductByIdOverride: (id, includeInactive) {
          return productControllers[id]?.stream ??
              Stream<ProductModel?>.value(null);
        },
      ),
      currentUserIdProvider: () => currentUserId,
      hiddenUserIdsLoader: (_) async => const <String>{},
    );

    controller.onInit();
    await flushStreams();

    user1FavoriteIds.add(const <String>['product-1']);
    await flushStreams();
    productControllers['product-1']!.add(buildProduct(id: 'product-1'));
    await flushStreams();

    expect(
      controller.favorites.map((product) => product.id).toList(growable: false),
      <String?>['product-1'],
    );

    currentUserId = 'user-2';
    await controller.bindToCurrentUser();
    await flushStreams();
    user2FavoriteIds.add(const <String>['product-2']);
    await flushStreams();
    productControllers['product-2']!.add(buildProduct(id: 'product-2'));
    await flushStreams();

    expect(watchedUsers, <String>['user-1', 'user-2']);
    expect(
      controller.favorites.map((product) => product.id).toList(growable: false),
      <String?>['product-2'],
    );

    final added = controller.toggleFavorite(buildProduct(id: 'product-3'));
    await flushStreams();
    expect(added, isTrue);
    expect(addedFavorites, <String>['user-2:product-3']);

    final removed = controller.toggleFavorite(buildProduct(id: 'product-2'));
    await flushStreams();
    expect(removed, isFalse);
    expect(removedFavorites, <String>['user-2:product-2']);
    expect(controller.isFavorite(buildProduct(id: 'product-2')), isFalse);

    controller.onClose();
    await user1FavoriteIds.close();
    await user2FavoriteIds.close();
    for (final streamController in productControllers.values) {
      await streamController.close();
    }
  });

  test('retries favorite persistence after restoring a firestore session',
      () async {
    var addAttempts = 0;
    var ensuredSessionCount = 0;

    final controller = FavoritesController(
      favoritesService: FavoritesFirestoreService.withOverrides(
        watchFavoriteProductIdsOverride: (_) =>
            Stream<List<String>>.value(const <String>[]),
        addFavoriteOverride: (userId, product) async {
          addAttempts += 1;
          if (addAttempts == 1) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unauthenticated',
            );
          }
        },
      ),
      productFirestoreService: ProductFirestoreService.withOverrides(
        watchProductByIdOverride: (_, __) => Stream<ProductModel?>.value(null),
      ),
      currentUserIdProvider: () => 'user-1',
      hiddenUserIdsLoader: (_) async => const <String>{},
      firestoreSessionEnsurer: () async {
        ensuredSessionCount += 1;
        return true;
      },
      firestoreSessionErrorProvider: () =>
          'Unable to start a Firebase session for favorites.',
      favoriteErrorNotifier: (_, __) {},
    );

    controller.onInit();
    await flushStreams();

    final added = controller.toggleFavorite(buildProduct(id: 'product-9'));
    await flushStreams();

    expect(added, isTrue);
    expect(addAttempts, 2);
    expect(ensuredSessionCount, 1);
    expect(controller.isFavorite(buildProduct(id: 'product-9')), isTrue);

    controller.onClose();
  });
}
