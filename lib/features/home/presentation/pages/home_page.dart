import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';
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
                      const SizedBox(height: 24),

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
                            _buildBikeCard(),
                            _buildBikeCard(),
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
                            _buildBikeCard(),
                            _buildBikeCard(),
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A6CAD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bike, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Bikenest',
                    style:
                        TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ],
              ),
              const Spacer(),
              // _buildHeaderIcon(Icons.notifications_none_outlined, badge: true),
              // _buildHeaderIcon(Icons.chat_bubble_outline),
              // _buildHeaderIcon(Icons.favorite_border),
              Image.asset('assets/images/Group 1171278003.png', height: 18, width: 18),
              const SizedBox(width: 12),
              Image.asset('assets/images/Vector (1).png', height: 18, width: 18),
              const SizedBox(width: 12),
              Image.asset('assets/images/Vector (2).png', height: 18, width: 18),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('assets/profile_pic.png'),
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
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'search',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
        ),
        const Text(
          'View All',
          style: TextStyle(color: Color(0xFF3E4E6C), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, String imagePath, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/select_category');
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
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E3E5C))),
          ],
        ),
      ),
    );
  }

  Widget _buildBikeCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/bike_detail');
      },
      child: Container(
        width: 176,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bike Image
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(
                      'assets/images/bike.png',
                      height: 60,
                      width: double.infinity,
                      // fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 110,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2021 Royal Enfield Hunter 350',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3E5C)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoTag('15,000 km'),
                      const SizedBox(width: 4),
                      _buildInfoTag('Petrol'),
                      const SizedBox(width: 4),
                      _buildInfoTag('350cc'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text('Madhya Pradesh 458468', style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '₹1.85 Lakh',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF233A66)),
                      ),
                      Text('10 days ago', style: TextStyle(color: Colors.grey.shade400, fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 8, fontWeight: FontWeight.w500)),
    );
  }
}
