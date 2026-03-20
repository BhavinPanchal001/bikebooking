import 'package:flutter/material.dart';

class ProductImagesScreen extends StatelessWidget {
  const ProductImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Same as ListProductScreen)
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        text: 'Product Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3E5C),
                        ),
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Main Image Preview
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/bike.png', // Placeholder
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image_outlined, size: 100, color: Colors.grey.shade300);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thumbnails
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildThumbnail('assets/images/bike.png'),
                          _buildThumbnail('assets/images/bike.png'),
                          _buildThumbnail('assets/images/bike.png'),
                          _buildThumbnail('assets/images/bike.png'),
                          _buildThumbnail('assets/images/bike.png'),
                          _buildAddThumbnail(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/bike_detail_form');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6495),
                    shape: RoundedRectanglePlatform.borderRadius(20), // Wait, custom shape
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String imagePath) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade300);
          },
        ),
      ),
    );
  }

  Widget _buildAddThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF7E7E7E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 24),
    );
  }
}

class RoundedRectanglePlatform {
  static RoundedRectangleBorder borderRadius(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
