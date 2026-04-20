import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bikebooking/features/home/data/models/boost_plan.dart';

/// Streams the admin-configured `/fee_config` master collection.
///
/// Every purchasable fee in the app (boost plans, listing fee, any future
/// verification / featured fees) is represented by a single document keyed by
/// a stable slug. Edits from the admin panel propagate to users instantly.
class FeeConfigService {
  FeeConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('fee_config');

  /// Streams all active boost plans sorted by `sortOrder` ascending.
  ///
  /// Falls back to [BoostPlan.allPlans] if the collection is empty so the
  /// app still works before the admin has seeded master data.
  Stream<List<BoostPlan>> watchBoostPlans() {
    return _ref.where('kind', isEqualTo: 'boost').snapshots().map((snapshot) {
      final plans = <BoostPlan>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == false) continue;
        plans.add(BoostPlan.fromFeeConfig(doc.id, data));
      }
      if (plans.isEmpty) {
        return BoostPlan.allPlans;
      }
      plans.sort((a, b) {
        if (a.priceInPaise != b.priceInPaise) {
          return a.priceInPaise.compareTo(b.priceInPaise);
        }
        return a.durationDays.compareTo(b.durationDays);
      });
      return plans;
    });
  }

  /// Fetches a single fee configuration (typically `listing_fee`).
  ///
  /// Returns `null` when the admin has not configured this fee or has
  /// disabled it — callers should then skip the paywall.
  Future<FeeConfigEntry?> getActiveFee(String slug) async {
    final snapshot = await _ref.doc(slug).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    if (data['isActive'] == false) return null;
    return FeeConfigEntry.fromMap(snapshot.id, data);
  }
}

class FeeConfigEntry {
  const FeeConfigEntry({
    required this.slug,
    required this.displayName,
    required this.kind,
    required this.amountPaise,
    required this.currency,
    this.durationDays,
    this.subtitle,
  });

  factory FeeConfigEntry.fromMap(String slug, Map<String, dynamic> data) {
    return FeeConfigEntry(
      slug: slug,
      displayName: (data['displayName'] as String?) ?? slug,
      kind: (data['kind'] as String?) ?? '',
      amountPaise: _toInt(data['amountPaise']) ?? 0,
      currency: (data['currency'] as String?) ?? 'INR',
      durationDays: _toInt(data['durationDays']),
      subtitle: data['subtitle'] as String?,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  final String slug;
  final String displayName;
  final String kind;
  final int amountPaise;
  final String currency;
  final int? durationDays;
  final String? subtitle;
}
