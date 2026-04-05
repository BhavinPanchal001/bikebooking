import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:flutter/material.dart';

class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductStatusColors.fromStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        ProductStatus.label(status),
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10 : 12,
        ),
      ),
    );
  }
}

class _ProductStatusColors {
  const _ProductStatusColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;

  factory _ProductStatusColors.fromStatus(String status) {
    return switch (ProductStatus.normalize(status)) {
      ProductStatus.sold => const _ProductStatusColors(
          background: Color(0xFFFFF1E8),
          border: Color(0xFFFFD3B5),
          foreground: Color(0xFFD46A1F),
        ),
      _ => const _ProductStatusColors(
          background: Color(0xFFEAF8ED),
          border: Color(0xFFBFE3C8),
          foreground: Color(0xFF2F7D4A),
        ),
    };
  }
}
