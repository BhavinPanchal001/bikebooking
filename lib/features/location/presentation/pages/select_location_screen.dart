import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectLocationScreen extends StatelessWidget {
  const SelectLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Illustration center
          Center(
            child: Image.asset(
              'assets/images/location_illustration.png',
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Select Your Location',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How would you like to set your location',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF1A3D6B)),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
