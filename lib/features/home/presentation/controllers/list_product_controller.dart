import 'dart:typed_data';

import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_storage_service.dart';

class PickedProductImage {
  const PickedProductImage({
    required this.file,
    required this.bytes,
  });

  final XFile file;
  final Uint8List bytes;
}

class ListProductController extends GetxController {
  ListProductController({
    ProductFirestoreService? firestoreService,
    ProductStorageService? storageService,
    ImagePicker? imagePicker,
  })  : _firestoreService = firestoreService ?? ProductFirestoreService(),
        _storageService = storageService ?? ProductStorageService(),
        _imagePicker = imagePicker ?? ImagePicker();

  final ProductFirestoreService _firestoreService;
  final ProductStorageService _storageService;
  final ImagePicker _imagePicker;
  static const int _maxProductImages = 6;

  // ── Step 1: Category ──
  String _category = '';
  String get category => _category;

  void setCategory(String value) {
    _category = value;
    update();
  }

  // ── Step 2: Images (URLs — placeholder for now) ──
  List<String> _imageUrls = [];
  List<String> get imageUrls => _imageUrls;
  final List<PickedProductImage> _pickedImages = [];
  List<PickedProductImage> get pickedImages => List.unmodifiable(_pickedImages);
  int _selectedImageIndex = 0;
  int get selectedImageIndex => _selectedImageIndex;
  bool get hasPickedImages => _pickedImages.isNotEmpty;
  PickedProductImage? get selectedPreviewImage =>
      _pickedImages.isEmpty ? null : _pickedImages[_selectedImageIndex];

  void setImageUrls(List<String> urls) {
    _imageUrls = urls;
    update();
  }

