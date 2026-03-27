import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class BikeDetailScreen extends StatefulWidget {
  const BikeDetailScreen({super.key});

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  int _selectedIndex = 0;
  final List<String> _images = [
    'assets/images/pngwing.com (18) 3.png',
    'assets/images/pngwing.com (18) 3.png',
    'assets/images/pngwing.com (18) 3.png',
    'assets/images/pngwing.com (18) 3.png',
    'assets/images/pngwing.com (18) 3.png',
  ];

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
                        _images[_selectedIndex],
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.directions_bike, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF2E3E5C), size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFAFAFA).withOpacity(0.8),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Favorite logic
                          },
                          child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/Path 3392.png',
                                height: 20,
                                width: 20,
                              )),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            // Report logic
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              // color: const Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: Colors.black.withOpacity(0.1),
                              //     blurRadius: 4,
                              //     offset: const Offset(0, 2),
                              //   ),
                              // ],
                            ),
                            child: Image.asset(
                              'assets/images/Vector (3).png',
                              height: 20,
                              width: 20,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Thumbnail Carousel Placeholder - Now Interactive
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._images.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String path = entry.value;
                          return _buildThumbnail(path, idx == _selectedIndex, () {
                            setState(() {
                              _selectedIndex = idx;
                            });
                          });
                        }),
                        _buildPlusThumbnail(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_images.length, (index) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == index ? const Color(0xFF2E3E5C) : Colors.grey.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2021 Royal Enfield Hunter 350',
                        style: TextStyle(fontSize: 14, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    const Text('Rs.1,85,000',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0C0E1B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Madhya Pradesh 458468', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Item specifications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                    const SizedBox(height: 12),
                    _buildSpecCard(),
                    const SizedBox(height: 24),
                    const Text('Description',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                    const SizedBox(height: 12),
                    _buildDescription(),
                    const SizedBox(height: 24),
                    const Text('Seller',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                    const SizedBox(height: 12),
                    _buildSellerCard(),
                    const SizedBox(height: 32),
                    CustomGradientButton(
                      text: 'Chat',
                      onPressed: () {
                        Navigator.pushNamed(context, '/chat_detail');
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
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

  Widget _buildThumbnail(String imagePath, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E3E5C) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E3E5C).withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildPlusThumbnail() {
    return InkWell(
      onTap: () {
        // Handle upload logic here
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 50,
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF868C91),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset('assets/bike_card.png', fit: BoxFit.contain),
                ),
              ),
            ),
            const Icon(Icons.add, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Colors.white,
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

  Widget _buildSpecRow(String label, String value) {
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
        // color: Colors.white,
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
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/seller_profile'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // color: Colors.white,
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
                backgroundImage: AssetImage('assets/images/Oval.png'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('Vinayak kadam',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
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
          Text('Joined: 2026',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Total Listings: 10',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ],
      ),
    ),
    );
  }
}
