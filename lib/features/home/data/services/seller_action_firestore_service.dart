import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockException implements Exception {
  const UserBlockException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SellerActionFirestoreService {
  SellerActionFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _sellerReportsRef =>
      _firestore.collection('seller_reports');

  CollectionReference<Map<String, dynamic>> get _userBlocksRef =>
      _firestore.collection('user_blocks');

  String _blockDocumentId({
    required String blockerId,
    required String blockedUserId,
  }) {
    return '${blockerId.trim()}_${blockedUserId.trim()}';
  }

  Future<void> reportSeller({
    required String sellerId,
    required String sellerName,
    required String reporterId,
    required String reporterName,
    required String reason,
    String details = '',
  }) async {
    await _sellerReportsRef.add({
      'sellerId': sellerId,
      'sellerName': sellerName,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason,
      'details': details.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isSellerBlocked({
    required String userId,
    required String sellerId,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedSellerId = sellerId.trim();
    if (normalizedUserId.isEmpty || normalizedSellerId.isEmpty) {
      return false;
    }

    try {
      final blockDoc = await _userBlocksRef
          .doc(
            _blockDocumentId(
              blockerId: normalizedUserId,
              blockedUserId: normalizedSellerId,
            ),
          )
          .get();
      if (blockDoc.exists) {
        return true;
      }
    } on FirebaseException {
      // Fall back to the legacy array field below.
    }

    final snapshot = await _usersRef.doc(normalizedUserId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return false;
    }

    final blockedSellerIds =
        List<String>.from(data['blockedSellerIds'] ?? const <String>[]);
    return blockedSellerIds.contains(normalizedSellerId);
  }

  Future<void> blockSeller({
    required String userId,
    required String sellerId,
    required String sellerName,
    String sellerPhotoUrl = '',
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedSellerId = sellerId.trim();
    if (normalizedUserId.isEmpty || normalizedSellerId.isEmpty) {
      return;
    }

    final normalizedSellerName =
        sellerName.trim().isNotEmpty ? sellerName.trim() : 'Seller';
    final normalizedPhotoUrl = sellerPhotoUrl.trim();

    await _usersRef.doc(normalizedUserId).set(
      {
        'blockedSellerIds': FieldValue.arrayUnion([normalizedSellerId]),
        'blockedSellersMeta.$normalizedSellerId': {
          'sellerName': normalizedSellerName,
          if (normalizedPhotoUrl.isNotEmpty) 'photoUrl': normalizedPhotoUrl,
          'blockedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await _userBlocksRef
          .doc(
        _blockDocumentId(
          blockerId: normalizedUserId,
          blockedUserId: normalizedSellerId,
        ),
      )
          .set(
        {
          'blockerId': normalizedUserId,
          'blockedUserId': normalizedSellerId,
          'sellerName': normalizedSellerName,
          'fullName': normalizedSellerName,
          'photoUrl': normalizedPhotoUrl,
          'blockedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied' &&
          error.code != 'unauthenticated') {
        rethrow;
      }
    }
  }

  Future<void> unblockSeller({
    required String userId,
    required String sellerId,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedSellerId = sellerId.trim();
    if (normalizedUserId.isEmpty || normalizedSellerId.isEmpty) {
      return;
    }

    await _usersRef.doc(normalizedUserId).set(
      {
        'blockedSellerIds': FieldValue.arrayRemove([normalizedSellerId]),
        'blockedSellersMeta.$normalizedSellerId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      final blockDocRef = _userBlocksRef.doc(
        _blockDocumentId(
          blockerId: normalizedUserId,
          blockedUserId: normalizedSellerId,
        ),
      );
      final blockDocSnapshot = await blockDocRef.get();
      if (blockDocSnapshot.exists) {
        await blockDocRef.delete();
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied' &&
          error.code != 'unauthenticated') {
        rethrow;
      }
    }
  }

  Future<Set<String>> getBlockedSellerIds(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <String>{};
    }

    final blockedIds = <String>{};

    try {
      final snapshot = await _userBlocksRef
          .where('blockerId', isEqualTo: normalizedUserId)
          .get();
      for (final doc in snapshot.docs) {
        final blockedUserId =
            doc.data()['blockedUserId']?.toString().trim() ?? '';
        if (blockedUserId.isNotEmpty) {
          blockedIds.add(blockedUserId);
        }
      }
    } on FirebaseException {
      // Fall back to the legacy array field below.
    }

    if (blockedIds.isNotEmpty) {
      return blockedIds;
    }

    final snapshot = await _usersRef.doc(normalizedUserId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return const <String>{};
    }

    return List<String>.from(data['blockedSellerIds'] ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<Set<String>> getUsersWhoBlocked(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <String>{};
    }

    try {
      final snapshot = await _userBlocksRef
          .where('blockedUserId', isEqualTo: normalizedUserId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['blockerId']?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet();
    } on FirebaseException {
      return const <String>{};
    }
  }

  Future<Set<String>> getHiddenUserIds(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <String>{};
    }

    final hiddenUserIds = <String>{};
    hiddenUserIds.addAll(await getBlockedSellerIds(normalizedUserId));
    hiddenUserIds.addAll(await getUsersWhoBlocked(normalizedUserId));
    hiddenUserIds.remove(normalizedUserId);
    return hiddenUserIds;
  }

  Future<bool> hasBlockingRelationship({
    required String firstUserId,
    required String secondUserId,
  }) async {
    final normalizedFirstUserId = firstUserId.trim();
    final normalizedSecondUserId = secondUserId.trim();
    if (normalizedFirstUserId.isEmpty || normalizedSecondUserId.isEmpty) {
      return false;
    }

    try {
      final directBlock = await _userBlocksRef
          .doc(
            _blockDocumentId(
              blockerId: normalizedFirstUserId,
              blockedUserId: normalizedSecondUserId,
            ),
          )
          .get();
      if (directBlock.exists) {
        return true;
      }

      final reverseBlock = await _userBlocksRef
          .doc(
            _blockDocumentId(
              blockerId: normalizedSecondUserId,
              blockedUserId: normalizedFirstUserId,
            ),
          )
          .get();
      if (reverseBlock.exists) {
        return true;
      }
    } on FirebaseException {
      // Fall back to the legacy blocker array check below.
    }

    final firstBlockedSecond = await isSellerBlocked(
      userId: normalizedFirstUserId,
      sellerId: normalizedSecondUserId,
    );
    if (firstBlockedSecond) {
      return true;
    }

    return isSellerBlocked(
      userId: normalizedSecondUserId,
      sellerId: normalizedFirstUserId,
    );
  }

  Future<List<Map<String, dynamic>>> getBlockedSellers(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final blockedUsersById = <String, Map<String, dynamic>>{};

    try {
      final snapshot = await _userBlocksRef
          .where('blockerId', isEqualTo: normalizedUserId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final blockedUserId = data['blockedUserId']?.toString().trim() ?? '';
        if (blockedUserId.isEmpty) {
          continue;
        }

        blockedUsersById[blockedUserId] = {
          'blockedUserId': blockedUserId,
          'sellerName': data['sellerName']?.toString() ?? '',
          'fullName': data['fullName']?.toString() ??
              data['sellerName']?.toString() ??
              '',
          'photoUrl': data['photoUrl']?.toString() ?? '',
          'blockedAt': data['blockedAt'],
        };
      }
    } on FirebaseException {
      // Fall back to the legacy metadata map below.
    }

    final legacySnapshot = await _usersRef.doc(normalizedUserId).get();
    final legacyData = legacySnapshot.data();
    final legacyMeta =
        legacyData?['blockedSellersMeta'] as Map<String, dynamic>? ?? {};

    legacyMeta.forEach((sellerId, sellerData) {
      if (sellerData is! Map) {
        return;
      }

      final normalizedSellerId = sellerId.toString().trim();
      if (normalizedSellerId.isEmpty) {
        return;
      }

      final data = Map<String, dynamic>.from(sellerData);
      final existing =
          blockedUsersById[normalizedSellerId] ?? const <String, dynamic>{};
      final legacyFullName = data['fullName']?.toString().trim() ?? '';
      final legacySellerName = data['sellerName']?.toString().trim() ?? '';
      final legacyPhotoUrl = data['photoUrl']?.toString().trim() ?? '';
      blockedUsersById[normalizedSellerId] = {
        'blockedUserId': normalizedSellerId,
        'sellerName':
            existing['sellerName']?.toString().trim().isNotEmpty == true
                ? existing['sellerName']
                : legacySellerName,
        'fullName': existing['fullName']?.toString().trim().isNotEmpty == true
            ? existing['fullName']
            : (legacyFullName.isNotEmpty ? legacyFullName : legacySellerName),
        'photoUrl': existing['photoUrl']?.toString().trim().isNotEmpty == true
            ? existing['photoUrl']
            : legacyPhotoUrl,
        'blockedAt': existing['blockedAt'] ?? data['blockedAt'],
      };
    });

    final blockedUsers = blockedUsersById.values.toList(growable: false);
    blockedUsers.sort((first, second) {
      final firstBlockedAt = first['blockedAt'] as Timestamp?;
      final secondBlockedAt = second['blockedAt'] as Timestamp?;
      if (firstBlockedAt == null && secondBlockedAt == null) {
        return 0;
      }
      if (firstBlockedAt == null) {
        return 1;
      }
      if (secondBlockedAt == null) {
        return -1;
      }
      return secondBlockedAt.compareTo(firstBlockedAt);
    });

    return blockedUsers;
  }
}
