import 'package:bikebooking/core/utils/geo_utils.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';

/// Ranks (and optionally radius-filters) products for the listing pages.
///
/// When [userLatitude]/[userLongitude] are provided, products are ranked by
/// distance from the user (nearest first), falling back to the legacy
/// address-string matching when coordinates are unavailable on either side.
///
/// When [maxDistanceKm] is provided alongside user coordinates, products that
/// have coordinates and lie beyond that radius are excluded. Products without
/// coordinates are kept (we can't verify their distance) so older listings
/// remain visible.
List<ProductModel> rankJustAddedProductsByLocation({
  required List<ProductModel> products,
  required String selectedLocationAddress,
  double? userLatitude,
  double? userLongitude,
  double? maxDistanceKm,
  int limit = 10,
  void Function(String productId)? onExpiredBoost,
}) {
  final hasUserCoords = userLatitude != null && userLongitude != null;

  double? distanceFor(ProductModel product) {
    if (!hasUserCoords ||
        product.latitude == null ||
        product.longitude == null) {
      return null;
    }
    return GeoUtils.distanceKm(
      userLatitude,
      userLongitude,
      product.latitude!,
      product.longitude!,
    );
  }

  final editorial = <ProductModel>[];
  final matchingBoosted = <ProductModel>[];
  final exactMatchingRegular = <ProductModel>[];
  final partialMatchingRegular = <ProductModel>[];
  final otherProducts = <ProductModel>[];

  for (final product in products) {
    final distance = distanceFor(product);

    // Hard radius filter: drop products with coordinates beyond the radius.
    if (maxDistanceKm != null && distance != null && distance > maxDistanceKm) {
      continue;
    }

    final matchScore = _getLocationMatchScore(
      product.location,
      selectedLocationAddress,
    );

    if (product.isCurrentlyEditorialFeatured) {
      editorial.add(product);
    } else if (product.isCurrentlyBoosted) {
      if (distance != null || matchScore > 0) {
        matchingBoosted.add(product);
      } else {
        otherProducts.add(product);
      }
    } else {
      if (product.isBoosted && !product.isCurrentlyBoosted) {
        final productId = product.id?.trim() ?? '';
        if (productId.isNotEmpty) {
          onExpiredBoost?.call(productId);
        }
      }

      if (matchScore == 2) {
        exactMatchingRegular.add(product);
      } else if (matchScore == 1) {
        partialMatchingRegular.add(product);
      } else {
        otherProducts.add(product);
      }
    }
  }

  // When user coordinates are available, sort each non-editorial tier by
  // distance (nearest first). Products without a known distance sort last.
  if (hasUserCoords) {
    int byDistance(ProductModel a, ProductModel b) {
      final da = distanceFor(a);
      final db = distanceFor(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    }

    matchingBoosted.sort(byDistance);
    exactMatchingRegular.sort(byDistance);
    partialMatchingRegular.sort(byDistance);
    otherProducts.sort(byDistance);
  }

  return [
    ...editorial,
    ...matchingBoosted,
    ...exactMatchingRegular,
    ...partialMatchingRegular,
    ...otherProducts,
  ].take(limit).toList(growable: false);
}

int _getLocationMatchScore(String? productLocation, String selectedAddress) {
  final listingLocation = _normalizeLocationText(productLocation);
  final selectedLocation = _normalizeLocationText(selectedAddress);
  if (listingLocation.isEmpty || selectedLocation.isEmpty) {
    return 0; // No match
  }

  if (listingLocation == selectedLocation ||
      selectedLocation.contains(listingLocation) ||
      listingLocation.contains(selectedLocation)) {
    return 2; // Exact or substring match (Location)
  }

  final listingTokens = _locationTokens(listingLocation);
  final selectedTokens = _locationTokens(selectedLocation);
  if (listingTokens.isEmpty || selectedTokens.isEmpty) {
    return 0; // No match
  }

  if (listingTokens.any(selectedTokens.contains)) {
    return 1; // Token match (District/Nearby)
  }

  return 0; // No match
}

String _normalizeLocationText(String? value) {
  return (value ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

Set<String> _locationTokens(String value) {
  const ignoredTokens = {
    'and',
    'area',
    'city',
    'dist',
    'district',
    'india',
    'near',
    'road',
    'state',
    'street',
  };

  return value
      .split(' ')
      .where((token) => token.length >= 3 && !ignoredTokens.contains(token))
      .toSet();
}
