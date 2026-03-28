import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class ProductStorageService {
  ProductStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference get _productImagesRef => _storage.ref().child('product_images');

  Future<List<String>> uploadProductImages({
    required String sellerId,
    required List<Uint8List> imageBytes,
  }) async {
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

      try {
        downloadUrls.add(await taskSnapshot.ref.getDownloadURL());
      } on FirebaseException catch (error) {
        if (_canFallbackToStorageUri(error.code)) {
          downloadUrls.add(
            'gs://${taskSnapshot.ref.bucket}/${taskSnapshot.ref.fullPath}',
          );
          continue;
        }
        rethrow;
      }
    }

    return downloadUrls;
  }

  bool _canFallbackToStorageUri(String code) {
    final normalizedCode = code.toLowerCase();
    return normalizedCode == 'object-not-found' ||
        normalizedCode == 'unauthorized' ||
        normalizedCode == 'unauthenticated';
  }
}
