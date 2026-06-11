import 'dart:async';
import 'dart:typed_data';

import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/constants/product_categories.dart';
import 'package:bikebooking/core/utils/image_crop_helper.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
    String Function()? sellerIdProvider,
    String Function()? sellerNameProvider,
  })  : _firestoreService = firestoreService ?? ProductFirestoreService(),
        _storageService = storageService ?? ProductStorageService(),
        _imagePicker = imagePicker ?? ImagePicker(),
        _sellerIdProvider = sellerIdProvider,
        _sellerNameProvider = sellerNameProvider;

  final ProductFirestoreService _firestoreService;
  final ProductStorageService _storageService;
  final ImagePicker _imagePicker;
  final String Function()? _sellerIdProvider;
  final String Function()? _sellerNameProvider;
  static const int _maxProductImages = 6;
  static const Duration _currentLocationTimeout = Duration(seconds: 15);


  // ── Step 1: Category ──
  String _category = '';
  String get category => _category;

  void setCategory(String value) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return;
    }

    final nextCategory = _isBikeOrScooterCategory(normalizedValue)
        ? ProductCategoryCatalog.baseCategoryFor(normalizedValue)
        : normalizedValue;
    if (nextCategory == _category) {
      return;
    }

    final previousCategory = _category;
    final previousBaseCategory = previousCategory.isEmpty
        ? ''
        : ProductCategoryCatalog.baseCategoryFor(previousCategory);
    final nextBaseCategory =
        ProductCategoryCatalog.baseCategoryFor(nextCategory);
    _category = nextCategory;

    if (_isBikeOrScooterCategory(nextCategory)) {
      _condition = null;
      _sellerType = null;

      if (!_isBikeOrScooterCategory(previousCategory) ||
          previousBaseCategory != nextBaseCategory) {
        _subCategory = null;
        _fuelType = null;
        kilometerController.clear();
        _numberOfOwners = null;
      }
    } else {
      _fuelType = null;
      kilometerController.clear();
      _numberOfOwners = null;

      if (previousCategory != nextCategory) {
        _subCategory = null;
      }
    }

    update();
  }

  bool _isBikeOrScooterCategory(String category) =>
      ProductCategoryCatalog.isVehicleCategory(category);

  bool get isBikeOrScooterCategory => _isBikeOrScooterCategory(_category);

  List<VehicleSubCategoryOption> get vehicleSubCategoryOptions =>
      ProductCategoryCatalog.vehicleOptionsFor(_category);

  // ── Step 2: Images (URLs — placeholder for now) ──
  List<String> _imageUrls = [];
  List<String> get imageUrls => _imageUrls;
  List<String> get existingImageUrls =>
      _imageUrls.where((url) => url.trim().isNotEmpty).toList(growable: false);
  final List<PickedProductImage> _pickedImages = [];
  List<PickedProductImage> get pickedImages => List.unmodifiable(_pickedImages);
  int _selectedImageIndex = 0;
  int get selectedImageIndex => _selectedImageIndex;
  bool get hasPickedImages => _pickedImages.isNotEmpty;
  bool get hasAnyImages =>
      existingImageUrls.isNotEmpty || _pickedImages.isNotEmpty;
  int get totalImageCount => existingImageUrls.length + _pickedImages.length;
  String? get selectedPreviewImageUrl {
    if (_selectedImageIndex < 0 ||
        _selectedImageIndex >= existingImageUrls.length) {
      return null;
    }
    return existingImageUrls[_selectedImageIndex];
  }

  PickedProductImage? get selectedPreviewImage {
    final pickedImageIndex = _selectedImageIndex - existingImageUrls.length;
    if (pickedImageIndex < 0 || pickedImageIndex >= _pickedImages.length) {
      return null;
    }
    return _pickedImages[pickedImageIndex];
  }

  void setImageUrls(List<String> urls) {
    _imageUrls = urls;
    if (_selectedImageIndex >= totalImageCount) {
      _selectedImageIndex = totalImageCount == 0 ? 0 : totalImageCount - 1;
    }
    update();
  }

  Future<void> pickProductImages() async {
    try {
      final remainingSlots = _maxProductImages - totalImageCount;
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
        final croppedFile = await ImageCropHelper.cropImage(
          sourceFile: file,
          aspectRatio: CropAspectRatioPresetType.freeStyle,
        );
        if (croppedFile == null) continue;
        final bytes = await croppedFile.readAsBytes();
        newImages.add(PickedProductImage(file: croppedFile, bytes: bytes));
      }

      _pickedImages.addAll(newImages);
      if (newImages.isNotEmpty) {
        _selectedImageIndex = existingImageUrls.length;
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
    if (index < 0 || index >= totalImageCount) {
      return;
    }
    _selectedImageIndex = index;
    update();
  }

  /// URLs of existing images that have been removed by the user.
  /// These are cleaned up from Firebase Storage when the product is submitted.
  final List<String> _removedExistingImageUrls = [];
  List<String> get removedExistingImageUrls =>
      List.unmodifiable(_removedExistingImageUrls);

  /// Removes the image at [index] from the combined image list
  /// (existing URLs first, then locally-picked images).
  void removeImage(int index) {
    if (index < 0 || index >= totalImageCount) {
      return;
    }

    final existingCount = existingImageUrls.length;

    if (index < existingCount) {
      // Remove an existing (remote) image URL.
      // Find the actual position in the _imageUrls list (which may contain
      // empty-string entries that existingImageUrls filters out).
      final urlToRemove = existingImageUrls[index];
      _imageUrls.remove(urlToRemove);
      _removedExistingImageUrls.add(urlToRemove);
    } else {
      // Remove a locally-picked image.
      final pickedIndex = index - existingCount;
      if (pickedIndex >= 0 && pickedIndex < _pickedImages.length) {
        _pickedImages.removeAt(pickedIndex);
      }
    }

    // Adjust the selected index so it stays in bounds.
    if (totalImageCount == 0) {
      _selectedImageIndex = 0;
    } else if (_selectedImageIndex >= totalImageCount) {
      _selectedImageIndex = totalImageCount - 1;
    }

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
    final normalizedValue = value.trim();
    _subCategory = normalizedValue.isEmpty ? null : normalizedValue;
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

  // ── Location place search ──
  static const int _minLocationSearchLength = 2;
  final GetConnect _placeConnect = GetConnect();
  Timer? _locationSearchDebounce;
  int _locationSearchRequestId = 0;
  String _locationSearchSessionToken =
      DateTime.now().microsecondsSinceEpoch.toString();

  List<PlaceSuggestion> _locationSuggestions = [];
  List<PlaceSuggestion> get locationSuggestions =>
      List.unmodifiable(_locationSuggestions);
  bool _isSearchingLocation = false;
  bool get isSearchingLocation => _isSearchingLocation;

  // Coordinates captured for the selected listing location. These mirror the
  // way the user's own location is stored (lat/lng), so listings can be
  // distance-filtered on the listing pages.
  double? _latitude;
  double? _longitude;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get hasLocationCoordinates => _latitude != null && _longitude != null;

  final ScrollController locationFormScrollController = ScrollController();

  void _scrollToLocationSuggestions() {
    if (_locationSuggestions.isEmpty) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (locationFormScrollController.hasClients) {
        locationFormScrollController.animateTo(
          locationFormScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void onLocationQueryChanged(String value) {
    _locationSearchDebounce?.cancel();
    _locationSearchRequestId++;

    // The user is editing the address text manually, so any previously
    // captured coordinates no longer match what is shown.
    _latitude = null;
    _longitude = null;

    final trimmed = value.trim();
    if (trimmed.length < _minLocationSearchLength) {
      _locationSuggestions = [];
      _isSearchingLocation = false;
      update();
      return;
    }

    _isSearchingLocation = true;
    update();

    _locationSearchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchLocationPlaces(trimmed),
    );
  }

  Future<void> _searchLocationPlaces(String query) async {
    final requestId = ++_locationSearchRequestId;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': query,
        'key': AppConfig.googlePlacesApiKey,
        'components': 'country:in',
        'types': 'geocode',
        'language': 'en',
        'sessiontoken': _locationSearchSessionToken,
      },
    );

    try {
      final response = await _placeConnect.get(uri.toString());
      if (requestId != _locationSearchRequestId) return;

      final body = response.body;
      if (!response.isOk || body is! Map) {
        _locationSuggestions = [];
      } else {
        final map = Map<String, dynamic>.from(body);
        final status = map['status']?.toString() ?? '';
        if (status == 'OK') {
          _locationSuggestions =
              (map['predictions'] as List<dynamic>? ?? [])
                  .whereType<Map>()
                  .map((p) => PlaceSuggestion.fromJson(
                        Map<String, dynamic>.from(p)))
                  .toList();
        } else {
          _locationSuggestions = [];
        }
      }
    } catch (_) {
      if (requestId != _locationSearchRequestId) return;
      _locationSuggestions = [];
    } finally {
      if (requestId == _locationSearchRequestId) {
        _isSearchingLocation = false;
        update();
        _scrollToLocationSuggestions();
      }
    }
  }

  Future<void> selectLocationSuggestion(PlaceSuggestion suggestion) async {
    _locationSearchDebounce?.cancel();
    final requestId = ++_locationSearchRequestId;
    locationController.text = suggestion.description;
    _locationSuggestions = [];
    _isSearchingLocation = false;
    _latitude = null;
    _longitude = null;
    update();

    // Resolve the coordinates for the chosen place so the listing can be
    // distance-filtered later, mirroring how the user's own location is saved.
    try {
      final resolved = await _resolvePlaceCoordinates(suggestion);
      // Ignore stale responses if the user picked/edited another location.
      if (requestId != _locationSearchRequestId) {
        return;
      }
      if (resolved != null) {
        _latitude = resolved.latitude;
        _longitude = resolved.longitude;
      }
    } catch (error) {
      debugPrint('Unable to resolve listing location coordinates: $error');
    } finally {
      if (requestId == _locationSearchRequestId) {
        _locationSearchSessionToken =
            DateTime.now().microsecondsSinceEpoch.toString();
        update();
      }
    }
  }

  /// Captures a manually-selected location (state/city/area) along with its
  /// coordinates, mirroring the user-location manual selection flow.
  void setManualLocation(
    String displayAddress, {
    double? latitude,
    double? longitude,
  }) {
    _locationSearchDebounce?.cancel();
    _locationSearchRequestId++;
    locationController.text = displayAddress;
    _locationSuggestions = [];
    _isSearchingLocation = false;
    _latitude = latitude;
    _longitude = longitude;
    update();
  }

  /// Fetches latitude/longitude for [suggestion] via Google Place Details.
  /// Returns null when coordinates can't be resolved.
  Future<({double latitude, double longitude})?> _resolvePlaceCoordinates(
    PlaceSuggestion suggestion,
  ) async {
    if (suggestion.latitude != null && suggestion.longitude != null) {
      return (
        latitude: suggestion.latitude!,
        longitude: suggestion.longitude!,
      );
    }

    if (suggestion.placeId.trim().isEmpty) {
      return null;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': suggestion.placeId,
        'fields': 'geometry/location',
        'key': AppConfig.googlePlacesApiKey,
        'language': 'en',
        'sessiontoken': _locationSearchSessionToken,
      },
    );

    final response = await _placeConnect.get(uri.toString());
    final body = response.body;
    if (!response.isOk || body is! Map) {
      return null;
    }

    final responseMap = Map<String, dynamic>.from(body);
    if ((responseMap['status']?.toString() ?? '') != 'OK') {
      return null;
    }

    final result = responseMap['result'];
    if (result is! Map) {
      return null;
    }

    final geometry = result['geometry'];
    final locationMap = geometry is Map
        ? Map<String, dynamic>.from(geometry['location'] as Map? ?? {})
        : <String, dynamic>{};

    final latitude = (locationMap['lat'] as num?)?.toDouble();
    final longitude = (locationMap['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      return null;
    }

    return (latitude: latitude, longitude: longitude);
  }

  void clearLocationSuggestions() {
    _locationSearchDebounce?.cancel();
    _locationSearchRequestId++;
    _locationSuggestions = [];
    _isSearchingLocation = false;
    update();
  }

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
  String _status = ProductStatus.active;
  String get status => _status;
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
      final providedSellerId = _sellerIdProvider?.call().trim() ?? '';
      final loginController = Get.isRegistered<LoginController>()
          ? Get.find<LoginController>()
          : null;
      await _ensureFirebaseSessionForSubmission(
        loginController: loginController,
        providedSellerId: providedSellerId,
      );
      final firebaseUser = providedSellerId.isNotEmpty
          ? null
          : FirebaseAuth.instance.currentUser;
      final sellerId = _resolveSellerId(
        providedSellerId: providedSellerId,
        loginController: loginController,
        firebaseUser: firebaseUser,
      );
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

      final effectiveStatus = _status;

      final product = ProductModel(
        id: _editingProductId,
        category: ProductCategoryCatalog.baseCategoryFor(_category),
        title: titleController.text.trim(),
        brand: _brand,
        year: _year,
        description: descriptionController.text.trim(),
        price: double.tryParse(priceController.text.trim()),
        location: locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: uploadedImageUrls,
        sellerId: sellerId,
        sellerName: sellerName,
        status: effectiveStatus,
        // Bike / Scooter fields
        fuelType: _fuelType,
        kilometerDriven: int.tryParse(kilometerController.text.trim()),
        numberOfOwners: _numberOfOwners,
        // Accessories / Spare Parts fields
        subCategory: _subCategory,
        condition: _condition,
        sellerType: _sellerType,
      );

      String? savedProductId;
      if (isEditing) {
        await _firestoreService.updateProduct(_editingProductId!, product);
        savedProductId = _editingProductId;
      } else {
        savedProductId = await _firestoreService.addProduct(product);
      }

      // Clean up any images the user removed during this session.
      _deleteRemovedImagesFromStorage();

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
    _locationSuggestions = [];
    _isSearchingLocation = false;
    _locationSearchDebounce?.cancel();
    _latitude = null;
    _longitude = null;
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
    _removedExistingImageUrls.clear();
    _selectedImageIndex = 0;
    _isLoading = false;
    _isFetchingCurrentLocation = false;
    _submissionErrorMessage = null;
    _submissionSuccessMessage = null;
    _editingProductId = null;
    _status = ProductStatus.active;
    update();
  }

  @override
  void onClose() {
    _locationSearchDebounce?.cancel();
    locationFormScrollController.dispose();
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
    _status = ProductStatus.normalize(product.status);
    final normalizedCategory = product.category.trim();
    _category = normalizedCategory.isEmpty
        ? ''
        : ProductCategoryCatalog.baseCategoryFor(normalizedCategory);
    titleController.text = product.title;
    descriptionController.text = product.description;
    kilometerController.text = product.kilometerDriven?.toString() ?? '';
    priceController.text = product.price != null
        ? (product.price == product.price!.roundToDouble()
            ? product.price!.toInt().toString()
            : product.price!.toString())
        : '';
    locationController.text = product.location ?? '';
    _latitude = product.latitude;
    _longitude = product.longitude;
    _brand = product.brand;
    _year = product.year;
    _fuelType = product.fuelType;
    _numberOfOwners = product.numberOfOwners;
    _subCategory = ProductCategoryCatalog.isVehicleCategory(normalizedCategory)
        ? ProductCategoryCatalog.resolveVehicleSubCategory(
            category: normalizedCategory,
            subCategory: product.subCategory,
            fuelType: product.fuelType,
          )
        : product.subCategory;
    _condition = product.condition;
    _sellerType = product.sellerType;
    _imageUrls = List<String>.from(product.imageUrls);
    _pickedImages.clear();
    _removedExistingImageUrls.clear();
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
    clearLocationSuggestions();
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

      final position = await _getCurrentPosition();

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
      _latitude = position.latitude;
      _longitude = position.longitude;
      Get.snackbar(
        'Location added',
        'Current location has been added to your listing.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      final message = _friendlyLocationError(error);
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

  Future<Position> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: _currentLocationTimeout,
        ),
      );
    } on TimeoutException {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        return lastKnownPosition;
      }

      throw Exception(
        'Unable to detect your location right now. Move to an open area, make sure GPS is on, and try again.',
      );
    }
  }

  Future<List<String>> _resolveProductImageUrls(String sellerId) async {
    final existingImageUrls = _imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    if (_pickedImages.isEmpty) {
      return existingImageUrls;
    }

    final uploadedImageUrls = await _storageService.uploadProductImages(
      sellerId: sellerId,
      imageBytes: _pickedImages.map((image) => image.bytes).toList(),
    );
    _imageUrls = [...existingImageUrls, ...uploadedImageUrls];
    return _imageUrls;
  }

  /// Fire-and-forget cleanup of images the user removed during this session.
  void _deleteRemovedImagesFromStorage() {
    if (_removedExistingImageUrls.isEmpty) {
      return;
    }

    final urlsToDelete = List<String>.from(_removedExistingImageUrls);
    _removedExistingImageUrls.clear();

    for (final url in urlsToDelete) {
      _storageService.deleteImageByUrl(url).catchError((_) {
        debugPrint('Failed to delete removed image from storage: $url');
        return false;
      });
    }
  }

  Future<void> _ensureFirebaseSessionForSubmission({
    required LoginController? loginController,
    required String providedSellerId,
  }) async {
    if (providedSellerId.isNotEmpty || loginController == null) {
      return;
    }

    if (!loginController.isPhoneAuthBypassed ||
        FirebaseAuth.instance.currentUser != null) {
      return;
    }

    final hasSession = await loginController.ensureFirestoreSession();
    if (hasSession) {
      return;
    }

    final sessionErrorMessage =
        loginController.firestoreSessionErrorMessage?.trim() ?? '';
    throw StateError(
      sessionErrorMessage.isNotEmpty
          ? sessionErrorMessage
          : 'Unable to verify your Firebase session right now.',
    );
  }

  String _resolveSellerId({
    required String providedSellerId,
    required LoginController? loginController,
    required User? firebaseUser,
  }) {
    if (providedSellerId.isNotEmpty) {
      return providedSellerId;
    }

    final profileUserId = loginController?.currentUserProfile?.id.trim() ?? '';
    if (loginController?.isPhoneAuthBypassed == true &&
        profileUserId.isNotEmpty) {
      return profileUserId;
    }

    final firebaseUserId = firebaseUser?.uid.trim() ?? '';
    if (firebaseUserId.isNotEmpty) {
      return firebaseUserId;
    }

    return profileUserId;
  }

  String _resolveSellerName({
    required LoginController? loginController,
    required User? firebaseUser,
  }) {
    final providedSellerName = _sellerNameProvider?.call().trim() ?? '';
    if (providedSellerName.isNotEmpty) {
      return providedSellerName;
    }

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

    final isBikeOrScooter = _isBikeOrScooterCategory(_category);
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

    if ((_subCategory ?? '').trim().isEmpty) {
      return 'Select a sub category.';
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

  String _friendlyLocationError(Object error) {
    if (error is TimeoutException) {
      return 'Unable to detect your location right now. Move to an open area, make sure GPS is on, and try again.';
    }

    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.toLowerCase().contains('timeoutexception')) {
      return 'Unable to detect your location right now. Move to an open area, make sure GPS is on, and try again.';
    }

    return message;
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
