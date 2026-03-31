import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
        final photoUrl = controller.currentUserProfile?.photoUrl.trim() ?? '';
        final savedLocation =
            controller.currentUserProfile?.location?.address ?? '';
        final registeredMobileNumber = controller
                    .currentUserProfile?.registeredMobileNumber
                    .trim()
                    .isNotEmpty ==
                true
            ? controller.currentUserProfile!.registeredMobileNumber.trim()
            : controller.currentUserProfile?.phoneNumber ?? '';

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
                              _buildProfileAvatar(
                                avatarLabel: avatarLabel,
                                photoUrl: photoUrl,
                                isUploading: controller.isUploadingProfilePhoto,
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: controller.isUploadingProfilePhoto
                                      ? null
                                      : () => _showPhotoSourceBottomSheet(
                                            context,
                                            controller,
                                          ),
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF233A66),
                                      shape: BoxShape.circle,
                                    ),
                                    child: controller.isUploadingProfilePhoto
                                        ? const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap the camera icon to change your profile photo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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
                          _buildLabel('Registered Mobile Number'),
                          _buildTextField(
                            initialValue: registeredMobileNumber,
                            hint: 'Registered mobile number',
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            readOnly: true,
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

  Widget _buildProfileAvatar({
    required String avatarLabel,
    required String photoUrl,
    required bool isUploading,
  }) {
    return Container(
      height: 130,
      width: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl.isNotEmpty)
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(avatarLabel),
              )
            else
              _buildAvatarFallback(avatarLabel),
            if (isUploading)
              Container(
                color: Colors.black.withOpacity(0.28),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String avatarLabel) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        avatarLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPhotoSourceBottomSheet(
    BuildContext context,
    LoginController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 44,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEE8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Text(
                  'Update Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to add your profile photo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPhotoSourceTile(
                  context: sheetContext,
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from gallery',
                  source: ImageSource.gallery,
                  controller: controller,
                ),
                const SizedBox(height: 12),
                _buildPhotoSourceTile(
                  context: sheetContext,
                  icon: Icons.photo_camera_outlined,
                  title: 'Take a photo',
                  source: ImageSource.camera,
                  controller: controller,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoSourceTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required ImageSource source,
    required LoginController controller,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        Navigator.pop(context);
        await controller.uploadProfilePhoto(source);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEF7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF233A66),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3E5C),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
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
