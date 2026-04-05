import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:bikebooking/features/home/presentation/widgets/product_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 20),
                  const Text(
                    'Favorites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<FavoritesController>(
                builder: (controller) {
                  if (!controller.hasFavorites) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.favorites.length,
                    itemBuilder: (context, index) {
                      final product = controller.favorites[index];
                      return _buildFavoriteCard(
                        context,
                        controller,
                        product,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFEAF0FB),
                child: Icon(
                  Icons.favorite_border,
                  size: 34,
                  color: Color(0xFF233A66),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No favorites yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A66),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap the heart icon on any product card to save it here for later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5E6E8C),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              CustomGradientButton(
                text: 'Browse products',
                onPressed: () {
                  Navigator.pushNamed(context, '/filter_result',
                      arguments: 'Bikes');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    FavoritesController controller,
    ProductModel product,
  ) {
    final primaryImage = _resolvePrimaryImage(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: 80,
                    color: Colors.white,
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
                      Text(
                        _buildTitle(product),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5E6E8C),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ProductStatusBadge(
                          status: product.status,
                          compact: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildPrice(product),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF151314),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF37474F),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _buildLocation(product),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF37474F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 24,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.removeFavorite(product),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(0.05)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Color(0xFF5E6E8C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomGradientButton(
                    height: 42,
                    text: 'View Details',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/bike_detail',
                        arguments: product,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
}
