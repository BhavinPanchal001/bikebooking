import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return GetBuilder<LoginController>(
      builder: (controller) {
        final displayName =
            controller.currentUserProfile?.displayName ?? 'Hello';
        final initial = displayName.isNotEmpty
            ? displayName.characters.first.toUpperCase()
            : 'U';

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.8,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E3E5C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello,',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4ADE80),
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),

              // Scrollable List Content
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDrawerItem(
                      context,
                      Icons.home_outlined,
                      'Home',
                      isSelected: currentRoute == '/home',
                      onTap: () => _navigateToRoute(context, '/home'),
                    ),
                    const Divider(),
                    _buildDrawerItem(
                      context,
                      Icons.directions_bike,
                      'Buy bike',
                      isSelected: currentRoute == '/search',
                      onTap: () => _navigateToRoute(context, '/search'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'By fuel type',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFuelTypeCard('Petrol\nBike',
                            const Color(0xFFD4E7C5), Icons.local_gas_station),
                        _buildFuelTypeCard('Electric\nBikes',
                            const Color(0xFFFFD1A5), Icons.bolt),
                        _buildFuelTypeCard('CNG\nBikes',
                            const Color(0xFFC9C9EB), Icons.directions_bus),
                        _buildFuelTypeCard('Hybrid\nBikes',
                            const Color(0xFFB9E5F3), Icons.eco),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'By body type',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBodyTypeItem('Sport'),
                        _buildBodyTypeItem('Cruiser'),
                        _buildBodyTypeItem('Electric'),
                        _buildBodyTypeItem('Adventure'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    _buildDrawerItem(
                      context,
                      Icons.directions_bike_outlined,
                      'Sell bike',
                      isSelected: currentRoute == '/list_product',
                      onTap: () => _navigateToRoute(context, '/list_product'),
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.favorite_border,
                      'My Favorites',
                      isSelected: currentRoute == '/favorites',
                      onTap: () => _navigateToRoute(context, '/favorites'),
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.add_circle_outline,
                      'My Post',
                      isSelected: currentRoute == '/my_listing',
                      onTap: () => _navigateToRoute(context, '/my_listing'),
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.verified_user_outlined,
                      'Subscription status',
                      isSelected: currentRoute == '/profile_overview',
                      onTap: () =>
                          _navigateToRoute(context, '/profile_overview'),
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.logout,
                      'Logout',
                      onTap: () async {
                        Navigator.pop(context);
                        await controller.logout();
                      },
                    ),
                    const Divider(),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect with us',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSocialIcon(Icons.facebook),
                        _buildSocialIcon(Icons.close),
                        _buildSocialIcon(Icons.camera_alt_outlined),
                        _buildSocialIcon(Icons.business_center_outlined),
                        _buildSocialIcon(Icons.play_circle_outline),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToRoute(BuildContext context, String routeName) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    Navigator.pop(context);

    if (currentRoute == routeName) {
      return;
    }

    Navigator.pushNamed(context, routeName);
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2E3E5C).withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2E3E5C), size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF2E3E5C),
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: const VisualDensity(vertical: -2),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFuelTypeCard(String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: Colors.green.shade800,
              size: 28), // Simplified icons for fuel
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E3E5C)),
        ),
      ],
    );
  }

  Widget _buildBodyTypeItem(String label) {
    return Column(
      children: [
        const Icon(Icons.directions_bike,
            color: Color(0xFF2E3E5C), size: 32), // Silhouette placeholder
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E3E5C)),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 18, color: Colors.grey.shade600),
    );
  }
}
