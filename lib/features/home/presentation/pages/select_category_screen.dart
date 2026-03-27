import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';

class SelectCategoryScreen extends StatelessWidget {
  const SelectCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section with Search
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
                  const Text(
                    'Select Categories',
                    style: TextStyle(
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
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/search'),
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
                      ),
                      const SizedBox(width: 12),
                      // Filter Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/filter');
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
                              ),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            // Category List
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bike',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF262A36),
                        ),
                      ),
                      const SizedBox(height: 5),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.82,
                        children: [
                          _buildCategoryCard(
                              context, 'Sports Bikes', '76 Products', 'assets/sports_bike.png', const Color(0xFFD4E7C5)),
                          _buildCategoryCard(
                              context, 'Cruiser Bikes', '56 Products', 'assets/cruiser_bike.png', const Color(0xFFFFD1A5)),
                          _buildCategoryCard(
                              context, 'Commuter Bikes', '98 Products', 'assets/commuter_bike.png', const Color(0xFFC9C9EB)),
                          _buildCategoryCard(
                              context, 'Adventure Bikes', '45 Products', 'assets/adventure_bike.png', const Color(0xFFB9E5F3)),
                          _buildCategoryCard(
                              context, 'Electric Bikes', '45 Products', 'assets/electric_bike.png', const Color(0xFFFFD580)),
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
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String count, String imagePath, Color bgColor) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/filter_result', arguments: title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    errorBuilder: (c, e, s) => const Icon(Icons.directions_bike, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF121926),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9F9F9F),
                      fontWeight: FontWeight.w500,
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
