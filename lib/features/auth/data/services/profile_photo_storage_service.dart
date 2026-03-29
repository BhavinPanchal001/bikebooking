import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoStorageService {
  ProfilePhotoStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference get _profilePhotosRef => _storage.ref().child('profile_photos');

  Future<String> uploadProfilePhoto({
    required String userId,
    required XFile imageFile,
  }) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw ArgumentError('User ID is required to upload a profile photo.');
    }

    final bytes = await imageFile.readAsBytes();
    final extension = _normalizedExtension(imageFile.path);
    final imageRef = _profilePhotosRef.child(
      '$trimmedUserId/avatar$extension',
    );

    final taskSnapshot = await imageRef.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        customMetadata: {'userId': trimmedUserId},
      ),
    );

    return taskSnapshot.ref.getDownloadURL();
  }

  Future<void> deleteProfilePhoto(String photoUrl) async {
    final trimmedPhotoUrl = photoUrl.trim();
    if (trimmedPhotoUrl.isEmpty) {
      return;
    }

    try {
      await _storage.refFromURL(trimmedPhotoUrl).delete();
    } on FirebaseException catch (error) {
      if (_isIgnorableDeleteError(error.code)) {
        return;
      }
      rethrow;
    } on ArgumentError {
      return;
    } on FormatException {
      return;
    }
  }

  bool _isIgnorableDeleteError(String code) {
    final normalizedCode = code.toLowerCase();
    return normalizedCode == 'object-not-found' ||
        normalizedCode == 'unauthorized' ||
        normalizedCode == 'unauthenticated';
  }

  String _normalizedExtension(String path) {
    final separatorIndex = path.lastIndexOf('.');
    if (separatorIndex < 0 || separatorIndex == path.length - 1) {
      return '.jpg';
    }

    final extension = path.substring(separatorIndex).toLowerCase();
    switch (extension) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.heic':
      case '.webp':
        return extension;
      default:
        return '.jpg';
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}
