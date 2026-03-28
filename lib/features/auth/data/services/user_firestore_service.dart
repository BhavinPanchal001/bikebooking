import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFirestoreService {
  UserFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

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
}
