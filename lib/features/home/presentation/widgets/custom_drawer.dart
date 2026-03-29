import 'package:bikebooking/core/widgets/app_snackbar.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_filter_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  static const List<_FuelFilterOption> _fuelOptions = <_FuelFilterOption>[
    _FuelFilterOption(
      label: 'Petrol\nBike',
      fuelType: 'Petrol',
      color: Color(0xFFD4E7C5),
      icon: Icons.local_gas_station,
    ),
    _FuelFilterOption(
      label: 'Electric\nBikes',
      fuelType: 'Electric',
      color: Color(0xFFFFD1A5),
      icon: Icons.bolt,
    ),
    _FuelFilterOption(
      label: 'CNG\nBikes',
      fuelType: 'CNG',
      color: Color(0xFFC9C9EB),
      icon: Icons.directions_bus,
    ),
    _FuelFilterOption(
      label: 'Hybrid\nBikes',
      fuelType: 'Hybrid',
      color: Color(0xFFB9E5F3),
      icon: Icons.eco,
    ),
  ];

  static const List<_BodyTypeOption> _bodyTypeOptions = <_BodyTypeOption>[
    _BodyTypeOption(
      label: 'Sport',
      category: 'Sports Bikes',
      icon: Icons.sports_motorsports_rounded,
    ),
    _BodyTypeOption(
      label: 'Cruiser',
      category: 'Cruiser Bikes',
      icon: Icons.two_wheeler_rounded,
    ),
    _BodyTypeOption(
      label: 'Electric',
      category: 'Electric Bikes',
      icon: Icons.electric_bike_rounded,
    ),
    _BodyTypeOption(
      label: 'Adventure',
      category: 'Adventure Bikes',
      icon: Icons.terrain_rounded,
    ),
  ];

  static const List<_SocialLinkOption> _socialLinks = <_SocialLinkOption>[
    _SocialLinkOption(
      icon: Icons.facebook,
      label: 'Facebook',
      url: 'https://www.facebook.com/',
    ),
    _SocialLinkOption(
      icon: Icons.alternate_email,
      label: 'X',
      url: 'https://x.com/',
    ),
    _SocialLinkOption(
      icon: Icons.camera_alt_outlined,
      label: 'Instagram',
      url: 'https://www.instagram.com/',
    ),
    _SocialLinkOption(
      icon: Icons.business_center_outlined,
      label: 'LinkedIn',
      url: 'https://www.linkedin.com/',
    ),
    _SocialLinkOption(
      icon: Icons.play_circle_outline,
      label: 'YouTube',
      url: 'https://www.youtube.com/',
    ),
  ];

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
                      children: _fuelOptions
                          .map(
                            (option) => _buildFuelTypeCard(
                              context,
                              option,
                            ),
                          )
                          .toList(growable: false),
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
                      children: _bodyTypeOptions
                          .map(
                            (option) => _buildBodyTypeItem(
                              context,
                              option,
                            ),
                          )
                          .toList(growable: false),
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
                      isSelected: currentRoute == '/subscription_status',
                      onTap: () =>
                          _navigateToRoute(context, '/subscription_status'),
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.logout,
                      'Logout',
                      onTap: () => _showLogoutConfirmation(context, controller),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect with us',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: _socialLinks
                          .map(
                            (option) => _buildSocialIcon(
                              context,
                              option,
                            ),
                          )
                          .toList(growable: false),
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

  void _openFilteredResults(
    BuildContext context,
    ProductFilterState filters,
  ) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/filter_result', arguments: filters);
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    Navigator.pop(context);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppSnackbar.show(
        title: 'Unable to Open Link',
        message: 'This social media link could not be opened on this device.',
        backgroundColor: const Color(0xFFC62828),
      );
    }
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

  Widget _buildFuelTypeCard(
    BuildContext context,
    _FuelFilterOption option,
  ) {
    return GestureDetector(
      onTap: () => _openFilteredResults(
        context,
        ProductFilterState(
          category: 'Bikes',
          selectedFuelType: option.fuelType,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: option.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              option.icon,
              color: Colors.green.shade800,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            option.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E3E5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTypeItem(
    BuildContext context,
    _BodyTypeOption option,
  ) {
    return GestureDetector(
      onTap: () => _openFilteredResults(
        context,
        ProductFilterState(category: option.category),
      ),
      child: Column(
        children: [
          Icon(
            option.icon,
            color: const Color(0xFF2E3E5C),
            size: 32,
          ),
          const SizedBox(height: 6),
          Text(
            option.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E3E5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(
    BuildContext context,
    _SocialLinkOption option,
  ) {
    return Tooltip(
      message: option.label,
      child: GestureDetector(
        onTap: () => _openExternalUrl(context, option.url),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(
            option.icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
  void _showLogoutConfirmation(BuildContext context, LoginController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 44,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEE8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.logout_rounded,
                      size: 90,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to logout? You will need to login again to access your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.pop(context); // Close drawer
                          await controller.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF233A66),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FuelFilterOption {
  const _FuelFilterOption({
    required this.label,
    required this.fuelType,
    required this.color,
    required this.icon,
  });

  final String label;
  final String fuelType;
  final Color color;
  final IconData icon;
}

class _BodyTypeOption {
  const _BodyTypeOption({
    required this.label,
    required this.category,
    required this.icon,
  });

  final String label;
  final String category;
  final IconData icon;
}

class _SocialLinkOption {
  const _SocialLinkOption({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;
}
