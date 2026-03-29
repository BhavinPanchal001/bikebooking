import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:bikebooking/features/auth/data/services/user_firestore_service.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/seller_review_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_review_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/block_sync_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class SellerProfileController extends GetxController {
  SellerProfileController({
    UserFirestoreService? userFirestoreService,
    ProductFirestoreService? productFirestoreService,
    SellerReviewFirestoreService? sellerReviewService,
    SellerActionFirestoreService? sellerActionService,
    LoginController? loginController,
  })  : _userFirestoreService = userFirestoreService ?? UserFirestoreService(),
        _productFirestoreService =
            productFirestoreService ?? ProductFirestoreService(),
        _sellerReviewService =
            sellerReviewService ?? SellerReviewFirestoreService(),
        _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  final UserFirestoreService _userFirestoreService;
  final ProductFirestoreService _productFirestoreService;
  final SellerReviewFirestoreService _sellerReviewService;
  final SellerActionFirestoreService _sellerActionService;
  final LoginController _loginController;

  String _sellerId = '';
  String get sellerId => _sellerId;

  String _fallbackSellerName = '';

  AppUserModel? _seller;
  AppUserModel? get seller => _seller;

  List<ProductModel> _listings = [];
  List<ProductModel> get listings => List.unmodifiable(_listings);

  List<SellerReviewModel> _reviews = [];
  List<SellerReviewModel> get reviews => List.unmodifiable(_reviews);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmittingReview = false;
  bool get isSubmittingReview => _isSubmittingReview;

  bool _isReportingSeller = false;
  bool get isReportingSeller => _isReportingSeller;

  bool _isUpdatingBlockStatus = false;
  bool get isUpdatingBlockStatus => _isUpdatingBlockStatus;

  bool _isSellerBlocked = false;
  bool get isSellerBlocked => _isSellerBlocked;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _actionErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  double get averageRating {
    if (_reviews.isEmpty) {
      return 0;
    }

    final total = _reviews.fold<double>(
      0,
      (totalRating, review) => totalRating + review.rating,
    );
    return total / _reviews.length;
  }

  int get reviewCount => _reviews.length;

  int get totalListings => _listings.length;

  bool get hasReviews => _reviews.isNotEmpty;

  bool get isOwnProfile {
    final currentUserId = _resolveCurrentUserId();
    return currentUserId.isNotEmpty && currentUserId == _sellerId;
  }

  bool get canWriteReview {
    final currentUserId = _resolveCurrentUserId();
    return _sellerId.isNotEmpty &&
        currentUserId.isNotEmpty &&
        currentUserId != _sellerId;
  }

  SellerReviewModel? get currentUserReview {
    final currentUserId = _resolveCurrentUserId();
    if (currentUserId.isEmpty) {
      return null;
    }

    try {
      return _reviews.firstWhere(
        (review) => review.reviewerId.trim() == currentUserId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadSellerProfile({
    required String sellerId,
    String fallbackSellerName = '',
    ProductModel? initialProduct,
    bool showLoader = true,
  }) async {
    final normalizedSellerId = sellerId.trim();
    if (normalizedSellerId.isEmpty) {
      _sellerId = '';
      _seller = null;
      _listings = [];
      _reviews = [];
      _isLoading = false;
      _errorMessage = 'Seller details are unavailable for this listing.';
      update();
      return;
    }

    _sellerId = normalizedSellerId;
    _fallbackSellerName = fallbackSellerName.trim();
    if (showLoader) {
      _isLoading = true;
    }
    _errorMessage = null;
    _actionErrorMessage = null;
    update();

    try {
      final currentUserId = _resolveCurrentUserId();
      if (currentUserId.isNotEmpty && currentUserId != normalizedSellerId) {
        final hasBlockingRelationship =
            await _sellerActionService.hasBlockingRelationship(
          firstUserId: currentUserId,
          secondUserId: normalizedSellerId,
        );
        if (hasBlockingRelationship) {
          _isSellerBlocked = await _sellerActionService.isSellerBlocked(
            userId: currentUserId,
            sellerId: normalizedSellerId,
          );
          _seller = _buildFallbackSeller(normalizedSellerId);
          _listings = const <ProductModel>[];
          _reviews = const <SellerReviewModel>[];
          _errorMessage = _isSellerBlocked
              ? 'You blocked this seller. Unblock them to view the profile again.'
              : 'This seller profile is unavailable because one of you has blocked the other.';
          return;
        }
      }

      final futures = await Future.wait<dynamic>([
        _loadSellerSafely(normalizedSellerId),
        _loadListingsSafely(
          normalizedSellerId,
          initialProduct: initialProduct,
        ),
        _loadReviewsSafely(normalizedSellerId),
      ]);

      final loadedSeller = futures[0] as AppUserModel?;
      final loadedListings = futures[1] as List<ProductModel>;
      final loadedReviews = futures[2] as List<SellerReviewModel>;

      _seller = loadedSeller ?? _buildFallbackSeller(normalizedSellerId);
      _listings = loadedListings;
      _reviews = loadedReviews;
      _errorMessage = null;

      await _loadBlockState();
    } on FirebaseException catch (error, stackTrace) {
      _errorMessage = error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Unable to load seller profile right now.';
      debugPrint('Error loading seller profile: $error\n$stackTrace');
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to load seller profile right now.';
      debugPrint('Error loading seller profile: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      update();
    }
  }

  AppUserModel _buildFallbackSeller(String sellerId) {
    return AppUserModel(
      id: sellerId,
      phoneNumber: '',
      fullName: _fallbackSellerName,
    );
  }

  Future<AppUserModel?> _loadSellerSafely(String sellerId) async {
    try {
      return await _userFirestoreService.getUserById(sellerId);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error loading seller user profile: $error\n$stackTrace');
      return null;
    }
  }

  Future<List<ProductModel>> _loadListingsSafely(
    String sellerId, {
    ProductModel? initialProduct,
  }) async {
    try {
      return await _productFirestoreService.getUserProducts(sellerId);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error loading seller listings: $error\n$stackTrace');

      if (initialProduct != null &&
          initialProduct.sellerId.trim() == sellerId.trim()) {
        return <ProductModel>[initialProduct];
      }

      return const <ProductModel>[];
    }
  }

  Future<List<SellerReviewModel>> _loadReviewsSafely(String sellerId) async {
    try {
      return await _sellerReviewService.getSellerReviews(sellerId);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error loading seller reviews: $error\n$stackTrace');
      return const <SellerReviewModel>[];
    }
  }

  Future<void> refreshProfile() async {
    if (_sellerId.isEmpty) {
      return;
    }
    await loadSellerProfile(
      sellerId: _sellerId,
      fallbackSellerName: _fallbackSellerName,
      showLoader: false,
    );
  }

  Future<bool> submitReview({
    required double rating,
    required String comment,
  }) async {
    final hasSession = await _loginController.ensureFirestoreSession();
    if (!hasSession) {
      _actionErrorMessage = _loginController.firestoreSessionErrorMessage ??
          'Unable to start a Firebase session for reviews right now.';
      update();
      return false;
    }

    final currentUserId = _resolveCurrentUserId();
    if (_sellerId.isEmpty || currentUserId.isEmpty) {
      _actionErrorMessage = 'Sign in to leave a review.';
      update();
      return false;
    }

    if (currentUserId == _sellerId) {
      _actionErrorMessage = 'You cannot review your own seller profile.';
      update();
      return false;
    }

    if (rating <= 0) {
      _actionErrorMessage = 'Please choose a star rating.';
      update();
      return false;
    }

    final trimmedComment = comment.trim();
    if (trimmedComment.isEmpty) {
      _actionErrorMessage = 'Add a short review before submitting.';
      update();
      return false;
    }

    final currentUser = _loginController.currentUserProfile;
    final reviewerName = currentUser?.displayName.trim().isNotEmpty == true
        ? currentUser!.displayName.trim()
        : 'Bikenest user';
    final reviewerPhotoUrl = currentUser?.photoUrl.trim() ?? '';

    _isSubmittingReview = true;
    _actionErrorMessage = null;
    update();

    try {
      final review = SellerReviewModel(
        id: currentUserId,
        sellerId: _sellerId,
        reviewerId: currentUserId,
        reviewerName: reviewerName,
        reviewerPhotoUrl: reviewerPhotoUrl,
        rating: rating,
        comment: trimmedComment,
      );

      await _sellerReviewService.upsertReview(review);
      await refreshProfile();
      return true;
    } catch (error, stackTrace) {
      _actionErrorMessage = 'Unable to save your review right now.';
      debugPrint('Error submitting seller review: $error\n$stackTrace');
      update();
      return false;
    } finally {
      _isSubmittingReview = false;
      update();
    }
  }

  Future<bool> reportSeller({
    required String reason,
    String details = '',
  }) async {
    final currentUserId = _resolveCurrentUserId();
    if (_sellerId.isEmpty || currentUserId.isEmpty) {
      _actionErrorMessage = 'Sign in to report this seller.';
      update();
      return false;
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      _actionErrorMessage = 'Choose a reason before reporting this seller.';
      update();
      return false;
    }

    _isReportingSeller = true;
    _actionErrorMessage = null;
    update();

    try {
      final currentUser = _loginController.currentUserProfile;
      await _sellerActionService.reportSeller(
        sellerId: _sellerId,
        sellerName: sellerDisplayName,
        reporterId: currentUserId,
        reporterName: currentUser?.displayName.trim().isNotEmpty == true
            ? currentUser!.displayName.trim()
            : 'Bikenest user',
        reason: trimmedReason,
        details: details,
      );
      return true;
    } catch (error, stackTrace) {
      _actionErrorMessage = 'Unable to submit your report right now.';
      debugPrint('Error reporting seller: $error\n$stackTrace');
      update();
      return false;
    } finally {
      _isReportingSeller = false;
      update();
    }
  }

  Future<bool> toggleSellerBlock() async {
    final currentUserId = _resolveCurrentUserId();
    if (_sellerId.isEmpty || currentUserId.isEmpty) {
      _actionErrorMessage = 'Sign in to manage blocked sellers.';
      update();
      return false;
    }

    if (currentUserId == _sellerId) {
      _actionErrorMessage = 'You cannot block your own seller profile.';
      update();
      return false;
    }

    _isUpdatingBlockStatus = true;
    _actionErrorMessage = null;
    update();

    try {
      if (_isSellerBlocked) {
        await _sellerActionService.unblockSeller(
          userId: currentUserId,
          sellerId: _sellerId,
        );
        _isSellerBlocked = false;
      } else {
        await _sellerActionService.blockSeller(
          userId: currentUserId,
          sellerId: _sellerId,
          sellerName: sellerDisplayName,
          sellerPhotoUrl: _seller?.photoUrl ?? '',
        );
        _isSellerBlocked = true;
      }
      BlockSyncHelper.refreshAfterBlockChange();
      return true;
    } catch (error, stackTrace) {
      _actionErrorMessage = _isSellerBlocked
          ? 'Unable to unblock this seller right now.'
          : 'Unable to block this seller right now.';
      debugPrint('Error updating seller block status: $error\n$stackTrace');
      update();
      return false;
    } finally {
      _isUpdatingBlockStatus = false;
      update();
    }
  }

  String get sellerDisplayName {
    final displayName = _seller?.displayName.trim() ?? '';
    if (displayName.isNotEmpty && displayName != 'User') {
      return displayName;
    }

    if (_fallbackSellerName.isNotEmpty) {
      return _fallbackSellerName;
    }

    return 'Seller';
  }

  String get sellerPhone {
    final seller = _seller;
    if (seller == null) {
      return 'Phone not available';
    }

    final phone = seller.primaryPhone.trim();
    if (phone.isNotEmpty && phone != 'Add your phone number') {
      return phone;
    }

    return 'Phone not available';
  }

  Future<void> _loadBlockState() async {
    final currentUserId = _resolveCurrentUserId();
    if (currentUserId.isEmpty || currentUserId == _sellerId) {
      _isSellerBlocked = false;
      return;
    }

    try {
      _isSellerBlocked = await _sellerActionService.isSellerBlocked(
        userId: currentUserId,
        sellerId: _sellerId,
      );
    } catch (error, stackTrace) {
      _isSellerBlocked = false;
      debugPrint('Error loading seller block state: $error\n$stackTrace');
    }
  }

  String _resolveCurrentUserId() {
    final profileUserId = _loginController.currentUserProfile?.id.trim() ?? '';
    if (profileUserId.isNotEmpty) {
      return profileUserId;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid.trim().isNotEmpty) {
      return firebaseUser.uid.trim();
    }

    return '';
  }
}
