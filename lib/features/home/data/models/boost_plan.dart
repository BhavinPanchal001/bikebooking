/// Represents a purchasable plan (boost or listing-fee) fetched from the
/// admin-configured Firestore `/fee_config` master.
///
/// Until MS3 #1 shipped, these were three hardcoded plans bundled with the
/// app binary. The static [allPlans] list is kept as a safety fallback when
/// the admin has not yet seeded `/fee_config` but **the source of truth is
/// now Firestore**. Editing a plan from the admin panel updates this price
/// for every user on the next stream tick without any app release.
class BoostPlan {
  const BoostPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.durationDays,
    required this.priceInPaise,
    required this.displayPrice,
  });

  /// Builds a plan from a Firestore `/fee_config/{slug}` document snapshot.
  ///
  /// Only entries where `kind == 'boost'` should be passed in here.
  factory BoostPlan.fromFeeConfig(
    String slug,
    Map<String, dynamic> data,
  ) {
    final amount = _toInt(data['amountPaise']) ?? 0;
    return BoostPlan(
      id: slug,
      name: (data['displayName'] as String?)?.trim().isNotEmpty == true
          ? data['displayName'] as String
          : slug,
      subtitle: (data['subtitle'] as String?) ?? '',
      durationDays: _toInt(data['durationDays']) ?? 0,
      priceInPaise: amount,
      displayPrice: _formatPaise(amount),
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final int durationDays;

  /// Razorpay requires amounts in paise (1 INR = 100 paise).
  final int priceInPaise;
  final String displayPrice;

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _formatPaise(int paise) {
    final rupees = paise / 100.0;
    return 'Rs.${rupees.toStringAsFixed(2)}';
  }

  // ── Fallback plans (used only when /fee_config is empty) ─────────────────

  static const basic = BoostPlan(
    id: 'basic_boost',
    name: 'Basic Boost',
    subtitle: '3 Days Boost',
    durationDays: 3,
    priceInPaise: 9900,
    displayPrice: 'Rs.99.00',
  );

  static const popular = BoostPlan(
    id: 'popular_boost',
    name: 'Popular Boost',
    subtitle: '7 Days Boost',
    durationDays: 7,
    priceInPaise: 19900,
    displayPrice: 'Rs.199.00',
  );

  static const premium = BoostPlan(
    id: 'premium_boost',
    name: 'Premium Boost',
    subtitle: '15 Days Boost',
    durationDays: 15,
    priceInPaise: 39900,
    displayPrice: 'Rs.399.00',
  );

  static const List<BoostPlan> allPlans = [basic, popular, premium];
}
