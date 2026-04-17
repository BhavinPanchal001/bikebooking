import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:bikebooking/features/home/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ListProductScreen extends StatelessWidget {
  const ListProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBFF),
        body: Column(
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
              padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 24),
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
                        mainAxisSpacing: 22,
                        childAspectRatio: 1.06,
                        children: [
                          _buildCategoryCard(
                            context,
                            'Bikes',
                            'assets/images/Group 1171278014.png',
                            const Color(0xFFD4E7C5),
                          ),
                          _buildCategoryCard(
                            context,
                            'Scooter',
                            'assets/images/Group 1171278015.png',
                            const Color(0xFFFFD1A5),
                          ),
                          _buildCategoryCard(
                            context,
                            'Accessories',
                            'assets/images/Group 1171278016.png',
                            const Color(0xFFC9C9EB),
                          ),
                          _buildCategoryCard(
                            context,
                            'Spare Parts',
                            'assets/images/Group 1171278017.png',
                            const Color(0xFFB9E5F3),
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
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String imagePath,
    Color bgColor,
  ) {
    return GestureDetector(
      onTap: () {
        final controller = Get.isRegistered<ListProductController>()
            ? Get.find<ListProductController>()
            : Get.put(ListProductController());
        controller.resetForm();
        controller.setCategory(title);
        Navigator.pushNamed(context, '/product_images', arguments: title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: AspectRatio(
                aspectRatio: 1.53,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: bgColor,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF121926),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
