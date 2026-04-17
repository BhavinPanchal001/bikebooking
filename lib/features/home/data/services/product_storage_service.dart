import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class ProductStorageService {
  ProductStorageService({FirebaseStorage? storage})
      : _storage = storage,
        _uploadProductImagesOverride = null;

  ProductStorageService.withOverride({
    FirebaseStorage? storage,
    Future<List<String>> Function({
      required String sellerId,
      required List<Uint8List> imageBytes,
    })? uploadProductImagesOverride,
  })  : _storage = storage,
        _uploadProductImagesOverride = uploadProductImagesOverride;

  final FirebaseStorage? _storage;
  final Future<List<String>> Function({
    required String sellerId,
    required List<Uint8List> imageBytes,
  })? _uploadProductImagesOverride;

  Reference get _productImagesRef =>
      (_storage ?? FirebaseStorage.instance).ref().child('product_images');

  Future<List<String>> uploadProductImages({
    required String sellerId,
    required List<Uint8List> imageBytes,
  }) async {
    final uploadProductImagesOverride = _uploadProductImagesOverride;
    if (uploadProductImagesOverride != null) {
      return uploadProductImagesOverride(
        sellerId: sellerId,
        imageBytes: imageBytes,
      );
    }

    if (imageBytes.isEmpty) {
      return const [];
    }

    final uploadBatchId = DateTime.now().millisecondsSinceEpoch;
    final downloadUrls = <String>[];

    for (var index = 0; index < imageBytes.length; index++) {
      final imageRef = _productImagesRef.child(
        '$sellerId/$uploadBatchId-$index.jpg',
      );

      final taskSnapshot = await imageRef.putData(
        imageBytes[index],
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'sellerId': sellerId},
        ),
      );

      downloadUrls.add(await taskSnapshot.ref.getDownloadURL());
    }

    return downloadUrls;
  }

  /// Deletes a single product image from Firebase Storage by its download URL.
  ///
  /// Returns `true` if the image was successfully deleted, `false` otherwise.
  Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      final ref =
          (_storage ?? FirebaseStorage.instance).refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (_) {
      // The image may already have been deleted or the URL may be invalid.
      return false;
    }
  }
}
