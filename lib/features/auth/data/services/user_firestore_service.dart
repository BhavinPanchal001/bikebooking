import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:bikebooking/features/home/data/models/notification_preferences_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFirestoreService {
  UserFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _sellerReportsRef =>
      _firestore.collection('seller_reports');

  Future<AppUserModel?> getUserById(String userId) async {
    final snapshot = await _usersRef.doc(userId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return AppUserModel.fromMap(data, snapshot.id);
  }

  Future<AppUserModel> ensureUser({
    required String userId,
    required String phoneNumber,
  }) async {
    final existingUser = await getUserById(userId);
    if (existingUser == null) {
      final newUser = AppUserModel(
        id: userId,
        phoneNumber: phoneNumber,
        registeredMobileNumber: phoneNumber,
      );

      await _usersRef.doc(userId).set({
        ...newUser.toCreateMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newUser;
    }

    final updates = <String, dynamic>{};
    if (phoneNumber.trim().isNotEmpty &&
        existingUser.phoneNumber.trim() != phoneNumber.trim()) {
      updates['phoneNumber'] = phoneNumber.trim();
    }
    if (existingUser.registeredMobileNumber.trim().isEmpty &&
        phoneNumber.trim().isNotEmpty) {
      updates['registeredMobileNumber'] = phoneNumber.trim();
    }

    if (updates.isEmpty) {
      return existingUser;
    }

    await _usersRef.doc(userId).set({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return (await getUserById(userId)) ??
        existingUser.copyWith(
          phoneNumber: updates['phoneNumber']?.toString(),
          registeredMobileNumber: updates['registeredMobileNumber']?.toString(),
        );
  }

  Future<AppUserModel> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    required String registeredMobileNumber,
  }) async {
    await _usersRef.doc(userId).set({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'registeredMobileNumber': registeredMobileNumber.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updatedUser = await getUserById(userId);
    if (updatedUser == null) {
      throw StateError('Unable to load the updated user profile.');
    }
    return updatedUser;
  }

  Future<AppUserModel> updateLocation({
    required String userId,
    required UserLocationModel location,
  }) async {
    await _usersRef.doc(userId).set({
      'location': location.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updatedUser = await getUserById(userId);
    if (updatedUser == null) {
      throw StateError('Unable to load the updated user location.');
    }
    return updatedUser;
  }

  Future<AppUserModel> updatePhotoUrl({
    required String userId,
    required String photoUrl,
  }) async {
    await _usersRef.doc(userId).set({
      'photoUrl': photoUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updatedUser = await getUserById(userId);
    if (updatedUser == null) {
      throw StateError('Unable to load the updated profile photo.');
    }
    return updatedUser;
  }

  Future<void> savePushToken({
    required String userId,
    required String token,
    String? permissionStatus,
  }) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return;
    }

    await _usersRef.doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([trimmedToken]),
      'notificationsEnabled': true,
      if (permissionStatus != null)
        'notificationPermissionStatus': permissionStatus,
      'notificationTokenUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removePushToken({
    required String userId,
    required String token,
  }) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return;
    }

    await _usersRef.doc(userId).set({
      'fcmTokens': FieldValue.arrayRemove([trimmedToken]),
      'notificationTokenUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotificationPermission({
    required String userId,
    required String permissionStatus,
    required bool isEnabled,
  }) async {
    await _usersRef.doc(userId).set({
      'notificationsEnabled': isEnabled,
      'notificationPermissionStatus': permissionStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<NotificationPreferencesModel> getNotificationPreferences(
    String userId,
  ) async {
    final snapshot = await _usersRef.doc(userId.trim()).get();
    final data = snapshot.data();
    if (data == null) {
      return NotificationPreferencesModel.defaults;
    }

    final preferences = data['notificationPreferences'];
    if (preferences is Map<String, dynamic>) {
      return NotificationPreferencesModel.fromMap(preferences);
    }
    if (preferences is Map) {
      return NotificationPreferencesModel.fromMap(
        Map<String, dynamic>.from(preferences),
      );
    }

    return NotificationPreferencesModel.defaults;
  }

  Future<void> updateNotificationPreferences({
    required String userId,
    required NotificationPreferencesModel preferences,
  }) async {
    await _usersRef.doc(userId.trim()).set({
      'notificationPreferences': preferences.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserAccountData(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return;
    }

    await _deleteCollection(
      _usersRef.doc(trimmedUserId).collection('notifications'),
    );
    await _deleteCollection(
      _usersRef.doc(trimmedUserId).collection('favorites'),
    );
    await _deleteCollection(
      _usersRef.doc(trimmedUserId).collection('recentlyViewed'),
    );
    await _deleteCollection(
      _usersRef.doc(trimmedUserId).collection('reviews'),
    );

    await _deleteQuery(
      _firestore.collectionGroup('reviews').where(
            'reviewerId',
            isEqualTo: trimmedUserId,
          ),
    );
    await _deleteQuery(
      _sellerReportsRef.where('reporterId', isEqualTo: trimmedUserId),
    );
    await _deleteQuery(
      _sellerReportsRef.where('sellerId', isEqualTo: trimmedUserId),
    );

    await _usersRef.doc(trimmedUserId).delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    await _deleteSnapshotDocuments(snapshot.docs);
  }

  Future<void> _deleteQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    final snapshot = await query.get();
    await _deleteSnapshotDocuments(snapshot.docs);
  }

  Future<void> _deleteSnapshotDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    if (documents.isEmpty) {
      return;
    }

    final uniqueReferences =
        <String, DocumentReference<Map<String, dynamic>>>{};
    for (final document in documents) {
      uniqueReferences[document.reference.path] = document.reference;
    }

    final references = uniqueReferences.values.toList(growable: false);
    for (var index = 0; index < references.length; index += 450) {
      final batch = _firestore.batch();
      final chunk = references.skip(index).take(450);
      for (final reference in chunk) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }
}
