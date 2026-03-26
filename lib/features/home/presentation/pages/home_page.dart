import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';
import '../widgets/bike_card.dart';
import '../widgets/custom_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FBFF),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar & Search
            _buildTopBanner(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Promo Banner
                      _buildPromoBanner(),
                      const SizedBox(height: 15),

                      // Top Categories
                      _buildSectionHeader('Top Categories'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryItem('Bikes', 'assets/images/Group 1171278014.png', const Color(0xFFD4E7C5)),
                            _buildCategoryItem(
                                'Scooter', 'assets/images/Group 1171278014.png', const Color(0xFFFFD1A5)),
                            _buildCategoryItem(
                                'Accessories', 'assets/images/Group 1171278014.png', const Color(0xFFC9C9EB)),
                            _buildCategoryItem(
                                'Spare Parts', 'assets/images/Group 1171278014.png', const Color(0xFFB9E5F3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Recently Viewed Items
                      _buildSectionHeader('Recently Viewed Items'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            const BikeCard(),
                            const BikeCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Just Added
                      _buildSectionHeader('Just Added'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            const BikeCard(),
                            const BikeCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 1) {
              Navigator.pushNamed(context, '/filter_result', arguments: 'Bikes');
              return;
            } else if (index == 2) {
              Navigator.pushNamed(context, '/list_product');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/my_listing');
            } else if (index == 4) {
              Navigator.pushNamed(context, '/profile_overview');
            }
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF233A66),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 28), activeIcon: Icon(Icons.home, size: 28), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_bike_outlined, size: 28), label: 'Buy'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 28), label: 'Sell'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border, size: 28), label: 'My Post'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 28), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: const Icon(Icons.menu, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 8),
              // Placeholder for Bikenest Logo
              Row(
                children: [
                  Image.asset('assets/images/homebike.png', height: 25, width: 25),
                  const SizedBox(width: 1),
                  Image.asset('assets/images/bokenestimage.png', height: 30, width: 100),
                ],
              ),
              const Spacer(),
              // _buildHeaderIcon(Icons.notifications_none_outlined, badge: true),
              // _buildHeaderIcon(Icons.chat_bubble_outline),
              // _buildHeaderIcon(Icons.favorite_border),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Image.asset('assets/images/Group 1171278003.png', height: 20, width: 20),
              ),
              const SizedBox(width: 12),
              Image.asset('assets/images/Vector (1).png', height: 20, width: 20),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/favorites'),
                child: Image.asset('assets/images/Vector (2).png', height: 20, width: 20),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile_overview'),
                child: Container(
                  height: 34,
                  width: 34,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      'assets/images/profileimage.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/search');
            },
            child: Container(
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/Group 1171276172.png',
                    height: 15,
                    width: 15,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'search',
                    style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 15, fontFamily: 'Neue Montreal'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool badge = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Stack(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          if (badge)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 8,
                  minHeight: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset('assets/images/Group 1171278220.png', fit: BoxFit.cover),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'View All',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, String imagePath, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          if (title == 'Accessories' || title == 'Spare Parts') {
            Navigator.pushNamed(context, '/filter_result', arguments: title);
          } else if (title == 'Bikes') {
            Navigator.pushNamed(context, '/filter_result', arguments: 'Bikes');
          } else {
            Navigator.pushNamed(context, '/select_category');
          }
        },
        child: Column(
          children: [
            Container(
              width: 80,
              height: 90,
              // decoration: BoxDecoration(
              //   color: bgColor,
              //   borderRadius: BorderRadius.circular(16),
              // ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  height: 110,
                  fit: BoxFit.contain,
                  // errorBuilder: (c, e, s) => const Icon(Icons.category, color: Colors.white, size: 30),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF262A36))),
          ],
        ),
      ),
    );
  }

}
