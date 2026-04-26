import 'package:bikebooking/features/home/data/models/product_model.dart';

List<ProductModel> rankJustAddedProductsByLocation({
  required List<ProductModel> products,
  required String selectedLocationAddress,
  int limit = 10,
  void Function(String productId)? onExpiredBoost,
}) {
  final editorial = <ProductModel>[];
  final matchingBoosted = <ProductModel>[];
  final matchingRegular = <ProductModel>[];
  final otherProducts = <ProductModel>[];

  for (final product in products) {
    final matchesSelectedLocation = _matchesSelectedLocation(
      product.location,
      selectedLocationAddress,
    );

    if (product.isCurrentlyEditorialFeatured) {
      editorial.add(product);
    } else if (product.isCurrentlyBoosted && matchesSelectedLocation) {
      matchingBoosted.add(product);
    } else {
      if (product.isBoosted && !product.isCurrentlyBoosted) {
        final productId = product.id?.trim() ?? '';
        if (productId.isNotEmpty) {
          onExpiredBoost?.call(productId);
        }
      }

      if (matchesSelectedLocation) {
        matchingRegular.add(product);
      } else {
        otherProducts.add(product);
      }
    }
  }

  return [
    ...editorial,
    ...matchingBoosted,
    ...matchingRegular,
    ...otherProducts,
  ].take(limit).toList(growable: false);
}

bool _matchesSelectedLocation(String? productLocation, String selectedAddress) {
  final listingLocation = _normalizeLocationText(productLocation);
  final selectedLocation = _normalizeLocationText(selectedAddress);
  if (listingLocation.isEmpty || selectedLocation.isEmpty) {
    return false;
  }

  if (listingLocation == selectedLocation ||
      selectedLocation.contains(listingLocation) ||
      listingLocation.contains(selectedLocation)) {
    return true;
  }

  final listingTokens = _locationTokens(listingLocation);
  final selectedTokens = _locationTokens(selectedLocation);
  if (listingTokens.isEmpty || selectedTokens.isEmpty) {
    return false;
  }

  return listingTokens.any(selectedTokens.contains);
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
