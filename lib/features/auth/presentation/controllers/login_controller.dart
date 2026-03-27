import 'dart:async';

import 'package:bikebooking/core/constants/global.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bikebooking/features/auth/data/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String placeId;
  final String title;
  final String subtitle;
  final String description;

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
    );
  }
}

class LoginController extends GetxController {
  LoginController(this._authService);

  final FirebaseAuthService _authService;
  final GetConnect _connect = GetConnect();
  static const int _minimumPlaceSearchLength = 2;
  static const bool _bypassPhoneAuth = true;

  final TextEditingController phoneController = TextEditingController();
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
  String? verificationId;
  int? resendToken;
  String? phoneNumber;
  String? errorMessage;
  String? infoMessage;
  bool isSearchingPlaces = false;
  bool isFetchingCurrentLocation = false;
  String? placeSearchError;
  String? placeSearchInfo = 'Type at least 2 characters to search.';
  PlaceSuggestion? selectedPlace;
  List<PlaceSuggestion> placeSuggestions = [];

  Timer? _placeSearchDebounce;
  int _placeSearchRequestId = 0;
  String _placeSearchSessionToken = _createPlaceSearchSessionToken();

  String get otpCode => otpControllers.map((controller) => controller.text).join();

  @override
  void onClose() {
    phoneController.dispose();
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
      infoMessage = 'Demo mode: enter any 6 digits to continue.';
      update();
      if (Get.currentRoute != '/otp') {
        Get.toNamed('/otp', arguments: formattedPhoneNumber);
      }
      return;
    }

    isSendingOtp = true;
    phoneNumber = formattedPhoneNumber;
    update();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        forceResendingToken: resendToken,
        verificationCompleted: (credential) async {
          try {
            await _authService.signInWithCredential(credential);
            Get.offAllNamed('/select_location');
          } on FirebaseAuthException catch (exception) {
            _setFirebaseError(
              exception,
              fallback: 'Auto verification failed. Please enter the OTP manually.',
            );
          } on StateError catch (exception) {
            _setError(exception.message);
          } catch (_) {
            _setError('Auto verification failed. Please enter the OTP manually.');
          }
        },
        verificationFailed: (exception) {
          isSendingOtp = false;
          _setFirebaseError(exception, fallback: 'Unable to send OTP right now.');
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

    phoneController.text = phoneNumber!.replaceFirst('+91', '').trim();

    if (_bypassPhoneAuth) {
      isSendingOtp = false;
      errorMessage = null;
      infoMessage = 'Demo mode: enter any 6 digits to continue.';
      _clearOtpFields();
      update();
      return;
    }

    await sendOtp();
  }

  Future<void> verifyOtp() async {
    if (_bypassPhoneAuth) {
      if (otpCode.length != otpControllers.length) {
        _setError('Enter any 6 digits to continue.');
        return;
      }

      isVerifyingOtp = false;
      errorMessage = null;
      infoMessage = null;
      update();
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
      await _authService.signInWithOtp(
        verificationId: verificationId!,
        smsCode: otpCode,
      );
      isVerifyingOtp = false;
      update();
      Get.offAllNamed('/select_location');
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

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final title = _joinAddressParts([
        placemark?.locality,
        placemark?.subAdministrativeArea,
        placemark?.administrativeArea,
      ]);
      final description = _joinAddressParts([
        placemark?.street,
        placemark?.subLocality,
        placemark?.locality,
        placemark?.administrativeArea,
        placemark?.postalCode,
        placemark?.country,
      ]);

      final currentPlace = PlaceSuggestion(
        placeId: '${position.latitude},${position.longitude}',
        title: title.isNotEmpty ? title : 'Current Location',
        subtitle: description.isNotEmpty ? description : 'Current Location',
        description: description.isNotEmpty ? description : 'Current Location',
      );

      selectedPlace = currentPlace;
      locationSearchController.value = locationSearchController.value.copyWith(
        text: currentPlace.description,
        selection: TextSelection.collapsed(
          offset: currentPlace.description.length,
        ),
      );
      placeSuggestions = [];
      placeSearchInfo = 'Using your current location.';
      Get.offAllNamed('/home');
    } catch (error) {
      placeSearchError = error.toString().replaceFirst('Exception: ', '');
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
              (prediction) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(prediction)),
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
    selectedPlace = null;
    placeSuggestions = [];
    placeSearchError = null;
    placeSearchInfo = 'Type at least 2 characters to search.';
    locationSearchController.clear();
    update();
  }

  void confirmSelectedLocation() {
    if (selectedPlace == null) {
      placeSearchError = 'Select a place from the search results to continue.';
      update();
      return;
    }

    placeSearchError = null;
    update();
    Get.offAllNamed('/home');
  }

  void clearFeedback() {
    if (errorMessage == null && infoMessage == null) {
      return;
    }
    errorMessage = null;
    infoMessage = null;
    update();
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
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
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
      return '+91$digitsOnly';
    }
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }
    if (rawPhoneNumber.startsWith('+') && digitsOnly.length >= 10) {
      return '+$digitsOnly';
    }
    return null;
  }

  static String _createPlaceSearchSessionToken() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static String _joinAddressParts(List<String?> parts) {
    return parts.whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).toSet().join(', ');
  }
}
