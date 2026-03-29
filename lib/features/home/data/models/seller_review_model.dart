import 'package:cloud_firestore/cloud_firestore.dart';

class SellerReviewModel {
  const SellerReviewModel({
    this.id,
    required this.sellerId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl = '',
    required this.rating,
    this.comment = '',
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String sellerId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final double rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SellerReviewModel copyWith({
    String? id,
    String? sellerId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerPhotoUrl,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerReviewModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl ?? this.reviewerPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'sellerId': sellerId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'sellerId': sellerId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'rating': rating,
      'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SellerReviewModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return SellerReviewModel(
      id: documentId,
      sellerId: map['sellerId']?.toString() ?? '',
      reviewerId: map['reviewerId']?.toString() ?? '',
      reviewerName: map['reviewerName']?.toString() ?? '',
      reviewerPhotoUrl: map['reviewerPhotoUrl']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      comment: map['comment']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
