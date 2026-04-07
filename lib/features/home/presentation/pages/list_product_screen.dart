import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:bikebooking/features/home/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListProductScreen extends StatelessWidget {
  const ListProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              width: double.infinity,
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'List Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3E5C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.08,
                        children: [
                          _buildCategoryCard(
                            context,
                            'Bikes',
                            const Color(0xFFE2F2D5), // Light Green
                          ),
                          _buildCategoryCard(
                            context,
                            'Scooter',
                            const Color(0xFFFFE0C2), // Light Peach
                          ),
                          _buildCategoryCard(
                            context,
                            'Accessories',
                            const Color(0xFFE2E2F8), // Light Purple
                          ),
                          _buildCategoryCard(
                            context,
                            'Spare Parts',
                            const Color(0xFFD9F2F9), // Light Blue
                          ),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    Color bgColor,
  ) {
    return GestureDetector(
      onTap: () {
        final controller = Get.isRegistered<ListProductController>()
            ? Get.find<ListProductController>()
            : Get.put(ListProductController());
        if (controller.isEditing) {
          controller.resetForm();
        }
        controller.setCategory(title);
        Navigator.pushNamed(context, '/product_images', arguments: title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getIconForCategory(title),
                    size: 42,
                    color: const Color(0xFF2E3E5C),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF121926),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String title) {
    switch (title) {
      case 'Bikes':
        return Icons.sports_motorsports_rounded;
      case 'Scooter':
        return Icons.moped_rounded;
      case 'Accessories':
        return Icons.shield_outlined;
      case 'Spare Parts':
        return Icons.build_circle_outlined;
      default:
        return Icons.category;
    }
  }
}
