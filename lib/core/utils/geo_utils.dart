import 'dart:math' as math;

/// Geo helpers shared across location-based product filtering/ranking.
class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusKm = 6371.0;

  /// Returns the great-circle distance in kilometres between two
  /// latitude/longitude points using the Haversine formula.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
