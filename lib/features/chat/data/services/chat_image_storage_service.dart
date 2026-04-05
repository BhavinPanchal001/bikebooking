import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatImageStorageService {
  ChatImageStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference get _chatImagesRef => _storage.ref().child('chat_images');

  Future<String> uploadChatImage({
    required String chatId,
    required String userId,
    required XFile imageFile,
  }) async {
    final trimmedChatId = chatId.trim();
    final trimmedUserId = userId.trim();
    if (trimmedChatId.isEmpty || trimmedUserId.isEmpty) {
      throw ArgumentError(
          'Chat ID and user ID are required to upload an image.');
    }

    final bytes = await imageFile.readAsBytes();
    final extension = _normalizedExtension(imageFile.path);
    final uploadId = DateTime.now().microsecondsSinceEpoch;
    final imageRef = _chatImagesRef.child(
      '$trimmedChatId/$trimmedUserId/$uploadId$extension',
    );

    final taskSnapshot = await imageRef.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        customMetadata: {
          'chatId': trimmedChatId,
          'userId': trimmedUserId,
        },
      ),
    );

    return taskSnapshot.ref.getDownloadURL();
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
