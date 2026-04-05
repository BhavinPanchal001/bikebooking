import 'package:bikebooking/core/constants/product_categories.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:bikebooking/features/auth/data/services/user_firestore_service.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/chat/data/models/chat_model.dart';
import 'package:bikebooking/features/chat/data/services/chat_firestore_service.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/seller_review_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_review_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/home_products_controller.dart';
import 'package:bikebooking/features/home/presentation/widgets/product_status_badge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BikeDetailScreen extends StatefulWidget {
  const BikeDetailScreen({super.key});

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  late final FavoritesController _favoritesController;
  ProductModel? _product;
  bool _isOwnerView = false;
  List<String> _imageUrls = const [];
  int _selectedIndex = 0;
  bool _initialized = false;

  // Seller info
  AppUserModel? _seller;
  double _sellerAverageRating = 0;
  int _sellerReviewCount = 0;
  int _sellerTotalListings = 0;
  bool _loadingSeller = false;

  @override
  void initState() {
    super.initState();
    _favoritesController = Get.isRegistered<FavoritesController>()
        ? Get.find<FavoritesController>()
        : Get.put(FavoritesController(), permanent: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductModel) {
      _bindProduct(args);
    } else if (args is Map) {
      final routeProduct = args['product'] is ProductModel
          ? args['product'] as ProductModel
          : null;
      if (routeProduct != null) {
        _bindProduct(
          routeProduct,
          isOwnerView:
              args['isOwnerView'] == true || args['isOwnProduct'] == true,
        );
      }
    }
    _initialized = true;
  }

  void _bindProduct(
    ProductModel product, {
    bool isOwnerView = false,
  }) {
    _product = product;
    _isOwnerView = isOwnerView;
    _imageUrls = product.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !Get.isRegistered<HomeProductsController>()) {
        return;
      }

      Get.find<HomeProductsController>().recordProductView(product);
    });

    _loadSellerInfo(product.sellerId);
  }

  Future<void> _loadSellerInfo(String sellerId) async {
    final normalizedId = sellerId.trim();
    if (normalizedId.isEmpty) return;

    if (mounted) {
      setState(() => _loadingSeller = true);
    }

    try {
      final userRepo = UserFirestoreService();
      final productRepo = ProductFirestoreService();
      final reviewRepo = SellerReviewFirestoreService();

      final futures = await Future.wait([
        userRepo.getUserById(normalizedId),
        productRepo.getUserProducts(
          normalizedId,
          includeInactive: _isOwnerView,
        ),
        reviewRepo.getSellerReviews(normalizedId),
      ]);

      if (!mounted) return;

      final seller = futures[0] as AppUserModel?;
      final listings = futures[1] as List<ProductModel>;
      final reviews = futures[2] as List<SellerReviewModel>;

      double avgRating = 0;
      if (reviews.isNotEmpty) {
        final total = reviews.fold<double>(0, (sum, item) => sum + item.rating);
        avgRating = total / reviews.length;
      }

      setState(() {
        _seller = seller;
        _sellerTotalListings = listings.length;
        _sellerReviewCount = reviews.length;
        _sellerAverageRating = avgRating;
        _loadingSeller = false;
      });
    } catch (e) {
      debugPrint('Error loading seller info: $e');
      if (mounted) {
        setState(() => _loadingSeller = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (product == null) {
      return _buildUnavailableProductScaffold(
        title: 'Product details are unavailable',
        message:
            'Open this screen from a product card to view the real listing details.',
      );
    }

    if (!product.isActive && !_isOwnProduct(product)) {
      return _buildUnavailableProductScaffold(
        title: 'This listing is no longer available',
        message:
            'The seller has already marked this product as sold, so it is only visible in their posts now.',
      );
    }

    final isBikeLike =
        ProductCategoryCatalog.isVehicleCategory(product.category);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.white,
                    child: Center(
                      child: _buildMainImage(),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2E3E5C),
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFAFAFA).withOpacity(0.85),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _buildFavoriteAction(product),
                        const SizedBox(width: 12),
                        _buildCircleAction(Icons.share_outlined),
                      ],
                    ),
                  ),
                ],
              ),
              if (_imageUrls.length > 1) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _imageUrls.length,
                          (index) => _buildThumbnail(
                            _imageUrls[index],
                            _selectedIndex == index,
                            () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_imageUrls.length, (index) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedIndex == index
                              ? const Color(0xFF2E3E5C)
                              : Colors.grey.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buildTitle(product),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _buildPrice(product),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0C0E1B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProductStatusBadge(status: product.status),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _buildLocation(product),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Item specifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3E5C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSpecCard(product, isBikeLike),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3E5C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDescription(product),
                    const SizedBox(height: 24),
                    const Text(
                      'Seller',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3E5C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSellerCard(product),
                    const SizedBox(height: 16),
                    if (!_isOwnProduct(product))
                      _buildBuyerActionSection(product),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    if (_imageUrls.isEmpty) {
      return Image.asset(
        'assets/images/bike.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.directions_bike,
          size: 100,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      _imageUrls[_selectedIndex],
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.image_outlined,
        size: 100,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildUnavailableProductScaffold({
    required String title,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: Color(0xFF5E6E8C),
                ),
                const SizedBox(height: 16),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF233A66),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Go back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF2E3E5C)),
    );
  }

  Widget _buildFavoriteAction(ProductModel product) {
    return GetBuilder<FavoritesController>(
      builder: (controller) {
        final isFavorite = controller.isFavorite(product);
        return GestureDetector(
          onTap: () => _favoritesController.toggleFavorite(product),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: isFavorite ? Colors.red : const Color(0xFF2E3E5C),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(
    String imageUrl,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E3E5C) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E3E5C).withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_outlined,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecCard(ProductModel product, bool isBikeLike) {
    final resolvedVehicleSubCategory =
        ProductCategoryCatalog.resolveVehicleSubCategory(
      category: product.category,
      subCategory: product.subCategory,
      fuelType: product.fuelType,
    );
    final displayCategory = isBikeLike
        ? ProductCategoryCatalog.baseCategoryFor(product.category)
        : product.category;
    final rows = <MapEntry<String, String>>[
      MapEntry('Category', displayCategory),
      MapEntry('Brand', product.brand.isNotEmpty ? product.brand : '—'),
      MapEntry('Year', product.year?.toString() ?? '—'),
    ];

    if (isBikeLike) {
      rows.add(MapEntry('Sub Category', resolvedVehicleSubCategory ?? '—'));
      rows.add(MapEntry('Fuel Type', product.fuelType ?? '—'));
      rows.add(
        MapEntry(
          'Kilometers',
          product.kilometerDriven != null ? '${product.kilometerDriven}' : '—',
        ),
      );
      rows.add(
        MapEntry(
          'Owners',
          product.numberOfOwners != null ? '${product.numberOfOwners}' : '—',
        ),
      );
    } else {
      rows.add(MapEntry('Sub Category', product.subCategory ?? '—'));
      rows.add(MapEntry('Condition', product.condition ?? '—'));
      rows.add(MapEntry('Seller Type', product.sellerType ?? '—'));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Column(
            children: [
              _buildSpecRow(row.key, row.value),
              if (index != rows.length - 1)
                const Divider(height: 24, thickness: 0.5),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDescription(ProductModel product) {
    final description = product.description.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        description.isNotEmpty ? description : 'No description provided.',
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF5E6E8C),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSellerCard(ProductModel product) {
    if (_loadingSeller && _seller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = _seller?.displayName ?? product.sellerName.trim();
    final sellerName = displayName.isNotEmpty ? displayName : 'Seller';
    final joinedYear = _seller?.createdAt?.year.toString() ?? '—';
    final photoUrl = _seller?.photoUrl ?? '';

    return GestureDetector(
      onTap: () => _openSellerProfile(
        product,
        fallbackSellerName: sellerName,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background as requested
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo
            photoUrl.isNotEmpty
                ? Container(
                    width: 60, // Increased size for better alignment
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 30, // Increased size for better alignment
                    backgroundColor: const Color(0xFFEAF0FB),
                    child: Text(
                      sellerName.isNotEmpty
                          ? sellerName.substring(0, 1).toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF233A66),
                      ),
                    ),
                  ),
            const SizedBox(width: 14),
            // Seller Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sellerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3E5C),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < _sellerAverageRating.floor()
                              ? Icons.star
                              : (index < _sellerAverageRating
                                  ? Icons.star_half
                                  : Icons.star_border),
                          color: Colors.orange,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($_sellerReviewCount Reviews)',
                        style: const TextStyle(
                          color: Color(0xFF5E6E8C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Joined: $joinedYear',
                    style: const TextStyle(
                      color: Color(0xFF5E6E8C),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Listings: $_sellerTotalListings',
                    style: const TextStyle(
                      color: Color(0xFF5E6E8C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF2E3E5C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
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
    if (parts.isEmpty) {
      return 'Untitled product';
    }
    return parts.join(' ');
  }

  Widget _buildBuyerActionSection(ProductModel product) {
    if (product.allowsBuyerActions) {
      return CustomGradientButton(
        text: 'Chat',
        onPressed: () => _startChat(product),
        height: 48,
        icon: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
          size: 20,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFACCA8)),
          ),
          child: Text(
            'This listing is marked ${product.statusLabel.toLowerCase()}, so chat is disabled.',
            style: const TextStyle(
              color: Color(0xFF9A4D15),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text('Chat unavailable'),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: const Color(0xFFE5EAF3),
              disabledForegroundColor: const Color(0xFF7A889F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openSellerProfile(
    ProductModel product, {
    required String fallbackSellerName,
  }) {
    final sellerId = product.sellerId.trim();
    if (sellerId.isEmpty) {
      return;
    }

    Navigator.pushNamed(
      context,
      '/seller_profile',
      arguments: <String, dynamic>{
        'sellerId': sellerId,
        'fallbackSellerName': fallbackSellerName,
        'product': product,
      },
    );
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
    if (location.isNotEmpty) {
      return location;
    }
    return 'Location not provided';
  }

  bool _isOwnProduct(ProductModel product) {
    if (_isOwnerView) {
      return true;
    }

    final sellerId = product.sellerId.trim();
    if (sellerId.isEmpty) {
      return false;
    }

    final candidateUserIds = <String>{};

    if (Get.isRegistered<LoginController>()) {
      final loginController = Get.find<LoginController>();
      final profileUserId = loginController.currentUserProfile?.id.trim() ?? '';
      final resolvedCurrentUserId =
          loginController.resolvedCurrentUserId.trim();
      final chatUserId = loginController.chatUserId.trim();

      if (profileUserId.isNotEmpty) {
        candidateUserIds.add(profileUserId);
      }
      if (resolvedCurrentUserId.isNotEmpty) {
        candidateUserIds.add(resolvedCurrentUserId);
      }
      if (chatUserId.isNotEmpty) {
        candidateUserIds.add(chatUserId);
      }
    }

    if (Firebase.apps.isNotEmpty) {
      final firebaseUserId =
          FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
      if (firebaseUserId.isNotEmpty) {
        candidateUserIds.add(firebaseUserId);
      }
    }

    return candidateUserIds.contains(sellerId);
  }

  Future<void> _startChat(ProductModel product) async {
    if (!product.allowsBuyerActions) {
      Get.snackbar(
        'Chat unavailable',
        'This listing is marked ${product.statusLabel.toLowerCase()}, so chat is disabled.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final loginController = Get.find<LoginController>();
    final chatUserId = loginController.chatUserId;
    final currentUser = loginController.currentUserProfile;
    if (currentUser == null || chatUserId.isEmpty) {
      Get.snackbar('Error', 'You must be logged in to chat.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final hasSession = await loginController.ensureFirestoreSession();
    if (!hasSession) {
      Get.snackbar(
        'Error',
        loginController.firestoreSessionErrorMessage ??
            'Unable to connect to chat right now. Please sign in again and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final currentChatUser = currentUser.id == chatUserId
        ? currentUser
        : currentUser.copyWith(id: chatUserId);

    // Don't chat with yourself.
    if (_isOwnProduct(product) || product.sellerId == currentChatUser.id) {
      return;
    }

    // Show a loading indicator.
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF233A66))),
      barrierDismissible: false,
    );

    try {
      // Fetch the seller's user profile.
      final userService = UserFirestoreService();
      final sellerUser = await userService.getUserById(product.sellerId);
      if (sellerUser == null) {
        Get.back(); // Close loading.
        Get.snackbar('Error', 'Seller profile not found.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Create or find the chat.
      final chatService = ChatFirestoreService();
      final chatId = await chatService.getOrCreateChat(
        currentUser: currentChatUser,
        otherUser: sellerUser,
        product: product,
      );

      Get.back(); // Close loading.

      final initialChat = ChatModel(
        id: chatId,
        participants: [currentChatUser.id, sellerUser.id],
        participantDetails: {
          currentChatUser.id: ChatParticipant(
            name: currentChatUser.displayName,
            photoUrl: currentChatUser.photoUrl,
            phoneNumber: currentChatUser.phoneNumber,
          ),
          sellerUser.id: ChatParticipant(
            name: sellerUser.displayName,
            photoUrl: sellerUser.photoUrl,
            phoneNumber: sellerUser.phoneNumber,
          ),
        },
        productSnapshot: ProductSnapshot(
          productId: product.id ?? '',
          title: product.title,
          price: product.price,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        ),
      );

      if (!mounted) return;
      Navigator.pushNamed(context, '/chat_detail', arguments: {
        'chatId': chatId,
        'chat': initialChat,
      });
    } catch (error) {
      Get.back(); // Close loading.
      final message = error is UserBlockException
          ? error.message
          : 'Unable to start chat. Please try again.';
      Get.snackbar(
        error is UserBlockException ? 'Chat unavailable' : 'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
