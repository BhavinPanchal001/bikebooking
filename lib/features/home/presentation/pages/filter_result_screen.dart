import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';

class FilterResultScreen extends StatelessWidget {
  const FilterResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = ModalRoute.of(context)?.settings.arguments as String? ?? 'Accessories';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Banner & Search
            Container(
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    category == 'Accessories'
                        ? 'Accessories'
                        : category == 'Spare Parts'
                            ? 'Spare Parts'
                            : 'Motorcycles',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 43,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/Group 1171276172.png',
                                height: 15,
                                width: 15,
                                errorBuilder: (c, e, s) => const Icon(Icons.search, size: 15, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'search',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/filter', arguments: category);
                        },
                        child: Container(
                          height: 43,
                          width: 43,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/Group.png',
                              height: 17,
                              width: 17,
                              errorBuilder: (c, e, s) => const Icon(Icons.tune, size: 17, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Chips Bar
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('Sort'),
                  _buildFilterChip('Brand', hasDropdown: true),
                  _buildFilterChip('Price', hasDropdown: true),
                  _buildFilterChip('Year', hasDropdown: true),
                ],
              ),
            ),

            // Result Count
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '83 Used bikes are available in Pune',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Result List
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: category == 'Accessories' ? 4 : 4,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final accessories = [
                    {
                      'name': 'Autosite Black Bike face mask',
                      'price': '₹1,085',
                      'image': 'assets/images/mask.png',
                    },
                    {
                      'name': 'Stylisty IND half Finger Anti- Slip...',
                      'price': '₹1,085',
                      'image': 'assets/images/gloves.png',
                    },
                    {
                      'name': 'Motard water H20 Hydration tactical...',
                      'price': '₹1,085',
                      'image': 'assets/images/bag.png',
                    },
                    {
                      'name': 'Probiker Racing equipment motorcy...',
                      'price': '₹1,085',
                      'image': 'assets/images/gloves_2.png',
                    },
                  ];

                  final spareParts = [
                    {
                      'name': 'Motorcycle Black Absorber',
                      'price': '₹1,085',
                      'image': 'assets/images/absorber.png',
                    },
                    {
                      'name': 'Pulsar - 150 cc Bajaj Engine',
                      'price': '₹1,085',
                      'image': 'assets/images/engine.png',
                    },
                    {
                      'name': 'Bike Motorcycle Chain and Sprocket...',
                      'price': '₹1,085',
                      'image': 'assets/images/chain.png',
                    },
                    {
                      'name': 'Maxbell Motorcycle LCD Digital Dashboa...',
                      'price': '₹1,085',
                      'image': 'assets/images/dashboard.png',
                    },
                  ];

                  final items = category == 'Accessories' ? accessories : spareParts;
                  return _buildItemCard(
                    items[index]['name']!,
                    items[index]['price']!,
                    items[index]['image']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
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
        currentIndex: 1, // Buy is selected
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else if (index == 2) {
            Navigator.pushNamed(context, '/list_product');
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
    );
  }

  Widget _buildFilterChip(String label, {bool hasDropdown = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(String name, String price, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accessory Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag, color: Colors.grey, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Accessory Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0C0E1B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/images/Path 3392.png', height: 14, width: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoTag('New'),
                      const SizedBox(width: 4),
                      _buildInfoTag('Dealer'),
                      const SizedBox(width: 4),
                      _buildInfoTag('2023'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text(
                        'Madhya Pradesh 458468',
                        style: const TextStyle(color: Color(0xFF262A36), fontSize: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2E4475)),
                      ),
                      Text('10 days ago', style: TextStyle(color: Color(0xFF9F9F9F), fontSize: 9)),
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
      child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.w500)),
    );
  }
}