  Future<void> pickProductImages() async {
    try {
      final remainingSlots = _maxProductImages - _pickedImages.length;
      if (remainingSlots <= 0) {
        Get.snackbar(
          'Limit reached',
          'You can upload up to $_maxProductImages images.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      if (pickedFiles.isEmpty) {
        return;
      }

      final filesToAdd = pickedFiles.take(remainingSlots).toList();
      final newImages = <PickedProductImage>[];
      for (final file in filesToAdd) {
        final bytes = await file.readAsBytes();
        newImages.add(PickedProductImage(file: file, bytes: bytes));
      }

      _pickedImages.addAll(newImages);
      if (_pickedImages.length == newImages.length) {
        _selectedImageIndex = 0;
      }
      update();
    } catch (error) {
      Get.snackbar(
        'Image upload failed',
        'Unable to pick images right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('Error picking product images: $error');
    }
  }

  void selectProductImage(int index) {
    if (index < 0 || index >= _pickedImages.length) {
      return;
    }
    _selectedImageIndex = index;
    update();
  }

  // ── Step 3: Bike / Scooter Detail Fields ──
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController kilometerController = TextEditingController();

  String _brand = '';
  String get brand => _brand;

  void setBrand(String value) {
    _brand = value;
    update();
  }

  int? _year;
  int? get year => _year;

  void setYear(int value) {
    _year = value;
    update();
  }

  String? _fuelType;
  String? get fuelType => _fuelType;

  void setFuelType(String value) {
    _fuelType = value;
    update();
  }

  int? _numberOfOwners;
  int? get numberOfOwners => _numberOfOwners;

  void setNumberOfOwners(int value) {
    _numberOfOwners = value;
    update();
  }

  // ── Step 3 (alt): Accessories / Spare Parts specific ──
  String? _subCategory;
  String? get subCategory => _subCategory;

  void setSubCategory(String value) {
    _subCategory = value;
    update();
  }

  String? _condition;
  String? get condition => _condition;

  void setCondition(String value) {
    _condition = value;
    update();
  }

  String? _sellerType;
  String? get sellerType => _sellerType;

  void setSellerType(String value) {
    _sellerType = value;
    update();
  }

  // ── Step 4: Price & Location ──
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // ── Loading state ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isFetchingCurrentLocation = false;
  bool get isFetchingCurrentLocation => _isFetchingCurrentLocation;
  String? _submissionErrorMessage;
  String? get submissionErrorMessage => _submissionErrorMessage;
  String? _submissionSuccessMessage;
  String? get submissionSuccessMessage => _submissionSuccessMessage;
  String? _editingProductId;
  String? get editingProductId => _editingProductId;
  bool get isEditing =>
      _editingProductId != null && _editingProductId!.isNotEmpty;

  // ── Submit Product ──
  Future<bool> submitProduct() async {
    _submissionErrorMessage = null;
    _submissionSuccessMessage = null;

    final validationError = _validateProduct();
    if (validationError != null) {
      _submissionErrorMessage = validationError;
      update();
      return false;
    }

    _isLoading = true;
    update();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final loginController = Get.isRegistered<LoginController>()
          ? Get.find<LoginController>()
          : null;
      final sellerId =
          firebaseUser?.uid ?? loginController?.currentUserProfile?.id ?? '';
      if (sellerId.isEmpty) {
        throw StateError(
          'Unable to find a Firebase user for this listing. Please sign in again and retry.',
        );
      }

      final sellerName = _resolveSellerName(
        loginController: loginController,
        firebaseUser: firebaseUser,
      );
      final uploadedImageUrls = await _resolveProductImageUrls(sellerId);

      final product = ProductModel(
        id: _editingProductId,
        category: _category,
        title: titleController.text.trim(),
        brand: _brand,
        year: _year,
        description: descriptionController.text.trim(),
        price: double.tryParse(priceController.text.trim()),
        location: locationController.text.trim(),
        imageUrls: uploadedImageUrls,
        sellerId: sellerId,
        sellerName: sellerName,
        status: 'active',
        // Bike / Scooter fields
        fuelType: _fuelType,
        kilometerDriven: int.tryParse(kilometerController.text.trim()),
        numberOfOwners: _numberOfOwners,
        // Accessories / Spare Parts fields
        subCategory: _subCategory,
        condition: _condition,
        sellerType: _sellerType,
      );

      if (isEditing) {
        await _firestoreService.updateProduct(_editingProductId!, product);
      } else {
        await _firestoreService.addProduct(product);
      }

      _isLoading = false;
      _submissionErrorMessage = null;
      _submissionSuccessMessage ??= isEditing
          ? 'Your product has been updated!'
          : 'Your product has been posted!';
      update();
      return true;
    } on FirebaseAuthException catch (error, stackTrace) {
      _submissionErrorMessage = _friendlySubmissionError(
        code: error.code,
        message: error.message,
        fallback: 'Unable to verify your Firebase session right now.',
      );
      debugPrint('Error submitting product: $error\n$stackTrace');
      _isLoading = false;
      update();
      return false;
    } on FirebaseException catch (error, stackTrace) {
      _submissionErrorMessage = _friendlySubmissionError(
        code: error.code,
        message: error.message,
        fallback: 'Unable to save your product right now.',
      );
      debugPrint('Error submitting product: $error\n$stackTrace');
      _isLoading = false;
      update();
      return false;
    } on StateError catch (error, stackTrace) {
      _submissionErrorMessage = error.message;
      debugPrint('Error submitting product: $error\n$stackTrace');
      _isLoading = false;
      update();
      return false;
    } catch (e) {
      _submissionErrorMessage = 'Unable to save your product right now.';
      _isLoading = false;
      update();
      debugPrint('Error submitting product: $e');
      return false;
    }
  }

  /// Resets all form fields to their initial state.
  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    kilometerController.clear();
    priceController.clear();
    locationController.clear();
    _category = '';
    _brand = '';
    _year = null;
    _fuelType = null;
    _numberOfOwners = null;
    _subCategory = null;
    _condition = null;
    _sellerType = null;
    _imageUrls = [];
    _pickedImages.clear();
    _selectedImageIndex = 0;
    _isLoading = false;
    _isFetchingCurrentLocation = false;
    _submissionErrorMessage = null;
    _submissionSuccessMessage = null;
    _editingProductId = null;
    update();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    kilometerController.dispose();
    priceController.dispose();
    locationController.dispose();
    super.onClose();
  }

  bool validateBikeDetailsStep() {
    final validationError = _validateBikeDetailsStep();
    if (validationError == null) {
      return true;
    }

    _showValidationError(validationError);
    return false;
  }

