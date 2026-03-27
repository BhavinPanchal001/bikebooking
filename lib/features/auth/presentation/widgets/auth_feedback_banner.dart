import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthFeedbackBanner extends StatelessWidget {
  const AuthFeedbackBanner({
    super.key,
    this.errorMessage,
    this.infoMessage,
  });

  final String? errorMessage;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ?? infoMessage;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    final isError = errorMessage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
