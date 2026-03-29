import 'package:bikebooking/features/home/data/models/seller_review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerReviewFirestoreService {
  SellerReviewFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String sellerId) =>
      _firestore.collection('users').doc(sellerId).collection('reviews');

  Future<List<SellerReviewModel>> getSellerReviews(String sellerId) async {
    final snapshot = await _reviewsRef(sellerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SellerReviewModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
  }

  Future<void> upsertReview(SellerReviewModel review) async {
    final reviewerId = review.reviewerId.trim();
    if (review.sellerId.trim().isEmpty || reviewerId.isEmpty) {
      throw ArgumentError('Seller ID and reviewer ID are required.');
    }

    final docRef = _reviewsRef(review.sellerId).doc(reviewerId);
    final existingSnapshot = await docRef.get();
    final payload = existingSnapshot.exists
        ? {
            ...review.toUpdateMap(),
            'createdAt': existingSnapshot.data()?['createdAt'] ??
                FieldValue.serverTimestamp(),
          }
        : review.toCreateMap();

    await docRef.set(payload, SetOptions(merge: true));
  }
}
