import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/location/presentation/widgets/location_option_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bikebooking/core/constants/global.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
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
          'Select Location',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GetBuilder<LoginController>(
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Center(
                child: Image.asset(
                  'assets/images/location_illustration2.png',
                  height: 210,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Select Your Location',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'How would you like to set your location',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 0,
                  bottom: 48,
                ),
                child: Column(
                  children: [
                    _buildLocationOption(
                      title: controller.isFetchingCurrentLocation
                          ? 'Detecting Current Location...'
                          : controller.isSavingLocation
                              ? 'Saving Location...'
                              : 'Use Current Location',
                      subtitle: 'Enable GPS to detect your location',
                      onTap: controller.isFetchingCurrentLocation ||
                              controller.isSavingLocation
                          ? null
                          : controller.useCurrentLocation,
                      leading: Image.asset(
                        'assets/images/currentLocation.png',
                        height: 35,
                        width: 35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationOption(
                      title: 'Add New Address',
                      subtitle: '',
                      onTap: controller.isSavingLocation
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/location_search');
                            },
                      leading: Image.asset(
                        'assets/images/currentLocation2.png',
                        height: 18,
                        width: 25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationOption(
                      title: 'Choose Location Manually',
                      subtitle: 'Select state, city and area',
                      onTap: () async {
                        print('DEBUG: Tapped Choose Location Manually');
                        print('DEBUG: Context is valid: ${context.mounted}');
                        print('DEBUG: Navigator state: ${Navigator.of(context).canPop}');
                        print('DEBUG: Navigating to /select_state');
                        try {
                          final result = await Navigator.pushNamed(context, '/select_state');
                          print('DEBUG: Navigation completed, result: $result');
                          if (result != null) {
                            // Handle the selected location
                            final locationData = result as Map<String, dynamic>;
                            // You can save this location or use it as needed
                            print('Selected location: ${locationData['displayAddress']}');
                          }
                        } catch (e) {
                          print('DEBUG: Navigation error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Navigation error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      leading: Icon(
                        Icons.location_city,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Simple test button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          print('DEBUG: RED BUTTON TAPPED - going to /select_state');
                          Navigator.pushNamed(context, '/select_state');
                        },
                        child: Text(
                          'TEST: Go to State Selection',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: AppColors.primary,
        onPressed: () {
          print('DEBUG: Direct navigation test - going to /select_state');
          Navigator.pushNamed(context, '/select_state');
        },
        child: const Icon(Icons.location_city, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationOption({
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Widget leading,
  }) {
    return LocationOptionCard(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      leading: leading,
    );
  }
}
