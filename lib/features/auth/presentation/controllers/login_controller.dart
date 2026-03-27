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
  String? errorMessage;
  String? infoMessage;

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
    if (errorMessage != null) {
      errorMessage = null;
    }
    phoneController.value = phoneController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    update();
  }

  void initializeOtp(String incomingPhoneNumber) {
    phoneNumber ??= incomingPhoneNumber;
    if (errorMessage != null) {
      errorMessage = null;
      update();
    }
  }

  void updateOtpDigit(int index, String value) {
    final sanitizedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    otpControllers[index].value = otpControllers[index].value.copyWith(
      text: sanitizedValue,
      selection: TextSelection.collapsed(offset: sanitizedValue.length),
    );

    if (errorMessage != null) {
      errorMessage = null;
    }

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

    isSendingOtp = true;
    errorMessage = null;
    infoMessage = null;
    phoneNumber = formattedPhoneNumber;
    update();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        forceResendingToken: resendToken,
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            Get.offAllNamed('/select_location');
          } on FirebaseAuthException catch (exception) {
            _setError(exception.message ?? 'Auto verification failed.');
          } catch (_) {
            _setError('Auto verification failed. Please enter the OTP manually.');
          }
        },
        verificationFailed: (exception) {
          isSendingOtp = false;
          _setError(exception.message ?? 'Unable to send OTP right now.');
        },
        codeSent: (receivedVerificationId, receivedResendToken) {
          verificationId = receivedVerificationId;
          resendToken = receivedResendToken;
          isSendingOtp = false;
          _clearOtpFields();
          infoMessage = 'OTP sent successfully.';
          update();
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
      _setError(exception.message ?? 'Unable to send OTP right now.');
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

    isVerifyingOtp = true;
    errorMessage = null;
    infoMessage = null;
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
      _setError(exception.message ?? 'Invalid OTP. Please try again.');
    } catch (_) {
      isVerifyingOtp = false;
      _setError('OTP verification failed. Please try again.');
    }
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

  void _setError(String message) {
    errorMessage = message;
    infoMessage = null;
    update();
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
