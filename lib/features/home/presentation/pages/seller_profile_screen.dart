import 'package:flutter/material.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF233A66),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seller Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Seller Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 70,
                              width: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage('https://i.pravatar.cc/150?u=vinayak'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Vinayak kadam',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.orange, size: 16),
                                      const Icon(Icons.star, color: Colors.orange, size: 16),
                                      const Icon(Icons.star, color: Colors.orange, size: 16),
                                      const Icon(Icons.star, color: Colors.orange, size: 16),
                                      const Icon(Icons.star, color: Colors.orange, size: 16),
                                      const SizedBox(width: 8),
                                      const Text('(45 Reviews)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '+91 1234567890',
                                    style: TextStyle(color: Color(0xFF5E6E8C), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSellerStat('Joined', '2026'),
                            _buildSellerStat('Total Listings', '10'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Seller's Listings
                  _buildSellerListingCard(
                    'Aprilia rs 125',
                    'RS.85,000',
                    '2024-57 km',
                    'Madhya Pradesh 458468',
                    'assets/images/bike.png',
                  ),
                  _buildSellerListingCard(
                    'Hunter 360',
                    'RS.85,000',
                    '2024-57 km',
                    'Madhya Pradesh 458468',
                    'assets/images/bike.png',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
      ],
    );
  }

  Widget _buildSellerListingCard(String title, String price, String stats, String location, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              height: 80,
              color: Colors.white,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF5E6E8C))),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                const SizedBox(height: 4),
                Text(stats, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(location, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
