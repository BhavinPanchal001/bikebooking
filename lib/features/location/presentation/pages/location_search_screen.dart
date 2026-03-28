import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bikebooking/core/constants/global.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final LoginController _loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    _loginController.initializeLocationSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Lighter premium grey background
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
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: TextField(
                    controller: controller.locationSearchController,
                    onChanged: controller.updateLocationQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search for area, city or address',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF5A739C),
                      ),
                      suffixIcon:
                          controller.locationSearchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: controller.clearLocationSearch,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              if (controller.placeSearchError != null ||
                  controller.placeSearchInfo != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.placeSearchError ??
                          controller.placeSearchInfo!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: controller.placeSearchError != null
                            ? Colors.red.shade700
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchResults(controller),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A5F82), Color(0xFF344867)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: controller.isSavingLocation
                        ? null
                        : controller.confirmSelectedLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      controller.isSavingLocation
                          ? 'Saving Location...'
                          : 'Confirm Location',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(LoginController controller) {
    if (controller.isSearchingPlaces && controller.placeSuggestions.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final children = <Widget>[];

    if (controller.selectedPlace != null) {
      children.add(
        _buildLocationCard(
          title: controller.selectedPlace!.title,
          subtitle: controller.selectedPlace!.description,
          isSelected: true,
          onTap: () =>
              controller.selectPlaceSuggestion(controller.selectedPlace!),
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    if (controller.placeSuggestions.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Text(
            controller.selectedPlace != null
                ? 'Tap confirm to continue with the selected place.'
                : 'Search places using the Google Places API.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    } else {
      for (final suggestion in controller.placeSuggestions) {
        children.add(
          _buildLocationCard(
            title: suggestion.title,
            subtitle: suggestion.description,
            onTap: () => controller.selectPlaceSuggestion(suggestion),
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    return ListView(
      children: children,
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEBEEF2),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFDDE3EB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.location_on_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