  void loadProductForEditing(ProductModel product) {
    _editingProductId = product.id;
    _category = product.category;
    titleController.text = product.title;
    descriptionController.text = product.description;
    kilometerController.text = product.kilometerDriven?.toString() ?? '';
    priceController.text = product.price != null
        ? (product.price == product.price!.roundToDouble()
            ? product.price!.toInt().toString()
            : product.price!.toString())
        : '';
    locationController.text = product.location ?? '';
    _brand = product.brand;
    _year = product.year;
    _fuelType = product.fuelType;
    _numberOfOwners = product.numberOfOwners;
    _subCategory = product.subCategory;
    _condition = product.condition;
    _sellerType = product.sellerType;
    _imageUrls = List<String>.from(product.imageUrls);
    _pickedImages.clear();
    _selectedImageIndex = 0;
    _isLoading = false;
    _isFetchingCurrentLocation = false;
    _submissionErrorMessage = null;
    _submissionSuccessMessage = null;
    update();
  }

  bool validateAccessoryDetailsStep() {
    final validationError = _validateAccessoryDetailsStep();
    if (validationError == null) {
      return true;
    }

    _showValidationError(validationError);
    return false;
  }

  bool validatePriceAndLocationStep() {
    final validationError = _validatePriceAndLocationStep();
    if (validationError == null) {
      return true;
    }

    _showValidationError(validationError);
    return false;
  }

  Future<void> useCurrentLocationForProduct() async {
    if (_isFetchingCurrentLocation) {
      return;
    }

    _isFetchingCurrentLocation = true;
    update();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable location services to continue.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Enable it from app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      var resolvedAddress =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final placemark = placemarks.isNotEmpty ? placemarks.first : null;
        final address = _joinAddressParts([
          placemark?.street,
          placemark?.subLocality,
          placemark?.locality,
          placemark?.administrativeArea,
          placemark?.postalCode,
          placemark?.country,
        ]);
        if (address.isNotEmpty) {
          resolvedAddress = address;
        }
      } catch (_) {
        // Keep the coordinates fallback if reverse geocoding fails.
      }

