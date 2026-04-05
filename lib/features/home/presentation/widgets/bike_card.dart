import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:bikebooking/features/home/presentation/widgets/product_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BikeCard extends StatelessWidget {
  const BikeCard({
    super.key,
    required this.product,
    this.width = 165,
    this.onTap,
    this.onFavoriteTap,
  });

  final ProductModel product;
  final double? width;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.isRegistered<FavoritesController>()
        ? Get.find<FavoritesController>()
        : Get.put(FavoritesController(), permanent: true);

    return GestureDetector(
      onTap: onTap ??
          () => Navigator.pushNamed(
                context,
                '/bike_detail',
                arguments: product,
              ),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 16, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: _buildImage(),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: ProductStatusBadge(
                    status: product.status,
                    compact: true,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GetBuilder<FavoritesController>(
                    builder: (controller) {
                      final isFavorite = controller.isFavorite(product);
                      return GestureDetector(
                        onTap: onFavoriteTap ??
                            () => favoritesController.toggleFavorite(product),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite
                                ? Colors.red
                                : const Color(0xFF5E6E8C),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _buildTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0C0E1B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        _buildTags().map(_buildInfoTag).toList(growable: false),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _buildLocation(),
                          style: const TextStyle(
                            color: Color(0xFF262A36),
                            fontSize: 9,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _buildPrice(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF2E4475),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(product.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 8,
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
    );
  }

  Widget _buildImage() {
    final imageUrl = product.imageUrls
        .map((url) => url.trim())
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 85,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _buildImageFallback(),
      );
    }

    return _buildImageFallback();
  }

  Widget _buildImageFallback() {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      height: 85,
      width: double.infinity,
      // color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/pngwing.com (18) 3.png',
        height: 85,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _buildTitle() {
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

    if (parts.isEmpty) {
      return 'Untitled product';
    }

    return parts.join(' ');
  }

  String _buildPrice() {
    if (product.price == null) {
      return 'Price on request';
    }

    final price = product.price!;
    if (price == price.roundToDouble()) {
      return 'Rs.${price.toInt()}';
    }
    return 'Rs.${price.toStringAsFixed(0)}';
  }

  String _buildLocation() {
    final location = product.location?.trim() ?? '';
    return location.isNotEmpty ? location : 'Location not provided';
  }

  List<String> _buildTags() {
    final tags = <String>[];
    if (product.kilometerDriven != null) {
      tags.add('${product.kilometerDriven} km');
    }
    if (product.fuelType?.trim().isNotEmpty == true) {
      tags.add(product.fuelType!.trim());
    }
    if (product.subCategory?.trim().isNotEmpty == true) {
      tags.add(product.subCategory!.trim());
    }
    if (product.condition?.trim().isNotEmpty == true) {
      tags.add(product.condition!.trim());
    }

    if (tags.isEmpty) {
      tags.add(product.category);
    }

    return tags.take(3).toList(growable: false);
  }

  String _timeAgo(DateTime? value) {
    if (value == null) {
      return 'Just now';
    }

    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 5) {
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    final years = (difference.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }
}
