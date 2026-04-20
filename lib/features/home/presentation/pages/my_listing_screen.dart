import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/core/widgets/product_cached_image.dart';
import 'package:bikebooking/features/home/data/models/boost_plan.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/boost_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/home_products_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/my_listing_controller.dart';
import 'package:bikebooking/features/home/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:bikebooking/features/home/presentation/widgets/product_status_badge.dart';
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
        final product = args['product'] as ProductModel?;
        if (product != null) {
          _showBoostBottomSheet(context, product);
        }
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        _navigateBack();
      },
      child: Scaffold(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Posts',
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
                child: _buildAdsTabContent(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      ),
    );
  }

  Future<bool> _handleBackNavigation() async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
    return false;
  }

  void _navigateBack() {
    _handleBackNavigation();
  }

  Widget _buildManagedListingCard(
    BuildContext context,
    MyListingController controller,
    ProductModel product,
  ) {
    final primaryImage = _resolveDisplayableImage(product.imageUrls);
    final productId = product.id;
    final isDeleting = controller.isDeleting(productId);
    final isUpdatingStatus = controller.isUpdatingStatus(productId);
    final isBusy = isDeleting || isUpdatingStatus;
    final canMarkSold = productId != null && product.isActive && !isBusy;
    final canBoost = product.isActive && productId != null && !isBusy;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openProductDetails(context, product),
            child: Padding(
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
                          ? ProductCachedImage(
                              imageUrl: primaryImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_) => _buildImageFallback(),
                              placeholderBuilder: (_) => _buildImageFallback(),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5E6E8C),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ProductStatusBadge(
                              status: product.status,
                              compact: true,
                            ),
                            const SizedBox(width: 4),
                            if (isUpdatingStatus)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else
                              PopupMenuButton<_ListingStatusMenuAction>(
                                tooltip: 'More actions',
                                onSelected: (action) => _handleStatusAction(
                                  context,
                                  controller,
                                  product,
                                  action,
                                ),
                                itemBuilder: (context) =>
                                    _buildStatusMenuItems(product),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: Color(0xFF5E6E8C),
                                  ),
                                ),
                              ),
                          ],
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: canMarkSold
                      ? CustomGradientButton(
                          height: 42,
                          text: 'Mark as Sold',
                          onPressed: () => _handleStatusAction(
                            context,
                            controller,
                            product,
                            _ListingStatusMenuAction.markSold,
                          ),
                        )
                      : OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF9AA6BC),
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.05),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            product.isSold ? 'Sold' : 'Mark as Sold',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: canBoost
                      ? product.isCurrentlyBoosted
                          ? OutlinedButton(
                              onPressed: () =>
                                  _showBoostDetailsSheet(context, product),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF3E0),
                                side: const BorderSide(
                                  color: Color(0xFFFF8C00),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt,
                                      size: 16, color: Color(0xFFFF8C00)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Boost Ad',
                                    style: TextStyle(
                                      color: Color(0xFFFF8C00),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : OutlinedButton(
                              onPressed: () =>
                                  _showBoostBottomSheet(context, product),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.black.withOpacity(0.05),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt,
                                      size: 16, color: Color(0xFF2E4475)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Boost Ad',
                                    style: TextStyle(
                                      color: Color(0xFF2E4475),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                      : OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF9AA6BC),
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.05),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Boost Ad',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsTabContent() {
    return GetBuilder<MyListingController>(
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
    );
  }

  void _openEditProduct(BuildContext context, ProductModel product) {
    if (!product.isActive) {
      Get.snackbar(
        'Editing unavailable',
        'Reactivate this listing before editing it.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final editController = Get.isRegistered<ListProductController>()
        ? Get.find<ListProductController>()
        : Get.put(ListProductController());

    editController.loadProductForEditing(product);
    Navigator.pushNamed(
      context,
      '/product_images',
      arguments: editController.category,
    );
  }

  List<PopupMenuEntry<_ListingStatusMenuAction>> _buildStatusMenuItems(
    ProductModel product,
  ) {
    if (product.isActive) {
      return const [
        PopupMenuItem<_ListingStatusMenuAction>(
          value: _ListingStatusMenuAction.edit,
          child: Text('Edit'),
        ),
        PopupMenuItem<_ListingStatusMenuAction>(
          value: _ListingStatusMenuAction.remove,
          child: Text('Remove'),
        ),
      ];
    }

    return const [
      PopupMenuItem<_ListingStatusMenuAction>(
        value: _ListingStatusMenuAction.remove,
        child: Text('Remove'),
      ),
      PopupMenuItem<_ListingStatusMenuAction>(
        value: _ListingStatusMenuAction.reactivate,
        child: Text('Reactivate'),
      ),
    ];
  }

  Future<void> _handleStatusAction(
    BuildContext context,
    MyListingController controller,
    ProductModel product,
    _ListingStatusMenuAction action,
  ) async {
    final productId = product.id;
    if (productId == null) {
      return;
    }

    if (action == _ListingStatusMenuAction.edit) {
      _openEditProduct(context, product);
      return;
    }

    if (action == _ListingStatusMenuAction.remove) {
      await _confirmDeleteProduct(context, controller, product);
      return;
    }

    final config = switch (action) {
      _ListingStatusMenuAction.markSold => (
          nextStatus: ProductStatus.sold,
          title: 'Mark as Sold',
          prompt:
              'Mark "${product.title.trim().isNotEmpty ? product.title.trim() : 'this listing'}" as sold?',
          successTitle: 'Marked as sold',
          successMessage: 'Your listing is now marked as sold.'
        ),
      _ListingStatusMenuAction.reactivate => (
          nextStatus: ProductStatus.active,
          title: 'Reactivate Listing',
          prompt:
              'Reactivate "${product.title.trim().isNotEmpty ? product.title.trim() : 'this listing'}" so buyers can interact with it again?',
          successTitle: 'Listing reactivated',
          successMessage: 'Your listing is active again.'
        ),
      _ListingStatusMenuAction.edit => throw UnimplementedError(),
      _ListingStatusMenuAction.remove => throw UnimplementedError(),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(config.title),
          content: Text(config.prompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                action == _ListingStatusMenuAction.reactivate
                    ? 'Reactivate'
                    : 'Confirm',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await controller.updateProductStatus(
      productId: productId,
      status: config.nextStatus,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      Get.snackbar(
        config.successTitle,
        config.successMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      return;
    }

    Get.snackbar(
      'Error',
      controller.actionErrorMessage ?? 'Unable to update this listing.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
    );
  }

  void _openProductDetails(BuildContext context, ProductModel product) {
    Navigator.pushNamed(
      context,
      '/bike_detail',
      arguments: <String, dynamic>{
        'product': product,
        'isOwnerView': true,
      },
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey.shade400,
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
      child: LayoutBuilder(
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
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
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
                          CustomGradientButton(
                            text: actionLabel,
                            onPressed: onAction,
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

  void _showBoostDetailsSheet(BuildContext context, ProductModel product) {
    final plan = BoostPlan.allPlans.firstWhere(
      (p) => p.id == product.boostPlanId,
      orElse: () => BoostPlan.basic,
    );

    final startedAt = product.boostStartedAt;
    final expiresAt = product.boostExpiresAt;
    final daysLeft =
        expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;
    final hoursLeft = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inHours % 24
        : 0;

    String remainingText;
    if (daysLeft > 0) {
      remainingText = '$daysLeft day${daysLeft > 1 ? 's' : ''} remaining';
    } else if (hoursLeft > 0) {
      remainingText = '$hoursLeft hour${hoursLeft > 1 ? 's' : ''} remaining';
    } else {
      remainingText = 'Expiring soon';
    }

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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
              const SizedBox(height: 24),
              // Status icon
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 40,
                  color: Color(0xFFFF8C00),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Boost Active',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8C00),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _buildTitle(product),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5E6E8C),
                ),
              ),
              const SizedBox(height: 24),
              // Plan details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF8C00).withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Plan',
                      value: plan.name,
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Started',
                      value: startedAt != null
                          ? _formatDetailDate(startedAt)
                          : 'N/A',
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.event_outlined,
                      label: 'Expires',
                      value: expiresAt != null
                          ? _formatDetailDate(expiresAt)
                          : 'N/A',
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.timer_outlined,
                      label: 'Remaining',
                      value: remainingText,
                      valueColor: daysLeft <= 1
                          ? Colors.red.shade400
                          : const Color(0xFF10B981),
                    ),
                    if (product.boostPaymentId != null) ...[
                      const SizedBox(height: 14),
                      _buildDetailRow(
                        icon: Icons.receipt_long_outlined,
                        label: 'Payment ID',
                        value: product.boostPaymentId!,
                        valueSize: 11,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Info text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Color(0xFF2E4475)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your listing is featured at the top of the home feed during the boost period.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E4475),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E4475),
                    side: const BorderSide(color: Color(0xFFCED4DE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    double valueSize = 13,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF2E3E5C),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDetailDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showBoostBottomSheet(BuildContext context, ProductModel product) {
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
                  child: Image.asset(
                    'assets/images/Frame 1171275371.png',
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.bolt,
                      size: 60,
                      color: Color(0xFF2E4475),
                    ),
                  ),
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
                  'Increase visibility and get more bookings by boosting',
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
                    Text('1. Priority placement in search results',
                        style:
                            TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('2. Featured ad badge on your listing',
                        style:
                            TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('3. Appear at the top of the home feed',
                        style:
                            TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('4. More views & faster selling',
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
                  _showBoostPlansSheet(context, product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBoostPlansSheet(BuildContext context, ProductModel product) {
    final boostController = Get.find<BoostController>();
    boostController.setTargetProduct(product);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setLocalState) {
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
                  // Product card with real data
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
                            child: _buildBoostProductImage(product),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _buildTitle(product),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E3E5C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _buildBoostTags(product)
                              .map(_buildSmallTag)
                              .toList(growable: false),
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
                                  _buildLocation(product),
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _buildPrice(product),
                              style: const TextStyle(
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
                  // Interactive plan selection — sourced from the admin's
                  // /fee_config master (falls back to bundled plans before
                  // the admin has seeded it).
                  GetBuilder<BoostController>(
                    builder: (ctrl) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: ctrl.availablePlans.map((plan) {
                          final isSelected = ctrl.selectedPlan.id == plan.id;
                          return GestureDetector(
                            onTap: () {
                              ctrl.selectPlan(plan);
                              setLocalState(() {});
                            },
                            child: _buildPlanOption(
                              plan.name,
                              plan.subtitle,
                              plan.displayPrice,
                              isSelected,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  GetBuilder<BoostController>(
                    builder: (ctrl) {
                      return CustomGradientButton(
                        text: ctrl.isProcessing
                            ? 'Processing...'
                            : 'Pay ${ctrl.selectedPlan.displayPrice}',
                        isLoading: ctrl.isProcessing,
                        onPressed: () {
                          // Set up callbacks before starting payment
                          ctrl.onBoostSuccess = () {
                            final selectedPlan = ctrl.selectedPlan;

                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;

                              _showPaymentSuccessSheet(
                                this.context,
                                selectedPlan,
                              );
                              _listingController.loadProducts();
                              // Also refresh home feed so boosted product moves to top
                              if (Get.isRegistered<HomeProductsController>()) {
                                Get.find<HomeProductsController>()
                                    .loadProducts(showLoader: false);
                              }
                            });
                          };
                          ctrl.onBoostError = (message) {
                            if (message.isNotEmpty) {
                              Get.snackbar(
                                'Boost Failed',
                                message,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red.shade600,
                                colorText: Colors.white,
                              );
                            }
                          };
                          // Pass user contact info for Razorpay prefill
                          final userProfile =
                              Get.isRegistered<LoginController>()
                                  ? Get.find<LoginController>()
                                      .currentUserProfile
                                  : null;
                          ctrl.startBoostPayment(
                            userPhone: userProfile?.phoneNumber,
                            userEmail: userProfile?.email,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBoostProductImage(ProductModel product) {
    final imageUrl = product.imageUrls.map((url) => url.trim()).firstWhere(
          (url) => url.startsWith('http://') || url.startsWith('https://'),
          orElse: () => '',
        );

    if (imageUrl.isNotEmpty) {
      return ProductCachedImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_) => Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey.shade400,
        ),
        placeholderBuilder: (_) => Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey.shade400,
        ),
      );
    }

    return Icon(
      Icons.image_outlined,
      size: 40,
      color: Colors.grey.shade400,
    );
  }

  List<String> _buildBoostTags(ProductModel product) {
    final tags = <String>[];
    if (product.kilometerDriven != null) {
      tags.add('${product.kilometerDriven} KM');
    }
    if (product.fuelType?.trim().isNotEmpty == true) {
      tags.add(product.fuelType!.trim());
    }
    if (product.year != null) {
      tags.add(product.year.toString());
    }
    if (product.condition?.trim().isNotEmpty == true) {
      tags.add(product.condition!.trim());
    }
    if (tags.isEmpty) {
      tags.add(product.category);
    }
    return tags.take(3).toList(growable: false);
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

  void _showPaymentSuccessSheet(BuildContext context, BoostPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
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
              Text(
                'Success! Your listing will stay at the top for the next ${plan.durationDays} days.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF5E6E8C), fontSize: 14),
              ),
              const SizedBox(height: 40),
              CustomGradientButton(
                text: 'Go to Home',
                onPressed: () {
                  // Reset boost state
                  if (Get.isRegistered<BoostController>()) {
                    Get.find<BoostController>().resetBoostState();
                  }
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

enum _ListingStatusMenuAction {
  edit,
  remove,
  markSold,
  reactivate,
}