      locationController.text = resolvedAddress;
      Get.snackbar(
        'Location added',
        'Current location has been added to your listing.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Location Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      _isFetchingCurrentLocation = false;
      update();
    }
  }

  Future<List<String>> _resolveProductImageUrls(String sellerId) async {
    final existingImageUrls = _imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    if (_pickedImages.isEmpty) {
      return existingImageUrls;
    }

    if (existingImageUrls.length == _pickedImages.length) {
      return existingImageUrls;
    }

    try {
      final uploadedImageUrls = await _storageService.uploadProductImages(
        sellerId: sellerId,
        imageBytes: _pickedImages.map((image) => image.bytes).toList(),
      );
      _imageUrls = uploadedImageUrls;
      return uploadedImageUrls;
    } on FirebaseException catch (error, stackTrace) {
      if (_canPostWithoutUploadedImages(error.code)) {
        debugPrint(
          'Falling back to posting without uploaded images: $error\n$stackTrace',
        );
        _submissionSuccessMessage =
            'Your product has been posted, but the images were not uploaded because Firebase Storage is not configured yet.';
        _imageUrls = [];
        return const [];
      }
      rethrow;
    }
  }

  String _resolveSellerName({
    required LoginController? loginController,
    required User? firebaseUser,
  }) {
    final profileDisplayName =
        loginController?.currentUserProfile?.displayName.trim() ?? '';
    if (profileDisplayName.isNotEmpty) {
      return profileDisplayName;
    }

    final authDisplayName = firebaseUser?.displayName?.trim() ?? '';
    if (authDisplayName.isNotEmpty) {
      return authDisplayName;
    }

    return 'Seller';
  }

  String? _validateProduct() {
    if (_category.trim().isEmpty) {
      return 'Select a category before posting.';
    }
    if (_pickedImages.isEmpty && _imageUrls.isEmpty) {
      return 'Upload at least one product image.';
    }

    final isBikeOrScooter = _category == 'Bikes' || _category == 'Scooter';
    final detailValidationError = isBikeOrScooter
        ? _validateBikeDetailsStep()
        : _validateAccessoryDetailsStep();
    if (detailValidationError != null) {
      return detailValidationError;
    }

    return _validatePriceAndLocationStep();
  }

  String? _validateBikeDetailsStep() {
    final commonValidationError = _validateCommonDetailsStep();
    if (commonValidationError != null) {
      return commonValidationError;
    }

    if ((_fuelType ?? '').trim().isEmpty) {
      return 'Select a fuel type.';
    }
    final kilometersText = kilometerController.text.trim();
    if (kilometersText.isEmpty) {
      return 'Enter kilometers driven.';
    }
    if (int.tryParse(kilometersText) == null) {
      return 'Enter a valid kilometers driven value.';
    }
    if (_numberOfOwners == null) {
      return 'Select the number of owners.';
    }
    return null;
  }

  String? _validateAccessoryDetailsStep() {
    final commonValidationError = _validateCommonDetailsStep();
    if (commonValidationError != null) {
      return commonValidationError;
    }

    if ((_subCategory ?? '').trim().isEmpty) {
      return 'Select a category for the product.';
    }
    if ((_condition ?? '').trim().isEmpty) {
      return 'Select the product condition.';
    }
    if ((_sellerType ?? '').trim().isEmpty) {
      return 'Select the seller type.';
    }
    return null;
  }

  String? _validateCommonDetailsStep() {
    if (titleController.text.trim().isEmpty) {
      return 'Enter a product title.';
    }
    if (_brand.trim().isEmpty) {
      return 'Select a brand.';
    }
    if (_year == null) {
      return 'Select the manufacturing year.';
    }
    if (descriptionController.text.trim().length < 20) {
      return 'Description must be at least 20 characters.';
    }
    return null;
  }

  String? _validatePriceAndLocationStep() {
    final priceText = priceController.text.trim();
    if (priceText.isEmpty) {
      return 'Enter a price.';
    }
    if (double.tryParse(priceText) == null) {
      return 'Enter a valid price.';
    }
    if (locationController.text.trim().isEmpty) {
      return 'Enter a location.';
    }
    return null;
  }

  void _showValidationError(String message) {
    Get.snackbar(
      'Missing details',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
    );
  }

  String _friendlySubmissionError({
    String? code,
    String? message,
    required String fallback,
  }) {
    final normalizedCode = code?.toLowerCase() ?? '';
    final normalizedMessage = message?.toLowerCase() ?? '';

    if (normalizedCode == 'operation-not-allowed' &&
        normalizedMessage.contains('anonymous')) {
      return 'Anonymous Firebase sign-in is disabled. Enable it in Firebase Authentication or turn off demo login before posting.';
    }
    if (normalizedCode == 'admin-restricted-operation' ||
        normalizedMessage.contains('restricted to administrators only')) {
      return 'Firebase blocked anonymous sign-in for this project. The app will need either a real signed-in user or Firebase rules that allow this product upload.';
    }
    if (normalizedCode == 'permission-denied' ||
        normalizedCode == 'unauthenticated' ||
        normalizedCode == 'unauthorized' ||
        normalizedMessage.contains('permission denied')) {
      return 'Firebase blocked this post request. Enable Anonymous sign-in and allow product writes in your Firebase rules, then try again.';
    }
    if (normalizedCode == 'bucket-not-found' ||
        normalizedCode == 'no-default-bucket') {
      return 'Firebase Storage is not configured for this project yet. Create the Storage bucket in Firebase Console and try again.';
    }
    if (normalizedCode == 'network-request-failed' ||
        normalizedCode == 'unavailable') {
      return 'Check your internet connection and try again.';
    }
    if (normalizedCode == 'quota-exceeded' ||
        normalizedCode == 'resource-exhausted') {
      return 'Firebase quota has been reached. Please try again later.';
    }
    if (normalizedCode == 'invalid-argument') {
      return 'Some product details are invalid. Please review the form and try again.';
    }
    if (normalizedCode == 'object-not-found') {
      return 'Firebase Storage could not find the uploaded image. Check the Storage bucket configuration and try again.';
    }

    final trimmedMessage = message?.trim() ?? '';
    if (trimmedMessage.isNotEmpty) {
      return trimmedMessage;
    }

    return fallback;
  }

  bool _canPostWithoutUploadedImages(String code) {
    final normalizedCode = code.toLowerCase();
    return normalizedCode == 'object-not-found' ||
        normalizedCode == 'bucket-not-found' ||
        normalizedCode == 'no-default-bucket' ||
        normalizedCode == 'unauthorized' ||
        normalizedCode == 'unauthenticated';
  }

  static String _joinAddressParts(List<String?> parts) {
    return parts
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .join(', ');
  }
}
