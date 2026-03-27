import 'package:bikebooking/features/auth/data/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  LoginController(this._authService);

  final FirebaseAuthService _authService;

  final TextEditingController phoneController = TextEditingController();
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

  String get otpCode => otpControllers.map((controller) => controller.text).join();

  @override
  void onClose() {
    phoneController.dispose();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
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

    if (!_ensureFirebaseConfigured()) {
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
    await sendOtp();
  }

  Future<void> verifyOtp() async {
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
}
