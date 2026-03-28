import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      builder: (controller) {
        final displayName =
            controller.currentUserProfile?.displayName ?? 'User';
        final avatarLabel = displayName.isNotEmpty
            ? displayName.substring(0, 1).toUpperCase()
            : 'U';
        final savedLocation =
            controller.currentUserProfile?.location?.address ?? '';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 65,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 58,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    avatarLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF233A66),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          _buildLabel('Full Name'),
                          _buildTextField(
                            controller: controller.fullNameController,
                            hint: 'Full Name',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Phone Number'),
                          _buildTextField(
                            initialValue:
                                controller.currentUserProfile?.phoneNumber ??
                                    '',
                            hint: 'Phone Number',
                            prefixIcon: Icons.phone_outlined,
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Email Address'),
                          _buildTextField(
                            controller: controller.emailController,
                            hint: 'Enter your email',
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Register Mobile Number'),
                          _buildTextField(
                            controller:
                                controller.registeredMobileNumberController,
                            hint: 'Enter mobile number',
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Saved Address'),
                          _buildTextField(
                            initialValue: savedLocation,
                            hint: 'No location saved yet',
                            prefixIcon: Icons.location_on_outlined,
                            readOnly: true,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: CustomGradientButton(
              text:
                  controller.isSavingProfile ? 'Updating...' : 'Update Profile',
              onPressed: controller.isSavingProfile
                  ? () {}
                  : () async {
                      final saved = await controller.saveProfile();
                      if (saved && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF37474F),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String initialValue = '',
    required String hint,
    IconData? prefixIcon,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final decoration = InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFF233A66))
          : null,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: readOnly,
      fillColor: readOnly ? const Color(0xFFF1F4F8) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF233A66)),
      ),
    );

    if (controller != null) {
      return TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: decoration,
      );
    }

    return TextFormField(
      initialValue: initialValue,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: decoration,
    );
  }
}
