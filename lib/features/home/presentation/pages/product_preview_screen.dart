import 'package:flutter/material.dart';

class ProductPreviewScreen extends StatelessWidget {
  const ProductPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2E3E5C), size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Center(
                      child: Container(
                        height: 250,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Image.asset(
                          'assets/images/bike.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Page Indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF233A66).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '2021 Royal Enfield Hunter 350',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Rs.2,85,000',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF233A66)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Madhya Pradesh 458468',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Item Specifications
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item specifications',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                _buildSpecRow('Brand', 'KTM Duke 360'),
                                _buildSpecRow('Year', '2022'),
                                _buildSpecRow('Model', 'Duke'),
                                _buildSpecRow('Condition', 'Used'),
                                _buildSpecRow('Kilometers', '9,600'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                            ),
                            child: const Text(
                              'This second-hand KTM Duke 360 is a powerful and well-maintained street bike, perfect for riders looking for performance at an affordable price. Equipped with a 373 cc liquid-cooled engine, it delivers strong acceleration, smooth throttle response, and an exciting riding experience.',
                              style: TextStyle(color: Color(0xFF5E6E8C), fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 56),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(color: Color(0xFF2E3E5C), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/my_listing');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6495),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 56),
                      ),
                      child: const Text(
                        'Post',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF2E3E5C), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
