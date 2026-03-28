import 'dart:async';

import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/app_snackbar.dart';
import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:bikebooking/features/auth/data/services/firebase_auth_service.dart';
import 'package:bikebooking/features/auth/data/services/user_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.description,
    this.latitude,
    this.longitude,
    this.address,
  });

  final String placeId;
  final String title;
  final String subtitle;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? address;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;
    final description = (json['description']?.toString() ?? '').trim();
    final title = (structuredFormatting?['main_text']?.toString() ?? '').trim();
    final subtitle = (structuredFormatting?['secondary_text']?.toString() ?? '').trim();

    return PlaceSuggestion(
      placeId: (json['place_id']?.toString() ?? description).trim(),
      title: title.isNotEmpty ? title : description,
      subtitle: subtitle.isNotEmpty ? subtitle : description,
      description: description,
      address: description,
    );
  }

  PlaceSuggestion copyWith({
    String? placeId,
    String? title,
    String? subtitle,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return PlaceSuggestion(
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }
}

class LoginController extends GetxController {
  LoginController(this._authService, this._userFirestoreService);

  final FirebaseAuthService _authService;
  final UserFirestoreService _userFirestoreService;
  final GetConnect _connect = GetConnect();

  static const int _minimumPlaceSearchLength = 2;
  static const bool _bypassPhoneAuth = true;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController registeredMobileNumberController = TextEditingController();
  final TextEditingController locationSearchController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  bool isLoadingProfile = false;
  bool isSavingProfile = false;
  bool isSearchingPlaces = false;
  bool isFetchingCurrentLocation = false;
  bool isSavingLocation = false;
  bool _isHandlingSplashNavigation = false;

  String? verificationId;
  int? resendToken;
  String? phoneNumber;
  String? errorMessage;
  String? infoMessage;
  String? placeSearchError;
  String? placeSearchInfo = 'Type at least 2 characters to search.';
  PlaceSuggestion? selectedPlace;
  List<PlaceSuggestion> placeSuggestions = [];
  AppUserModel? currentUserProfile;

  Timer? _placeSearchDebounce;
  int _placeSearchRequestId = 0;
  String _placeSearchSessionToken = _createPlaceSearchSessionToken();

  String get otpCode => otpControllers.map((controller) => controller.text).join();

  @override
  void onClose() {
    phoneController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    registeredMobileNumberController.dispose();
    locationSearchController.dispose();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    _placeSearchDebounce?.cancel();
    super.onClose();
  }

  void updatePhoneNumber(String value) {
    phoneController.value = phoneController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    update();
  }

  void initializeOtp(String incomingPhoneNumber) {
    phoneNumber ??= incomingPhoneNumber;
  }

  void updateOtpDigit(int index, String value) {
    final sanitizedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    otpControllers[index].value = otpControllers[index].value.copyWith(
          text: sanitizedValue,
          selection: TextSelection.collapsed(offset: sanitizedValue.length),
        );

    if (sanitizedValue.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (sanitizedValue.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }

    update();
  }

  Future<void> handleSplashNavigation() async {
    if (_isHandlingSplashNavigation) {
      return;
    }

    _isHandlingSplashNavigation = true;
    isLoadingProfile = true;
    update();

    try {
      await Future<void>.delayed(const Duration(seconds: 2));

      if (_bypassPhoneAuth) {
        final localUser = currentUserProfile;
        if (localUser == null) {
          _clearLocalSession();
          Get.offAllNamed('/login');
          return;
        }

        phoneNumber = localUser.phoneNumber;
        _syncProfileControllers(localUser);

        if (localUser.hasLocation) {
          Get.offAllNamed('/home');
          return;
        }

        Get.offAllNamed('/select_location');
        return;
      }

      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        _clearLocalSession();
        Get.offAllNamed('/login');
        return;
      }

      final userProfile = await _ensureUserDocument(
        firebaseUser,
        fallbackPhoneNumber: firebaseUser.phoneNumber,
      );

      if (userProfile.hasLocation) {
        Get.offAllNamed('/home');
        return;
      }

      Get.offAllNamed('/select_location');
    } catch (_) {
      await _safeSignOut();
      _clearLocalSession();
      Get.offAllNamed('/login');
    } finally {
      _isHandlingSplashNavigation = false;
      isLoadingProfile = false;
      update();
    }
  }

  Future<void> sendOtp() async {
    final formattedPhoneNumber = _formatPhoneNumber(phoneController.text);
    if (formattedPhoneNumber == null) {
      _setError('Enter a valid 10 digit phone number.');
      return;
    }

    if (_bypassPhoneAuth) {
      phoneNumber = formattedPhoneNumber;
      isSendingOtp = false;
      errorMessage = null;
      _clearOtpFields();
      _showInfo('Demo mode: enter any 6 digits to continue.');
      if (Get.currentRoute != '/otp') {
        Get.toNamed('/otp', arguments: formattedPhoneNumber);
      }
      return;
    }

    if (!_ensureFirebaseConfigured()) {
      return;
    }

    final authPhoneNumber = _formatPhoneNumberForAuth(phoneController.text);
    if (authPhoneNumber == null) {
      _setError('Enter a valid 10 digit phone number.');
      return;
    }

    isSendingOtp = true;
    phoneNumber = formattedPhoneNumber;
    errorMessage = null;
    infoMessage = null;
    update();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: authPhoneNumber,
        forceResendingToken: resendToken,
        verificationCompleted: (credential) async {
          try {
            final userCredential = await _authService.signInWithCredential(credential);
            await _handleSuccessfulSignIn(
              userCredential.user,
              fallbackPhoneNumber: formattedPhoneNumber,
            );
          } on FirebaseAuthException catch (exception) {
            _setFirebaseError(
              exception,
              fallback: 'Auto verification failed. Please enter the OTP manually.',
            );
          } on StateError catch (exception) {
            _setError(exception.message);
          } catch (_) {
            _setError(
              'Auto verification failed. Please enter the OTP manually.',
            );
          }
        },
        verificationFailed: (exception) {
          isSendingOtp = false;
          _setFirebaseError(
            exception,
            fallback: 'Unable to send OTP right now.',
          );
        },
        codeSent: (receivedVerificationId, receivedResendToken) {
          verificationId = receivedVerificationId;
          resendToken = receivedResendToken;
          isSendingOtp = false;
          _clearOtpFields();
          update();
          _showInfo('OTP sent successfully.');
          if (Get.currentRoute != '/otp') {
            Get.toNamed('/otp', arguments: formattedPhoneNumber);
          }
        },
        codeAutoRetrievalTimeout: (receivedVerificationId) {
          verificationId = receivedVerificationId;
          isSendingOtp = false;
          update();
        },
      );
    } on FirebaseAuthException catch (exception) {
      isSendingOtp = false;
      _setFirebaseError(exception, fallback: 'Unable to send OTP right now.');
    } on StateError catch (exception) {
      isSendingOtp = false;
      _setError(exception.message);
    } catch (_) {
      isSendingOtp = false;
      _setError('Unable to send OTP right now. Please try again.');
    }
  }

  Future<void> resendOtp() async {
    if (phoneNumber == null) {
      _setError('Phone number is missing. Please restart the login flow.');
      return;
    }

    phoneController.text = phoneNumber!.trim();

    if (_bypassPhoneAuth) {
      isSendingOtp = false;
      errorMessage = null;
      _clearOtpFields();
      _showInfo('Demo mode: enter any 6 digits to continue.');
      return;
    }

    await sendOtp();
  }

  Future<void> verifyOtp() async {
    if (_bypassPhoneAuth) {
      final resolvedPhoneNumber = phoneNumber?.trim() ?? '';
      if (resolvedPhoneNumber.isEmpty) {
        _setError('Phone number is missing. Please restart the login flow.');
        return;
      }

      if (otpCode.length != otpControllers.length) {
        _setError('Enter the 6 digit OTP to continue.');
        return;
      }

      final userProfile = await _ensureLocalUserDocument(
        fallbackPhoneNumber: resolvedPhoneNumber,
      );

      isVerifyingOtp = false;
      errorMessage = null;
      infoMessage = null;
      update();

      if (userProfile.hasLocation) {
        Get.offAllNamed('/home');
        return;
      }

      Get.offAllNamed('/select_location');
      return;
    }

    if (verificationId == null || verificationId!.isEmpty) {
      _setError('OTP session expired. Please request a new OTP.');
      return;
    }

    if (otpCode.length != otpControllers.length) {
      _setError('Enter the complete OTP.');
      return;
    }

    if (!_ensureFirebaseConfigured()) {
      return;
    }

    isVerifyingOtp = true;
    update();

    try {
      final userCredential = await _authService.signInWithOtp(
        verificationId: verificationId!,
        smsCode: otpCode,
      );
      isVerifyingOtp = false;
      await _handleSuccessfulSignIn(
        userCredential.user,
        fallbackPhoneNumber: phoneNumber,
      );
    } on FirebaseAuthException catch (exception) {
      isVerifyingOtp = false;
      _setFirebaseError(exception, fallback: 'Invalid OTP. Please try again.');
    } on StateError catch (exception) {
      isVerifyingOtp = false;
      _setError(exception.message);
    } catch (_) {
      isVerifyingOtp = false;
      _setError('OTP verification failed. Please try again.');
    }
  }

  Future<void> useCurrentLocation() async {
    isFetchingCurrentLocation = true;
    placeSearchError = null;
    placeSearchInfo = null;
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

      var title = 'Current Location';
      var description = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final placemark = placemarks.isNotEmpty ? placemarks.first : null;
        final resolvedTitle = _joinAddressParts([
          placemark?.locality,
          placemark?.subAdministrativeArea,
          placemark?.administrativeArea,
        ]);
        final resolvedDescription = _joinAddressParts([
          placemark?.street,
          placemark?.subLocality,
          placemark?.locality,
          placemark?.administrativeArea,
          placemark?.postalCode,
          placemark?.country,
        ]);

        if (resolvedTitle.isNotEmpty) {
          title = resolvedTitle;
        }
        if (resolvedDescription.isNotEmpty) {
          description = resolvedDescription;
        }
      } catch (_) {
        // If reverse geocoding fails, keep the coordinates fallback.
      }

      final currentPlace = PlaceSuggestion(
        placeId: '${position.latitude},${position.longitude}',
        title: title,
        subtitle: description,
        description: description,
        latitude: position.latitude,
        longitude: position.longitude,
        address: description,
      );

      selectedPlace = currentPlace;
      locationSearchController.value = locationSearchController.value.copyWith(
        text: currentPlace.description,
        selection: TextSelection.collapsed(
          offset: currentPlace.description.length,
        ),
      );
      placeSuggestions = [];

      await _persistLocationForCurrentUser(
        UserLocationModel(
          address: description,
          latitude: position.latitude,
          longitude: position.longitude,
          label: title,
        ),
      );

      placeSearchInfo = 'Location saved successfully.';
      Get.offAllNamed('/home');
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      placeSearchError = message;
      Get.snackbar(
        'Location Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isFetchingCurrentLocation = false;
      update();
    }
  }

  void initializeLocationSearch() {
    _placeSearchDebounce?.cancel();
    _placeSearchRequestId++;
    _placeSearchSessionToken = _createPlaceSearchSessionToken();
    isSearchingPlaces = false;
    isSavingLocation = false;
    placeSearchError = null;
    placeSearchInfo = 'Type at least 2 characters to search.';
    selectedPlace = null;
    placeSuggestions = [];
    locationSearchController.clear();
    update();
  }

  void updateLocationQuery(String value) {
    if (locationSearchController.text != value) {
      locationSearchController.value = locationSearchController.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }

    _placeSearchDebounce?.cancel();
    _placeSearchRequestId++;
    selectedPlace = null;
    placeSearchError = null;

    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      isSearchingPlaces = false;
      placeSuggestions = [];
      placeSearchInfo = 'Type at least 2 characters to search.';
      update();
      return;
    }

    if (trimmedValue.length < _minimumPlaceSearchLength) {
      isSearchingPlaces = false;
      placeSuggestions = [];
      placeSearchInfo = 'Type at least 2 characters to search.';
      update();
      return;
    }

    placeSearchInfo = null;
    update();

    _placeSearchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => searchPlaces(trimmedValue),
    );
  }

  Future<void> searchPlaces(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < _minimumPlaceSearchLength) {
      return;
    }

    final requestId = ++_placeSearchRequestId;
    isSearchingPlaces = true;
    placeSearchError = null;
    placeSearchInfo = null;
    update();

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': trimmedQuery,
        'key': AppConfig.googlePlacesApiKey,
        'components': 'country:in',
        'types': 'geocode',
        'language': 'en',
        'sessiontoken': _placeSearchSessionToken,
      },
    );

    try {
      final response = await _connect.get(uri.toString());
      if (requestId != _placeSearchRequestId) {
        return;
      }

      final body = response.body;
      if (!response.isOk || body is! Map) {
        throw Exception('Unable to fetch places.');
      }

      final responseMap = Map<String, dynamic>.from(body);
      final status = responseMap['status']?.toString() ?? 'UNKNOWN_ERROR';

      if (status == 'OK') {
        final predictions = (responseMap['predictions'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (prediction) => PlaceSuggestion.fromJson(
                Map<String, dynamic>.from(prediction),
              ),
            )
            .toList();

        placeSuggestions = predictions;
        placeSearchInfo = predictions.isEmpty ? 'No places found for "$trimmedQuery".' : null;
      } else if (status == 'ZERO_RESULTS') {
        placeSuggestions = [];
        placeSearchInfo = 'No places found for "$trimmedQuery".';
      } else {
        final apiErrorMessage = responseMap['error_message']?.toString();
        throw Exception(
          apiErrorMessage?.isNotEmpty == true ? apiErrorMessage : 'Google Places returned $status.',
        );
      }
    } catch (_) {
      if (requestId != _placeSearchRequestId) {
        return;
      }
      placeSuggestions = [];
      placeSearchError = 'Unable to fetch places right now. Check the API key and internet access.';
    } finally {
      if (requestId == _placeSearchRequestId) {
        isSearchingPlaces = false;
        update();
      }
    }
  }

  void selectPlaceSuggestion(PlaceSuggestion suggestion) {
    _placeSearchDebounce?.cancel();
    _placeSearchRequestId++;
    selectedPlace = suggestion;
    placeSuggestions = [];
    isSearchingPlaces = false;
    placeSearchError = null;
    placeSearchInfo = 'Selected location: ${suggestion.title}';
    locationSearchController.value = locationSearchController.value.copyWith(
      text: suggestion.description,
      selection: TextSelection.collapsed(offset: suggestion.description.length),
    );
    update();
  }

  void clearLocationSearch() {
    _placeSearchDebounce?.cancel();
    _placeSearchRequestId++;
    _placeSearchSessionToken = _createPlaceSearchSessionToken();
    isSearchingPlaces = false;
    isSavingLocation = false;
    selectedPlace = null;
    placeSuggestions = [];
    placeSearchError = null;
    placeSearchInfo = 'Type at least 2 characters to search.';
    locationSearchController.clear();
    update();
  }

  Future<void> confirmSelectedLocation() async {
    if (selectedPlace == null) {
      placeSearchError = 'Select a place from the search results to continue.';
      update();
      return;
    }

    isSavingLocation = true;
    placeSearchError = null;
    placeSearchInfo = null;
    update();

    try {
      final resolvedLocation = await _resolveSelectedLocation(selectedPlace!);
      selectedPlace = selectedPlace!.copyWith(
        description: resolvedLocation.address,
        subtitle: resolvedLocation.address,
        address: resolvedLocation.address,
        latitude: resolvedLocation.latitude,
        longitude: resolvedLocation.longitude,
      );

      await _persistLocationForCurrentUser(resolvedLocation);

      placeSearchInfo = 'Location saved successfully.';
      Get.offAllNamed('/home');
    } catch (error) {
      placeSearchError = error.toString().replaceFirst('Exception: ', '');
      _showSnackbar(
        title: 'Location Error',
        message: placeSearchError!,
        backgroundColor: const Color(0xFFC62828),
      );
    } finally {
      isSavingLocation = false;
      update();
    }
  }

  Future<bool> saveProfile() async {
    final firebaseUser = _authService.currentUser;
    final shouldUseLocalSession = _bypassPhoneAuth || firebaseUser == null;

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final registeredMobileNumber = registeredMobileNumberController.text.trim();

    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      _setError('Enter a valid email address.');
      return false;
    }

    final formattedRegisteredMobile = _formatOptionalPhoneNumber(registeredMobileNumber);
    if (registeredMobileNumber.isNotEmpty && formattedRegisteredMobile == null) {
      _setError('Enter a valid registered mobile number.');
      return false;
    }

    isSavingProfile = true;
    update();

    try {
      late final AppUserModel updatedUser;

      if (shouldUseLocalSession) {
        final baseUser = await _ensureLocalUserDocument(
          fallbackPhoneNumber: phoneNumber,
        );
        try {
          updatedUser = await _userFirestoreService.updateProfile(
            userId: baseUser.id,
            fullName: fullName,
            email: email,
            registeredMobileNumber: formattedRegisteredMobile ?? '',
          );
        } catch (_) {
          updatedUser = baseUser.copyWith(
            fullName: fullName,
            email: email,
            registeredMobileNumber: formattedRegisteredMobile ?? '',
            updatedAt: DateTime.now(),
          );
        }
      } else {
        updatedUser = await _userFirestoreService.updateProfile(
          userId: firebaseUser.uid,
          fullName: fullName,
          email: email,
          registeredMobileNumber: formattedRegisteredMobile ?? '',
        );
      }

      _setCurrentUserProfile(updatedUser);

      if (!shouldUseLocalSession && fullName.isNotEmpty) {
        try {
          await _authService.updateDisplayName(fullName);
        } catch (_) {
          // The Firestore profile remains the source of truth.
        }
      }

      _showInfo('Profile updated successfully.');
      return true;
    } catch (_) {
      _setError('Unable to update profile right now. Please try again.');
      return false;
    } finally {
      isSavingProfile = false;
      update();
    }
  }

  Future<void> refreshCurrentUserProfile() async {
    final firebaseUser = _authService.currentUser;
    if (_bypassPhoneAuth || firebaseUser == null) {
      final localUser = currentUserProfile;
      if (localUser == null) {
        return;
      }

      try {
        final storedUser = await _userFirestoreService.getUserById(localUser.id);
        _setCurrentUserProfile(storedUser ?? localUser);
      } catch (_) {
        _setCurrentUserProfile(localUser);
      }
      update();
      return;
    }

    final userProfile = await _userFirestoreService.getUserById(firebaseUser.uid);
    if (userProfile == null) {
      return;
    }

    _setCurrentUserProfile(userProfile);
    update();
  }

  Future<void> logout() async {
    await _safeSignOut();
    _clearLocalSession();
    update();
    Get.offAllNamed('/login');
  }

  void clearFeedback() {
    if (errorMessage == null && infoMessage == null) {
      return;
    }
    errorMessage = null;
    infoMessage = null;
    update();
  }

  Future<void> _handleSuccessfulSignIn(
    User? firebaseUser, {
    String? fallbackPhoneNumber,
  }) async {
    final userProfile = await _ensureUserDocument(
      firebaseUser,
      fallbackPhoneNumber: fallbackPhoneNumber,
    );

    isSendingOtp = false;
    isVerifyingOtp = false;
    errorMessage = null;
    infoMessage = null;
    update();

    if (userProfile.hasLocation) {
      Get.offAllNamed('/home');
      return;
    }

    Get.offAllNamed('/select_location');
  }

  Future<AppUserModel> _ensureUserDocument(
    User? firebaseUser, {
    String? fallbackPhoneNumber,
  }) async {
    if (_bypassPhoneAuth) {
      return _ensureLocalUserDocument(
        fallbackPhoneNumber: fallbackPhoneNumber,
      );
    }

    if (firebaseUser == null) {
      throw StateError('Unable to find the signed-in user.');
    }

    final resolvedPhoneNumber = _resolveStoredPhoneNumber(
      authPhoneNumber: firebaseUser.phoneNumber,
      fallbackPhoneNumber: fallbackPhoneNumber ?? phoneNumber,
    );

    final userProfile = await _userFirestoreService.ensureUser(
      userId: firebaseUser.uid,
      phoneNumber: resolvedPhoneNumber,
    );

    _setCurrentUserProfile(userProfile);
    update();

    return userProfile;
  }

  Future<void> _persistLocationForCurrentUser(UserLocationModel location) async {
    final firebaseUser = _authService.currentUser;
    if (_bypassPhoneAuth || firebaseUser == null) {
      final localUser = await _ensureLocalUserDocument(
        fallbackPhoneNumber: phoneNumber,
      );
      try {
        final updatedUser = await _userFirestoreService.updateLocation(
          userId: localUser.id,
          location: location,
        );
        _setCurrentUserProfile(updatedUser);
      } catch (_) {
        _setCurrentUserProfile(
          localUser.copyWith(
            location: location,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return;
    }

    final updatedUser = await _userFirestoreService.updateLocation(
      userId: firebaseUser.uid,
      location: location,
    );

    _setCurrentUserProfile(updatedUser);
  }

  Future<UserLocationModel> _resolveSelectedLocation(
    PlaceSuggestion suggestion,
  ) async {
    if (suggestion.latitude != null && suggestion.longitude != null) {
      return UserLocationModel(
        address: suggestion.address ?? suggestion.description,
        latitude: suggestion.latitude!,
        longitude: suggestion.longitude!,
        label: suggestion.title,
      );
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': suggestion.placeId,
        'fields': 'formatted_address,geometry/location,name',
        'key': AppConfig.googlePlacesApiKey,
        'language': 'en',
        'sessiontoken': _placeSearchSessionToken,
      },
    );

    final response = await _connect.get(uri.toString());
    final body = response.body;
    if (!response.isOk || body is! Map) {
      throw Exception('Unable to fetch place details.');
    }

    final responseMap = Map<String, dynamic>.from(body);
    final status = responseMap['status']?.toString() ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      final apiErrorMessage = responseMap['error_message']?.toString();
      throw Exception(
        apiErrorMessage?.isNotEmpty == true ? apiErrorMessage : 'Google Places returned $status.',
      );
    }

    final result = responseMap['result'];
    if (result is! Map) {
      throw Exception('Place details are missing.');
    }

    final resultMap = Map<String, dynamic>.from(result);
    final geometry = resultMap['geometry'];
    final locationMap =
        geometry is Map ? Map<String, dynamic>.from(geometry['location'] as Map? ?? {}) : <String, dynamic>{};

    final latitude = (locationMap['lat'] as num?)?.toDouble();
    final longitude = (locationMap['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw Exception('Unable to read the selected place coordinates.');
    }

    return UserLocationModel(
      address: resultMap['formatted_address']?.toString() ?? suggestion.address ?? suggestion.description,
      latitude: latitude,
      longitude: longitude,
      label: resultMap['name']?.toString() ?? suggestion.title,
    );
  }

  void _syncProfileControllers(AppUserModel userProfile) {
    fullNameController.text = userProfile.fullName;
    emailController.text = userProfile.email;
    registeredMobileNumberController.text =
        userProfile.registeredMobileNumber.isNotEmpty ? userProfile.registeredMobileNumber : userProfile.phoneNumber;
  }

  void _setCurrentUserProfile(AppUserModel userProfile) {
    currentUserProfile = userProfile;
    phoneNumber = userProfile.phoneNumber;
    _syncProfileControllers(userProfile);
  }

  AppUserModel _createOrUpdateLocalSession({
    String? fallbackPhoneNumber,
  }) {
    final resolvedPhoneNumber = _resolveStoredPhoneNumber(
      fallbackPhoneNumber: fallbackPhoneNumber ?? phoneNumber,
    );

    if (resolvedPhoneNumber.trim().isEmpty) {
      throw StateError('Unable to continue without a valid phone number.');
    }

    final existingUser = currentUserProfile;
    final updatedUser = AppUserModel(
      id: existingUser?.id ?? _localUserIdFromPhoneNumber(resolvedPhoneNumber),
      phoneNumber: resolvedPhoneNumber,
      fullName: existingUser?.fullName ?? '',
      email: existingUser?.email ?? '',
      registeredMobileNumber: existingUser?.registeredMobileNumber.isNotEmpty == true
          ? existingUser!.registeredMobileNumber
          : resolvedPhoneNumber,
      photoUrl: existingUser?.photoUrl ?? '',
      location: existingUser?.location,
      createdAt: existingUser?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _setCurrentUserProfile(updatedUser);
    return updatedUser;
  }

  Future<AppUserModel> _ensureLocalUserDocument({
    String? fallbackPhoneNumber,
  }) async {
    final localUser = _createOrUpdateLocalSession(
      fallbackPhoneNumber: fallbackPhoneNumber,
    );

    try {
      final persistedUser = await _userFirestoreService.ensureUser(
        userId: localUser.id,
        phoneNumber: localUser.phoneNumber,
      );

      final mergedUser = persistedUser.copyWith(
        fullName: localUser.fullName,
        email: localUser.email,
        registeredMobileNumber: localUser.registeredMobileNumber,
        photoUrl: localUser.photoUrl,
        location: localUser.location ?? persistedUser.location,
        createdAt: persistedUser.createdAt ?? localUser.createdAt,
        updatedAt: persistedUser.updatedAt ?? localUser.updatedAt,
      );

      _setCurrentUserProfile(mergedUser);
      return mergedUser;
    } catch (_) {
      return localUser;
    }
  }

  void _clearLocalSession() {
    verificationId = null;
    resendToken = null;
    phoneNumber = null;
    errorMessage = null;
    infoMessage = null;
    currentUserProfile = null;
    selectedPlace = null;
    placeSuggestions = [];
    placeSearchError = null;
    placeSearchInfo = 'Type at least 2 characters to search.';
    isSendingOtp = false;
    isVerifyingOtp = false;
    isSavingProfile = false;
    isSavingLocation = false;
    isFetchingCurrentLocation = false;
    isSearchingPlaces = false;
    phoneController.clear();
    fullNameController.clear();
    emailController.clear();
    registeredMobileNumberController.clear();
    locationSearchController.clear();
    _clearOtpFields();
  }

  Future<void> _safeSignOut() async {
    try {
      await _authService.signOut();
    } catch (_) {
      // Ignore sign-out issues while clearing local session state.
    }
  }

  void _clearOtpFields() {
    for (final controller in otpControllers) {
      controller.clear();
    }
  }

  bool _ensureFirebaseConfigured() {
    if (_authService.isConfigured) {
      return true;
    }
    _setError(
      'Firebase is not configured yet. Create a Firebase project, then run flutterfire configure.',
    );
    return false;
  }

  void _setError(String message) {
    errorMessage = message;
    infoMessage = null;
    update();
    _showSnackbar(
      title: 'Something went wrong',
      message: message,
      backgroundColor: const Color(0xFFC62828),
    );
  }

  void _setFirebaseError(
    FirebaseAuthException exception, {
    required String fallback,
  }) {
    _setError(
      _friendlyFirebaseMessage(
        code: exception.code,
        message: exception.message,
        fallback: fallback,
      ),
    );
  }

  void _showInfo(String message) {
    errorMessage = null;
    infoMessage = message;
    update();
    _showSnackbar(
      title: 'Success',
      message: message,
      backgroundColor: const Color(0xFF2E7D32),
    );
  }

  void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    AppSnackbar.show(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
    );
  }

  String _friendlyFirebaseMessage({
    String? code,
    String? message,
    required String fallback,
  }) {
    final normalizedCode = code?.toLowerCase() ?? '';
    final normalizedMessage = message?.toLowerCase() ?? '';

    if (normalizedMessage.contains('billing_not_enabled')) {
      return 'Phone verification is not available right now. Please try again later.';
    }
    if (normalizedCode == 'invalid-phone-number') {
      return 'Enter a valid phone number.';
    }
    if (normalizedCode == 'too-many-requests' || normalizedCode == 'quota-exceeded') {
      return 'Too many attempts. Please wait a bit and try again.';
    }
    if (normalizedCode == 'invalid-verification-code') {
      return 'Invalid OTP. Please try again.';
    }
    if (normalizedCode == 'session-expired') {
      return 'OTP expired. Please request a new OTP.';
    }
    if (normalizedCode == 'network-request-failed') {
      return 'Check your internet connection and try again.';
    }
    if (normalizedMessage.contains('internal error')) {
      return fallback;
    }

    return fallback;
  }

  String? _formatPhoneNumber(String rawPhoneNumber) {
    final digitsOnly = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 10) {
      return digitsOnly;
    }
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return digitsOnly.substring(2);
    }
    return null;
  }

  String? _formatPhoneNumberForAuth(String rawPhoneNumber) {
    final formattedPhoneNumber = _formatPhoneNumber(rawPhoneNumber);
    if (formattedPhoneNumber == null) {
      return null;
    }
    return '+91$formattedPhoneNumber';
  }

  String? _formatOptionalPhoneNumber(String rawPhoneNumber) {
    if (rawPhoneNumber.trim().isEmpty) {
      return '';
    }
    return _formatPhoneNumber(rawPhoneNumber);
  }

  String _resolveStoredPhoneNumber({
    String? authPhoneNumber,
    String? fallbackPhoneNumber,
  }) {
    final formattedAuthPhone = _formatPhoneNumber(authPhoneNumber ?? '');
    if (formattedAuthPhone != null) {
      return formattedAuthPhone;
    }

    final formattedFallback = _formatPhoneNumber(fallbackPhoneNumber ?? '');
    if (formattedFallback != null) {
      return formattedFallback;
    }

    return (fallbackPhoneNumber ?? '').trim();
  }

  static String _createPlaceSearchSessionToken() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static String _joinAddressParts(List<String?> parts) {
    return parts.whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).toSet().join(', ');
  }

  static String _localUserIdFromPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return 'local_$digitsOnly';
  }
}
