import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/app_snackbar.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/seller_review_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/seller_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late final String _controllerTag;
  late final SellerProfileController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'seller-profile-${DateTime.now().microsecondsSinceEpoch.toString()}';
    _controller = Get.put(
      SellerProfileController(),
      tag: _controllerTag,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final args = _resolveSellerArguments(routeArguments);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await _controller.loadSellerProfile(
        sellerId: args.sellerId,
        fallbackSellerName: args.fallbackSellerName,
        initialProduct: args.initialProduct,
      );
    });
    _initialized = true;
  }

  @override
  void dispose() {
    if (Get.isRegistered<SellerProfileController>(tag: _controllerTag)) {
      Get.delete<SellerProfileController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SellerProfileController>(
      tag: _controllerTag,
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(controller),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: controller.refreshProfile,
                    child: _buildBody(controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SellerProfileController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 26,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A5F82), AppColors.primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              controller.isOwnProfile
                  ? const SizedBox(width: 28, height: 28)
                  : PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 28,
                      ),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'report') {
                          _showReportSellerSheet(controller);
                          return;
                        }
                        if (value == 'block') {
                          _confirmBlockSeller(controller);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Text('Report seller'),
                        ),
                        PopupMenuItem<String>(
                          value: 'block',
                          child: Text(
                            controller.isSellerBlocked
                                ? 'Unblock seller'
                                : 'Block seller',
                          ),
                        ),
                      ],
                    ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Seller Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SellerProfileController controller) {
    if (controller.isLoading && controller.seller == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    if (controller.errorMessage != null && controller.seller == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.person_off_outlined,
            size: 62,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          const Text(
            'Seller unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF233A66),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await controller.refreshProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        _buildSellerCard(controller),
        const SizedBox(height: 20),
        if (controller.canWriteReview) _buildReviewActionCard(controller),
        if (controller.canWriteReview) const SizedBox(height: 20),
        _buildListingsSection(controller),
        const SizedBox(height: 24),
        _buildReviewsSection(controller),
      ],
    );
  }

  Widget _buildSellerCard(SellerProfileController controller) {
    final seller = controller.seller;
    final sellerName = controller.sellerDisplayName;
    final sellerPhotoUrl = seller?.photoUrl.trim() ?? '';
    final sellerLocation = seller?.location?.address.trim() ?? '';
    final initials = _initialsFromText(sellerName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sellerPhotoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFEAF0FB),
                      backgroundImage: NetworkImage(sellerPhotoUrl),
                      onBackgroundImageError: (_, __) {},
                    )
                  : CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFEAF0FB),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF233A66),
                          fontWeight: FontWeight.bold,
                        ),
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
                            sellerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (controller.isSellerBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Blocked',
                              style: TextStyle(
                                color: Color(0xFFC62828),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            _iconForRating(index, controller.averageRating),
                            color: Colors.orange,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.reviewCount == 0
                              ? 'No reviews yet'
                              : '${controller.averageRating.toStringAsFixed(1)} (${controller.reviewCount} ${controller.reviewCount == 1 ? 'review' : 'reviews'})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.sellerPhone,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    if (sellerLocation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sellerLocation,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatChip(
                label: 'Joined',
                value: _formatJoinedDate(seller?.createdAt),
              ),
              _buildStatChip(
                label: 'Total Listings',
                value: controller.totalListings.toString(),
              ),
              _buildStatChip(
                label: 'Rating',
                value: controller.reviewCount == 0
                    ? 'New'
                    : controller.averageRating.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewActionCard(SellerProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.currentUserReview == null
                  ? 'Share your experience with this seller.'
                  : 'You already reviewed this seller. You can update it anytime.',
              style: const TextStyle(
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              if (!controller.canWriteReview) {
                AppSnackbar.show(
                  title: 'Unable to Add Review',
                  message: 'Sign in with a valid account to leave a review.',
                  backgroundColor: const Color(0xFFC62828),
                );
                return;
              }

              _showReviewSheet(controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              controller.currentUserReview == null
                  ? 'Add Review'
                  : 'Edit Review',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsSection(SellerProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Seller Listings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Text(
              '${controller.totalListings}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (controller.listings.isEmpty)
          _buildSectionEmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'This seller has no active listings yet.',
          )
        else
          ...controller.listings.map(_buildListingCard),
      ],
    );
  }

  Widget _buildReviewsSection(SellerProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews & Ratings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FD),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  controller.reviewCount == 0
                      ? 'New'
                      : controller.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          _iconForRating(index, controller.averageRating),
                          color: Colors.orange,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.reviewCount == 0
                          ? 'No reviews yet'
                          : '${controller.reviewCount} ${controller.reviewCount == 1 ? 'review' : 'reviews'} from buyers',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!controller.hasReviews)
          _buildSectionEmptyState(
            icon: Icons.rate_review_outlined,
            message: 'Be the first person to leave feedback for this seller.',
          )
        else
          ...controller.reviews.map(_buildReviewCard),
      ],
    );
  }

  Widget _buildListingCard(ProductModel product) {
    final primaryImage = product.imageUrls
        .map((url) => url.trim())
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/bike_detail',
        arguments: product,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: primaryImage.isNotEmpty
                    ? Image.network(
                        primaryImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildListingImageFallback(),
                      )
                    : _buildListingImageFallback(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _buildProductTitle(product),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildProductPrice(product),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildProductStats(product),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _buildProductLocation(product),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
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

  Widget _buildReviewCard(SellerReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewerAvatar(review),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName.trim().isNotEmpty
                          ? review.reviewerName.trim()
                          : 'Bikenest user',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          _iconForRating(index, review.rating),
                          color: Colors.orange,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatRelativeDate(review.createdAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment.trim(),
              style: const TextStyle(
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewerAvatar(SellerReviewModel review) {
    final reviewerPhotoUrl = review.reviewerPhotoUrl.trim();
    final initials = _initialsFromText(review.reviewerName);

    if (reviewerPhotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFEAF0FB),
        backgroundImage: NetworkImage(reviewerPhotoUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFEAF0FB),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF233A66),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListingImageFallback() {
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_bike_outlined,
        color: Color(0xFF94A3B8),
        size: 30,
      ),
    );
  }

  Widget _buildSectionEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _SellerRouteArgs _resolveSellerArguments(Object? args) {
    if (args is ProductModel) {
      return _SellerRouteArgs(
        sellerId: args.sellerId.trim(),
        fallbackSellerName: args.sellerName.trim(),
        initialProduct: args,
      );
    }

    if (args is Map) {
      return _SellerRouteArgs(
        sellerId: (args['sellerId'] ?? '').toString().trim(),
        fallbackSellerName:
            (args['fallbackSellerName'] ?? args['sellerName'] ?? '')
                .toString()
                .trim(),
        initialProduct: args['product'] is ProductModel
            ? args['product'] as ProductModel
            : null,
      );
    }

    if (args is String) {
      return _SellerRouteArgs(sellerId: args.trim());
    }

    return const _SellerRouteArgs();
  }

  Future<void> _showReviewSheet(SellerProfileController controller) async {
    if (!controller.canWriteReview || controller.isOwnProfile) {
      AppSnackbar.show(
        title: 'Unable to Add Review',
        message: 'You can’t review your own seller profile.',
        backgroundColor: const Color(0xFFC62828),
      );
      return;
    }

    final existingReview = controller.currentUserReview;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ReviewSheet(
          controller: controller,
          existingReview: existingReview,
        );
      },
    );
  }

  void _showReportSellerSheet(SellerProfileController controller) {
    const reasons = <String>[
      'Spam or fake listings',
      'Misleading information',
      'Abusive behaviour',
      'Fraud concern',
      'Other',
    ];

    String selectedReason = reasons.first;
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Report Seller',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...reasons.map(
                      (reason) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            selectedReason = value;
                          });
                        },
                        title: Text(reason),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Add more details (optional)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() {
                                  isSubmitting = true;
                                });

                                final success = await controller.reportSeller(
                                  reason: selectedReason,
                                  details: detailsController.text,
                                );

                                if (!mounted || !context.mounted) {
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = false;
                                });

                                if (success) {
                                  Navigator.of(sheetContext).pop();
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    AppSnackbar.show(
                                      title: 'Report Submitted',
                                      message:
                                          'Thanks. Our team will review this seller report.',
                                      backgroundColor: const Color(0xFF2E7D32),
                                    );
                                  });
                                  return;
                                }

                                AppSnackbar.show(
                                  title: 'Unable to Report Seller',
                                  message: controller.actionErrorMessage ??
                                      'Please try again.',
                                  backgroundColor: const Color(0xFFC62828),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Report'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(detailsController.dispose);
  }

  Future<void> _confirmBlockSeller(SellerProfileController controller) async {
    final shouldBlock = !controller.isSellerBlocked;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(shouldBlock ? 'Block Seller?' : 'Unblock Seller?'),
            content: Text(
              shouldBlock
                  ? 'You will still be able to see this profile, but this seller will be marked as blocked in your account.'
                  : 'This seller will be removed from your blocked sellers list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      shouldBlock ? const Color(0xFFC62828) : AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(shouldBlock ? 'Block' : 'Unblock'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final success = await controller.toggleSellerBlock();
    if (!mounted) {
      return;
    }

    if (success) {
      AppSnackbar.show(
        title:
            controller.isSellerBlocked ? 'Seller Blocked' : 'Seller Unblocked',
        message: controller.isSellerBlocked
            ? 'This seller has been added to your blocked list.'
            : 'This seller has been removed from your blocked list.',
        backgroundColor: controller.isSellerBlocked
            ? const Color(0xFFC62828)
            : const Color(0xFF2E7D32),
      );
      return;
    }

    AppSnackbar.show(
      title: 'Action Failed',
      message: controller.actionErrorMessage ?? 'Please try again.',
      backgroundColor: const Color(0xFFC62828),
    );
  }

  IconData _iconForRating(int index, double rating) {
    final starIndex = index + 1;
    if (rating >= starIndex) {
      return Icons.star_rounded;
    }
    if (rating > index && rating < starIndex) {
      return Icons.star_half_rounded;
    }
    return Icons.star_border_rounded;
  }

  String _initialsFromText(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'S';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _formatJoinedDate(DateTime? value) {
    if (value == null) {
      return 'Recently';
    }

    const monthLabels = <String>[
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
    return '${monthLabels[value.month - 1]} ${value.year}';
  }

  String _buildProductTitle(ProductModel product) {
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

  String _buildProductPrice(ProductModel product) {
    if (product.price == null) {
      return 'Price on request';
    }

    final price = product.price!;
    if (price == price.roundToDouble()) {
      return 'Rs.${price.toInt()}';
    }
    return 'Rs.${price.toStringAsFixed(0)}';
  }

  String _buildProductStats(ProductModel product) {
    final stats = <String>[];
    if (product.year != null) {
      stats.add(product.year.toString());
    }
    if (product.kilometerDriven != null) {
      stats.add('${product.kilometerDriven} km');
    }
    if (product.fuelType?.trim().isNotEmpty == true) {
      stats.add(product.fuelType!.trim());
    }
    if (product.condition?.trim().isNotEmpty == true) {
      stats.add(product.condition!.trim());
    }

    if (stats.isEmpty) {
      return product.category;
    }
    return stats.join(' • ');
  }

  String _buildProductLocation(ProductModel product) {
    final location = product.location?.trim() ?? '';
    return location.isNotEmpty ? location : 'Location not provided';
  }

  String _formatRelativeDate(DateTime? value) {
    if (value == null) {
      return 'Recently';
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
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    final years = (difference.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({
    required this.controller,
    required this.existingReview,
  });

  final SellerProfileController controller;
  final SellerReviewModel? existingReview;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late final TextEditingController _commentController;
  late double _selectedRating;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.existingReview?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.controller.submitReview(
      rating: _selectedRating,
      comment: _commentController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.show(
          title: 'Review Saved',
          message: 'Your feedback has been updated.',
          backgroundColor: const Color(0xFF2E7D32),
        );
      });
      return;
    }

    AppSnackbar.show(
      title: 'Unable to Save Review',
      message: widget.controller.actionErrorMessage ?? 'Please try again.',
      backgroundColor: const Color(0xFFC62828),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.existingReview == null ? 'Write Review' : 'Edit Review',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedRating = starNumber.toDouble();
                    });
                  },
                  icon: Icon(
                    _selectedRating >= starNumber
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Tell others about your experience with this seller',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.existingReview == null
                            ? 'Submit Review'
                            : 'Update Review',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerRouteArgs {
  const _SellerRouteArgs({
    this.sellerId = '',
    this.fallbackSellerName = '',
    this.initialProduct,
  });

  final String sellerId;
  final String fallbackSellerName;
  final ProductModel? initialProduct;
}
