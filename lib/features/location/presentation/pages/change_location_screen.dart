import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/location/presentation/widgets/location_option_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangeLocationScreen extends StatelessWidget {
  const ChangeLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Location',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GetBuilder<LoginController>(
        builder: (controller) {
          final currentAddress =
              controller.currentUserProfile?.location?.address.trim() ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Column(
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/location_illustration2.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Update Your Location',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you would like to change your current location.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (currentAddress.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE3E6EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8EEF7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current saved location',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E3E5C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                LocationOptionCard(
                  title: controller.isFetchingCurrentLocation
                      ? 'Detecting Current Location...'
                      : controller.isSavingLocation
                          ? 'Saving Location...'
                          : 'Use Current Location',
                  subtitle: 'Enable GPS to detect your location',
                  onTap: controller.isFetchingCurrentLocation ||
                          controller.isSavingLocation
                      ? null
                      : () => _handleUseCurrentLocation(context, controller),
                  leading: Image.asset(
                    'assets/images/currentLocation.png',
                    height: 35,
                    width: 35,
                  ),
                ),
                // const SizedBox(height: 16),
                // LocationOptionCard(
                //   title: 'Choose Location',
                //   subtitle: 'Search and select from available locations',
                //   onTap: controller.isSavingLocation
                //       ? null
                //       : () => _handleChooseLocation(context),
                //   leading: Image.asset(
                //     'assets/images/currentLocation2.png',
                //     height: 18,
                //     width: 25,
                //   ),
                // ),
                const SizedBox(height: 16),
                LocationOptionCard(
                  title: 'Choose Location',
                  subtitle: 'Select state, city and area',
                  onTap: controller.isSavingLocation
                      ? null
                      : () => _handleChooseLocationManually(context),
                  leading: const Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleUseCurrentLocation(
    BuildContext context,
    LoginController controller,
  ) async {
    final location = await controller.useCurrentLocation(
      navigateToHome: false,
      showSuccessSnackbar: true,
    );
    if (location != null && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  // Future<void> _handleChooseLocation(BuildContext context) async {
  //   final didSave = await Navigator.pushNamed(
  //     context,
  //     '/location_search',
  //     arguments: {'returnOnSave': true},
  //   );
  //
  //   if (didSave == true && context.mounted) {
  //     Navigator.pop(context, true);
  //   }
  // }

  Future<void> _handleChooseLocationManually(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/select_state');
    if (result != null && result is Map<String, dynamic> && context.mounted) {
      final displayAddress = result['displayAddress'] as String? ?? '';
      final latitude = (result['latitude'] as num?)?.toDouble();
      final longitude = (result['longitude'] as num?)?.toDouble();
      if (displayAddress.isNotEmpty) {
        final controller = Get.find<LoginController>();
        final saved = await controller.saveManualLocation(
          displayAddress,
          latitude: latitude,
          longitude: longitude,
        );
        if (saved && context.mounted) {
          Navigator.pop(context, true);
        }
      } else {
        Navigator.pop(context, true);
      }
    }
  }
}
