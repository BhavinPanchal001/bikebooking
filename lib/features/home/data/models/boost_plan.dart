/// Represents a boost plan that a seller can purchase for a specific listing.
class BoostPlan {
  const BoostPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.durationDays,
    required this.priceInPaise,
    required this.displayPrice,
  });

  final String id;
  final String name;
  final String subtitle;
  final int durationDays;

  /// Razorpay requires amounts in paise (1 ₹ = 100 paise).
  final int priceInPaise;
  final String displayPrice;

  // ── Pre-defined plans ──────────────────────────────────────────────────

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
