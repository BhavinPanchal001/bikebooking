import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';

class ListProductScreen extends StatelessWidget {
  const ListProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'List Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'List Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3E5C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.08,
                        children: [
                          _buildCategoryCard(
                            context,
                            'Bikes',
                            const Color(0xFFE2F2D5), // Light Green
                            'assets/images/bike_placeholder.png',
                          ),
                          _buildCategoryCard(
                            context,
                            'Scooter',
                            const Color(0xFFFFE0C2), // Light Peach
                            'assets/images/scooter_placeholder.png',
                          ),
                          _buildCategoryCard(
                            context,
                            'Accessories',
                            const Color(0xFFE2E2F8), // Light Purple
                            'assets/images/accessories_placeholder.png',
                          ),
                          _buildCategoryCard(
                            context,
                            'Spare Parts',
                            const Color(0xFFD9F2F9), // Light Blue
                            'assets/images/spare_parts_placeholder.png',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, Color bgColor, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product_images', arguments: title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        _getIconForCategory(title),
                        size: 40,
                        color: Colors.black.withOpacity(0.2),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF121926),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String title) {
    switch (title) {
      case 'Bikes':
        return Icons.directions_bike;
      case 'Scooter':
        return Icons.moped;
      case 'Accessories':
        return Icons.shopping_bag;
      case 'Spare Parts':
        return Icons.settings;
      default:
        return Icons.category;
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2, // Sell is selected
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else if (index == 1) {
            Navigator.pushNamed(context, '/filter_result', arguments: 'Bikes');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/my_listing');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/profile_overview');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF233A66),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24), activeIcon: Icon(Icons.home, size: 24), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike_outlined, size: 24), label: 'Buy'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 24), label: 'Sell'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border, size: 24), label: 'My Post'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 24), label: 'Profile'),
        ],
      ),
    );
  }
}
