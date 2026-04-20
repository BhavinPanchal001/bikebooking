class ProductStatus {
  const ProductStatus._();

  static const String active = 'active';
  static const String sold = 'sold';

  /// Listing fee is configured and has not yet been paid. The product is
  /// hidden from public listings until the Cloud Function flips the status
  /// to [active] after `verifyPaymentSignature` succeeds.
  static const String awaitingPayment = 'awaiting_payment';
  static const String _legacyCompleted = 'completed';

  static const Set<String> supportedValues = <String>{
    active,
    sold,
    awaitingPayment,
  };

  static String normalize(String? value) {
    final normalizedValue = value?.trim().toLowerCase() ?? '';
    if (normalizedValue == _legacyCompleted) {
      return sold;
    }
    if (supportedValues.contains(normalizedValue)) {
      return normalizedValue;
    }
    return active;
  }

  static bool isActive(String? value) => normalize(value) == active;

  static bool isSold(String? value) => normalize(value) == sold;

  static bool isInactive(String? value) => !isActive(value);

  static bool allowsBuyerActions(String? value) => isActive(value);

  static String label(String? value) {
    return switch (normalize(value)) {
      sold => 'Sold',
      _ => 'Active',
    };
  }
}
