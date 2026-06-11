import 'package:bikebooking/features/home/data/services/product_location_backfill_service.dart';
import 'package:flutter/foundation.dart';

/// Run this script to backfill missing lat/long coordinates for all products.
/// 
/// Usage options:
/// 
/// 1. **Run once at app startup** (in main.dart):
///    Add this check in your initialization to backfill automatically:
///    ```dart
///    final backfillService = ProductLocationBackfillService();
///    final stats = await backfillService.backfillAll(batchSize: 10);
///    debugPrint('Backfill complete: $stats');
///    ```
///
/// 2. **Admin-triggered backfill** (add a button in admin panel):
///    Call `backfillProductLocations()` when admin presses the button.
///
/// 3. **Firebase Cloud Function** (for large datasets):
///    Deploy a cloud function that processes products in batches.

Future<void> backfillProductLocations() async {
  debugPrint('🚀 Starting product location backfill...');
  
  final service = ProductLocationBackfillService();
  
  // Check how many need backfilling
  final count = await service.getCountNeedingBackfill();
  if (count == 0) {
    debugPrint('✅ No products need backfilling!');
    return;
  }
  
  debugPrint('📦 Found $count products without coordinates');
  
  // Run backfill with progress tracking
  final stats = await service.backfillAll(
    batchSize: 20, // Process 20 at a time
    onProgress: (processed, total) {
      final percent = ((processed / total) * 100).toStringAsFixed(1);
      debugPrint('⏳ Progress: $processed/$total ($percent%)');
    },
  );
  
  debugPrint('✅ Backfill complete!');
  debugPrint('   Total: ${stats.total}');
  debugPrint('   Updated: ${stats.updated}');
  debugPrint('   Failed: ${stats.failed}');
  debugPrint('   Skipped: ${stats.skipped}');
}
