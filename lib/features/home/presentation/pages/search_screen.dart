import 'dart:async';

import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/search_controller.dart'
    as home_search;
import 'package:bikebooking/features/home/presentation/widgets/bike_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final home_search.SearchController _searchController;
  late final FavoritesController _favoritesController;
  late final bool _ownsSearchController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<home_search.SearchController>()) {
      _searchController = Get.find<home_search.SearchController>();
      _ownsSearchController = false;
    } else {
      _searchController = Get.put(home_search.SearchController());
      _ownsSearchController = true;
    }

    _favoritesController = Get.find<FavoritesController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.initialize();
    });
  }

  @override
  void dispose() {
    if (_ownsSearchController &&
        Get.isRegistered<home_search.SearchController>()) {
      Get.delete<home_search.SearchController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<home_search.SearchController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FBFF),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 45,
                        child: TextField(
                          controller: controller.searchTextController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onChanged: controller.onSearchChanged,
                          onSubmitted: controller.submitSearch,
                          decoration: InputDecoration(
                            hintText: 'Search products',
                            hintStyle: const TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 15,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(
                                Icons.search,
                                size: 18,
                                color: Color(0xFF5E6E8C),
                              ),
                            ),
                            suffixIcon: controller.hasQuery
                                ? IconButton(
                                    onPressed: controller.clearSearch,
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF5E6E8C),
                                      size: 18,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF1F4F8),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(context, controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    home_search.SearchController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null) {
      return _buildStateView(
        context,
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load search',
        message: controller.errorMessage!,
        actionLabel: 'Try again',
        onAction: controller.refreshData,
      );
    }

    if (controller.hasQuery) {
      return _buildSearchResults(context, controller);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationSection(context, controller),
            const SizedBox(height: 24),
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (controller.recentSearches.isEmpty)
              Text(
                'Your recent searches will appear here.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              )
            else
              ...controller.recentSearches.map(
                (query) => _buildRecentSearchItem(controller, query),
              ),
            const SizedBox(height: 24),
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (controller.recommendedProducts.isEmpty)
              Text(
                'Recommendations will appear after products are loaded.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: controller.recommendedProducts
                      .map(
                        (product) => BikeCard(
                          product: product,
                          onTap: () {
                            unawaited(controller.recordCurrentQuery());
                            Navigator.pushNamed(
                              context,
                              '/bike_detail',
                              arguments: product,
                            );
                          },
                          onFavoriteTap: () {
                            _favoritesController.toggleFavorite(product);
                            controller.refreshRecommendations();
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(
    BuildContext context,
    home_search.SearchController controller,
  ) {
    return GetBuilder<LoginController>(
      builder: (loginController) {
        final selectedLocation =
            loginController.currentUserProfile?.location?.address.trim() ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildLocationButton(
                    icon: Icons.my_location,
                    label: loginController.isFetchingCurrentLocation
                        ? 'Detecting...'
                        : 'Use Current Location',
                    onTap: loginController.isFetchingCurrentLocation ||
                            loginController.isSavingLocation
                        ? null
                        : () async {
                            final location =
                                await loginController.useCurrentLocation(
                              navigateToHome: false,
                              showSuccessSnackbar: true,
                            );
                            if (location != null) {
                              controller.refreshRecommendations();
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLocationButton(
                    icon: Icons.add_circle_outline,
                    label: loginController.isSavingLocation
                        ? 'Saving...'
                        : 'Add New Address',
                    onTap: loginController.isSavingLocation
                        ? null
                        : () async {
                            final didSave = await Navigator.pushNamed(
                              context,
                              '/location_search',
                              arguments: {'returnOnSave': true},
                            );
                            if (didSave == true) {
                              controller.refreshRecommendations();
                            }
                          },
                  ),
                ),
              ],
            ),
            if (selectedLocation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Current search location: $selectedLocation',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5E6E8C),
                  height: 1.5,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    home_search.SearchController controller,
  ) {
    if (controller.searchResults.isEmpty) {
      return _buildStateView(
        context,
        icon: Icons.search_off_outlined,
        title: 'No products found',
        message:
            'Try a different name, brand, location, or category to find more matches.',
        actionLabel: 'Clear search',
        onAction: controller.clearSearch,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        itemCount: controller.searchResults.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${controller.searchResults.length} results for "${controller.currentQuery}"',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            );
          }

          final product = controller.searchResults[index - 1];
          return _buildSearchResultCard(context, controller, product);
        },
      ),
    );
  }

  Widget _buildSearchResultCard(
    BuildContext context,
    home_search.SearchController controller,
    ProductModel product,
  ) {
    final primaryImage = _resolvePrimaryImage(product);
    final tags = _buildTags(product);

    return GestureDetector(
      onTap: () {
        unawaited(controller.recordCurrentQuery());
        Navigator.pushNamed(
          context,
          '/bike_detail',
          arguments: product,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 108,
                  height: 108,
                  color: const Color(0xFFF1F4F8),
                  child: primaryImage != null
                      ? Image.network(
                          primaryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImageFallback(),
                        )
                      : _buildImageFallback(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _buildTitle(product),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0C0E1B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GetBuilder<FavoritesController>(
                          builder: (favoritesController) {
                            final isFavorite =
                                favoritesController.isFavorite(product);
                            return GestureDetector(
                              onTap: () =>
                                  _favoritesController.toggleFavorite(product),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? Colors.red
                                      : const Color(0xFF5E6E8C),
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map((tag) => _buildInfoTag(tag))
                            .toList(growable: false),
                      ),
                    if (tags.isNotEmpty) const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _buildLocation(product),
                            style: const TextStyle(
                              color: Color(0xFF262A36),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _buildPrice(product),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF2E4475),
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(product.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF9F9F9F),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateView(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFFEAF0FB),
                          child: Icon(
                            icon,
                            size: 34,
                            color: const Color(0xFF233A66),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF233A66),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF5E6E8C),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(actionLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2E3E5C)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3E5C),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(
    home_search.SearchController controller,
    String text,
  ) {
    return InkWell(
      onTap: () => controller.applyRecentSearch(text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2E3E5C)),
              ),
            ),
            GestureDetector(
              onTap: () => controller.removeRecentSearch(text),
              child: Icon(Icons.close, color: Colors.grey.shade400, size: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Center(
      child: Image.asset(
        'assets/images/bike.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.directions_bike,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String? _resolvePrimaryImage(ProductModel product) {
    for (final imageUrl in product.imageUrls) {
      final trimmed = imageUrl.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  String _buildTitle(ProductModel product) {
    final parts = <String>[];
    if (product.year != null) {
      parts.add(product.year.toString());
    }
    if (product.brand.trim().isNotEmpty) {
      parts.add(product.brand.trim());
    }
    if (product.title.trim().isNotEmpty) {
      parts.add(product.title.trim());
    }
    return parts.isEmpty ? 'Untitled product' : parts.join(' ');
  }

  String _buildPrice(ProductModel product) {
    if (product.price == null) {
      return 'Price on request';
    }
    final price = product.price!;
    if (price == price.roundToDouble()) {
      return 'Rs.${price.toInt()}';
    }
    return 'Rs.${price.toStringAsFixed(0)}';
  }

  String _buildLocation(ProductModel product) {
    final location = product.location?.trim() ?? '';
    return location.isNotEmpty ? location : 'Location not provided';
  }

  List<String> _buildTags(ProductModel product) {
    final tags = <String>[];
    if (product.kilometerDriven != null) {
      tags.add('${product.kilometerDriven} km');
    }
    if ((product.fuelType ?? '').trim().isNotEmpty) {
      tags.add(product.fuelType!.trim());
    }
    if ((product.subCategory ?? '').trim().isNotEmpty) {
      tags.add(product.subCategory!.trim());
    }
    if (product.year != null) {
      tags.add(product.year.toString());
    }
    if ((product.condition ?? '').trim().isNotEmpty) {
      tags.add(product.condition!.trim());
    }
    return tags.take(3).toList(growable: false);
  }

  String _timeAgo(DateTime? createdAt) {
    if (createdAt == null) {
      return 'Recently added';
    }

    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    }
    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    }
    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return '$months mo ago';
    }
    final years = (difference.inDays / 365).floor();
    return '$years yr ago';
  }
}
