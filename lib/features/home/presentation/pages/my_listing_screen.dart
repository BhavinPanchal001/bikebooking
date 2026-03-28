import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/my_listing_controller.dart';
import 'package:bikebooking/features/home/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyListingScreen extends StatefulWidget {
  const MyListingScreen({super.key});

  @override
  State<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends State<MyListingScreen>
    with SingleTickerProviderStateMixin {
  late final MyListingController _listingController;
  late final AnimationController _shimmerController;
  late final bool _ownsListingController;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<MyListingController>()) {
      _listingController = Get.find<MyListingController>();
      _ownsListingController = false;
    } else {
      _listingController = Get.put(MyListingController());
      _ownsListingController = true;
    }

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listingController.loadProducts();

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['showBoost'] == true) {
        _showBoostBottomSheet(context);
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    if (_ownsListingController && Get.isRegistered<MyListingController>()) {
      Get.delete<MyListingController>();
    }
    super.dispose();
  }

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
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'My Listing',
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
              child: GetBuilder<MyListingController>(
                builder: (controller) {
                  if (controller.isLoading) {
                    return _buildShimmerList();
                  }

                  if (controller.errorMessage != null) {
                    return _buildStateView(
                      icon: Icons.cloud_off_outlined,
                      title: 'Unable to load posts',
                      message: controller.errorMessage!,
                      actionLabel: 'Try again',
                      onAction: controller.loadProducts,
                    );
                  }

                  if (controller.products.isEmpty) {
                    return _buildStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No posts yet',
                      message:
                          'Your products will appear here once you publish your first listing.',
                      actionLabel: 'Post a product',
                      onAction: () => Navigator.pushNamed(
                        context,
                        '/list_product',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF233A66),
                    onRefresh: controller.refreshProducts,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.products.length,
                      itemBuilder: (context, index) {
                        final product = controller.products[index];
                        return _buildManagedListingCard(
                          context,
                          controller,
                          product,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildManagedListingCard(
    BuildContext context,
    MyListingController controller,
    ProductModel product,
  ) {
    final primaryImage = _resolveDisplayableImage(product.imageUrls);
    final productId = product.id;

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
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 110,
                    height: 90,
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
                      Text(
                        _buildStats(product),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF37474F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Color(0xFF37474F)),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        productId == null || controller.isDeleting(productId)
                            ? null
                            : () => _confirmDeleteProduct(
                                  context,
                                  controller,
                                  product,
                                ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(0.05)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: controller.isDeleting(productId)
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
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
                    text: 'Edit',
                    onPressed: () => _openEditProduct(context, product),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProduct(BuildContext context, ProductModel product) {
    final editController = Get.isRegistered<ListProductController>()
        ? Get.find<ListProductController>()
        : Get.put(ListProductController());

    editController.loadProductForEditing(product);

    final routeName = switch (product.category) {
      'Spare Parts' => '/spare_parts_detail_form',
      'Accessories' => '/accessories_detail_form',
      _ => '/bike_detail_form',
    };

    Navigator.pushNamed(context, routeName);
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Image.asset(
          'assets/images/bike.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.directions_bike, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return RefreshIndicator(
      color: const Color(0xFF233A66),
      onRefresh: _listingController.refreshProducts,
      child: ListView(
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
                CustomGradientButton(
                  text: actionLabel,
                  onPressed: onAction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(
                    width: 110,
                    height: 90,
                    radius: 12,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(
                          width: double.infinity,
                          height: 14,
                          radius: 8,
                        ),
                        const SizedBox(height: 8),
                        _buildShimmerBox(
                          width: 110,
                          height: 20,
                          radius: 8,
                        ),
                        const SizedBox(height: 8),
                        _buildShimmerBox(
                          width: 140,
                          height: 10,
                          radius: 8,
                        ),
                        const SizedBox(height: 8),
                        _buildShimmerBox(
                          width: 120,
                          height: 10,
                          radius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildShimmerBox(
                      width: double.infinity,
                      height: 42,
                      radius: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShimmerBox(
                      width: double.infinity,
                      height: 42,
                      radius: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - shimmerValue, -0.3),
              end: Alignment(1.0 + shimmerValue, 0.3),
              colors: const [
                Color(0xFFE8EEF6),
                Color(0xFFF7FAFE),
                Color(0xFFE8EEF6),
              ],
              stops: const [0.1, 0.3, 0.4],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    MyListingController controller,
    ProductModel product,
  ) async {
    final productId = product.id;
    if (productId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Post'),
          content: Text(
            'Do you want to remove "${product.title.trim().isNotEmpty ? product.title.trim() : 'this post'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await controller.deleteProduct(productId);
    if (!mounted) {
      return;
    }

    if (success) {
      Get.snackbar(
        'Removed',
        'Your post has been removed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Error',
      controller.actionErrorMessage ?? 'Unable to remove this post right now.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
    );
  }

  String? _resolveDisplayableImage(List<String> imageUrls) {
    for (final imageUrl in imageUrls) {
      final trimmedUrl = imageUrl.trim();
      if (trimmedUrl.startsWith('http://') ||
          trimmedUrl.startsWith('https://')) {
        return trimmedUrl;
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
    } else {
      parts.add(product.category);
    }
    return parts.join(' ');
  }

  String _buildPrice(ProductModel product) {
    final price = product.price;
    if (price == null) {
      return 'Price not set';
    }
    if (price == price.roundToDouble()) {
      return 'Rs.${price.toInt()}';
    }
    return 'Rs.${price.toStringAsFixed(2)}';
  }

  String _buildStats(ProductModel product) {
    final stats = <String>[];

    if (product.year != null) {
      stats.add(product.year.toString());
    }
    if (product.kilometerDriven != null) {
      stats.add('${product.kilometerDriven} km');
    } else if ((product.condition ?? '').trim().isNotEmpty) {
      stats.add(product.condition!.trim());
    }
    if ((product.fuelType ?? '').trim().isNotEmpty) {
      stats.add(product.fuelType!.trim());
    } else if ((product.subCategory ?? '').trim().isNotEmpty) {
      stats.add(product.subCategory!.trim());
    }

    if (stats.isEmpty) {
      return product.category;
    }

    return stats.join(' • ');
  }

  String _buildLocation(ProductModel product) {
    final location = product.location?.trim() ?? '';
    if (location.isNotEmpty) {
      return location;
    }
    return 'Location not set';
  }

  void _showBoostBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 140,
                width: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset('assets/images/Frame 1171275371.png'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Boost Your Ad',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A66),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Increase visibility and get more booking by boosting',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E6E8C)),
                ),
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'After boost you can',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. + 1x extra listing',
                        style:
                            TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('2. Free featured ads',
                        style:
                            TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('3. Priority Visibility',
                        style:
                            TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('4. Priority Visibility',
                        style:
                            TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomGradientButton(
                text: 'Choose Boost Plan',
                onPressed: () {
                  Navigator.pop(context);
                  _showBoostPlansSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBoostPlansSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Boost Your Ad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A66),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        color: const Color(0xFFF9FBFF),
                        child: Center(
                          child: Image.asset(
                            'assets/images/bike.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '2021 Royal Enfield Hunter 350',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3E5C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSmallTag('15,255 KM'),
                        const SizedBox(width: 8),
                        _buildSmallTag('Petrol'),
                        const SizedBox(width: 8),
                        _buildSmallTag('2021'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              'Madhya Pradesh 458468',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          '₹1.85 Lakh',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E4475),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildPlanOption(
                  'Basic Boost', '3 Days Boost', 'Rs.99.00', false),
              _buildPlanOption(
                  'Popular Boost', '7 Days Boost', 'Rs.199.00', true),
              _buildPlanOption(
                  'Premium Boost', '15 Days Boost', 'Rs.399.00', false),
              const SizedBox(height: 24),
              CustomGradientButton(
                text: 'Choose Boost Plan',
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentSuccessSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
      ),
    );
  }

  Widget _buildPlanOption(
    String title,
    String subtitle,
    String price,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4A6495)
              : Colors.black.withOpacity(0.05),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF4A6495) : Colors.grey.shade400,
              ),
            ),
            child: isSelected
                ? const Center(
                    child:
                        Icon(Icons.circle, size: 14, color: Color(0xFF4A6495)),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4475),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    height: 90,
                    width: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Color(0xFF4CAF50),
                    child: Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Payment Successful',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Ad is Boosted!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Success! Your listing will stay at the top for the next 7 days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF5E6E8C), fontSize: 14),
              ),
              const SizedBox(height: 40),
              CustomGradientButton(
                text: 'Go to Home',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
