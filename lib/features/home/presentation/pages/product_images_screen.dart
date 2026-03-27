import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductImagesScreen extends StatelessWidget {
  const ProductImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = ModalRoute.of(context)?.settings.arguments as String? ?? 'Bikes';

    // Initialize the controller at the start of the flow
    final controller = Get.put(ListProductController());
    // Store selected category
    if (controller.category.isEmpty) {
      controller.setCategory(category);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Same as ListProductScreen)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
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
                      fontSize: 20,
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
              child: CustomGradientButton(
                text: 'Next',
                onPressed: () {
                  if (category == 'Spare Parts') {
                    Navigator.pushNamed(context, '/spare_parts_detail_form');
                  } else if (category == 'Accessories') {
                    Navigator.pushNamed(context, '/accessories_detail_form');
                  } else {
                    Navigator.pushNamed(context, '/bike_detail_form');
                  }
                },
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
