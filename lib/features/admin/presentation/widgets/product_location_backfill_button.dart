import 'package:bikebooking/features/home/data/services/product_location_backfill_service.dart';
import 'package:flutter/material.dart';

/// Admin button to backfill product coordinates.
/// Place this in an admin panel or settings screen.
class ProductLocationBackfillButton extends StatefulWidget {
  const ProductLocationBackfillButton({super.key});

  @override
  State<ProductLocationBackfillButton> createState() => _ProductLocationBackfillButtonState();
}

class _ProductLocationBackfillButtonState extends State<ProductLocationBackfillButton> {
  bool _isLoading = false;
  String? _status;

  Future<void> _runBackfill() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking...';
    });

    final service = ProductLocationBackfillService();
    final count = await service.getCountNeedingBackfill();

    if (count == 0) {
      setState(() {
        _isLoading = false;
        _status = '✅ All products already have coordinates!';
      });
      return;
    }

    setState(() {
      _status = 'Backfilling $count products...';
    });

    final stats = await service.backfillAll(
      batchSize: 20,
      onProgress: (processed, total) {
        setState(() {
          _status = 'Processed $processed / $total';
        });
      },
    );

    setState(() {
      _isLoading = false;
      _status = '✅ Done! Updated: ${stats.updated}, Failed: ${stats.failed}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Location Backfill',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add latitude/longitude to products created before the distance feature.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_status != null) ...[
              Text(
                _status!,
                style: TextStyle(
                  fontSize: 14,
                  color: _status!.startsWith('✅') ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runBackfill,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Processing...'),
                        ],
                      )
                    : const Text('Run Backfill'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
