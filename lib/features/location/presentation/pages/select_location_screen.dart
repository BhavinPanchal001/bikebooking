import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bikebooking/core/constants/global.dart';

class SelectLocationScreen extends StatelessWidget {
  const SelectLocationScreen({super.key});

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          // Illustration center
          Container(
            // color: Colors.red,
            child: Center(
              child: Image.asset(
                'assets/images/location_illustration2.png',
                height: 210,
                fit: BoxFit.contain,
              ),
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
          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 48),
            child: Column(
              children: [
                _buildLocationOption(
                  context,
                  icon: Icons.my_location,
                  title: 'Use Current Location',
                  subtitle: 'Enable GPS to detect your location',
                  onTap: () {
                    Navigator.pushNamed(context, '/location_search');
                  },
                  leading: Image.asset(
                    'assets/images/currentLocation.png',
                    height: 35,
                    width: 35,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLocationOption(
                  context,
                  icon: Icons.add,
                  title: 'Add New Address',
                  subtitle: '',
                  onTap: () {
                    // Navigate to add address
                  },
                  leading: Image.asset(
                    'assets/images/currentLocation2.png',
                    height: 18,
                    width: 25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Widget leading,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Custom Leading
              leading,
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
