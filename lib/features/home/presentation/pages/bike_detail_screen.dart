import 'package:flutter/material.dart';

class BikeDetailScreen extends StatelessWidget {
  const BikeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar & Image
              Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.white,
                    child: Center(
                      child: Image.asset(
                        'assets/bike_card.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.directions_bike, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF2E3E5C)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _buildTopActionIcon(Icons.favorite_border),
                        const SizedBox(width: 12),
                        _buildTopActionIcon(Icons.error_outline),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Thumbnail Carousel Placeholder
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildThumbnail('assets/bike_card.png'),
                    _buildThumbnail('assets/bike_card.png'),
                    _buildThumbnail('assets/bike_card.png'),
                    _buildThumbnail('assets/bike_card.png'),
                    _buildThumbnail('assets/bike_card.png'),
                    _buildPlusThumbnail(),
                  ],
                ),
              ),
              
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.grey),
                    SizedBox(width: 4),
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF2E3E5C)),
                    SizedBox(width: 4),
                    CircleAvatar(radius: 3, backgroundColor: Colors.grey),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2021 Royal Enfield Hunter 350', style: TextStyle(fontSize: 16, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    const Text('Rs.1,85,000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF233A66))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Madhya Pradesh 458468', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Item specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                    const SizedBox(height: 12),
                    _buildSpecCard(),
                    
                    const SizedBox(height: 24),
                    const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                    const SizedBox(height: 12),
                    _buildDescription(),
                    
                    const SizedBox(height: 24),
                    const Text('Seller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                    const SizedBox(height: 12),
                    _buildSellerCard(),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/chat_detail');
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        label: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6CAD),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
      child: Icon(icon, color: const Color(0xFF2E3E5C), size: 22),
    );
  }

  Widget _buildThumbnail(String imagePath) {
    return Container(
      width: 45,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Image.asset(imagePath, fit: BoxFit.contain),
    );
  }

  Widget _buildPlusThumbnail() {
    return Container(
      width: 45,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF868C91).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Icon(Icons.add_a_photo, color: Colors.white, size: 18)),
    );
  }

  Widget _buildSpecCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildSpecRow('Brand', 'KTM Duke 360'),
          const Divider(height: 24, thickness: 0.5),
          _buildSpecRow('Year', '2022'),
          const Divider(height: 24, thickness: 0.5),
          _buildSpecRow('Model', 'Duke'),
          const Divider(height: 24, thickness: 0.5),
          _buildSpecRow('Condition', 'Used'),
          const Divider(height: 24, thickness: 0.5),
          _buildSpecRow('Kilometers', '9,600'),
        ],
      ),
    );
  }

  static Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Color(0xFF2E3E5C), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        'This second-hand KTM Duke 360 is a powerful and well-maintained street bike, perfect for riders looking for performance at an affordable price. Equipped with a 373 cc liquid-cooled engine, it delivers strong acceleration, smooth throttle response, and an exciting riding experience.',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _buildSellerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage('assets/profile_pic.png'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('Vinayak kadam', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                      SizedBox(width: 4),
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ],
                  ),
                  Row(
                    children: [
                      ...List.generate(5, (i) => const Icon(Icons.star, size: 14, color: Colors.amber)),
                      const SizedBox(width: 4),
                      Text('(45 Reviews)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Joined: 2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Total Listings: 10', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
