import 'dart:async';

import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/location/data/services/openstreetmap_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Backfills missing latitude/longitude for products by geocoding their address.
/// This is useful for products created before the location coordinate feature.
class ProductLocationBackfillService {
  ProductLocationBackfillService();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Backfills all products without coordinates.
  /// Returns stats about the operation.
  Future<BackfillStats> backfillAll({
    int batchSize = 50,
    void Function(int processed, int total)? onProgress,
  }) async {
    int processed = 0;
    int updated = 0;
    int failed = 0;
    int skipped = 0;

    // Get initial count
    final countQuery = await _firestore
        .collection('products')
        .where('location', isNotEqualTo: '')
        .count()
        .get();
    final total = countQuery.count ?? 0;

    if (total == 0) {
      return BackfillStats(
        total: 0,
        processed: 0,
        updated: 0,
        failed: 0,
        skipped: 0,
      );
    }

    // Process in batches - query all with location, filter in code
    final products = await _firestore
        .collection('products')
        .where('location', isNotEqualTo: '')
        .limit(batchSize * 2)
        .get();

    for (final doc in products.docs) {
      final product = ProductModel.fromMap(doc.data(), doc.id);
      processed++;

      if (product.location?.trim().isEmpty == true ||
          (product.latitude != null && product.longitude != null)) {
        skipped++;
        onProgress?.call(processed, total);
        continue;
      }

      try {
        final place = await OpenStreetMapService.geocodeAddress(product.location!.trim());
        if (place != null && place.lat != null && place.lng != null) {
          await doc.reference.update({
            'latitude': place.lat,
            'longitude': place.lng,
          });
          updated++;
        } else {
          debugPrint('Could not geocode: ${product.location}');
          failed++;
        }
      } catch (e) {
        debugPrint('Error backfilling ${product.id}: $e');
        failed++;
      }

      onProgress?.call(processed, total);

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return BackfillStats(
      total: total,
      processed: processed,
      updated: updated,
      failed: failed,
      skipped: skipped,
    );
  }

  /// Check if there are products needing backfill
  Future<bool> hasProductsNeedingBackfill() async {
    final snapshot = await _firestore
        .collection('products')
        .where('location', isNotEqualTo: '')
        .where('latitude', isNull: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Get count of products needing backfill
  Future<int> getCountNeedingBackfill() async {
    final count = await _firestore
        .collection('products')
        .where('location', isNotEqualTo: '')
        .where('latitude', isNull: true)
        .count()
        .get();
    return count.count ?? 0;
  }
}

class BackfillStats {
  final int total;
  final int processed;
  final int updated;
  final int failed;
  final int skipped;

  BackfillStats({
    required this.total,
    required this.processed,
    required this.updated,
    required this.failed,
    required this.skipped,
  });

  @override
  String toString() {
    return 'BackfillStats(total: $total, processed: $processed, updated: $updated, failed: $failed, skipped: $skipped)';
  }
}
