import 'package:bikebooking/features/home/data/models/product_model.dart';

List<ProductModel> rankJustAddedProductsByLocation({
  required List<ProductModel> products,
  required String selectedLocationAddress,
  int limit = 10,
  void Function(String productId)? onExpiredBoost,
}) {
  final editorial = <ProductModel>[];
  final matchingBoosted = <ProductModel>[];
  final exactMatchingRegular = <ProductModel>[];
  final partialMatchingRegular = <ProductModel>[];
  final otherProducts = <ProductModel>[];

  for (final product in products) {
    final matchScore = _getLocationMatchScore(
      product.location,
      selectedLocationAddress,
    );

    if (product.isCurrentlyEditorialFeatured) {
      editorial.add(product);
    } else if (product.isCurrentlyBoosted) {
      if (matchScore > 0) {
        matchingBoosted.add(product);
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
