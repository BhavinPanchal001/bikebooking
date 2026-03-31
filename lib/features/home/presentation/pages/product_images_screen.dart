import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductImagesScreen extends StatelessWidget {
  const ProductImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Bikes';

    final controller = Get.isRegistered<ListProductController>()
        ? Get.find<ListProductController>()
        : Get.put(ListProductController());
    if (controller.category.isEmpty) {
      controller.setCategory(category);
    }

    return GetBuilder<ListProductController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
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
                          child: _buildMainPreview(controller),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (var index = 0;
                                  index < controller.totalImageCount;
                                  index++)
                                _buildThumbnail(controller, index),
                              if (controller.totalImageCount < 6)
                                _buildAddThumbnail(controller),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomGradientButton(
                    text: 'Next',
                    onPressed: () {
                      if (!controller.hasAnyImages) {
                        Get.snackbar(
                          'Images required',
                          'Please upload at least one product image.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      if (category == 'Spare Parts') {
                        Navigator.pushNamed(
                            context, '/spare_parts_detail_form');
                      } else if (category == 'Accessories') {
                        Navigator.pushNamed(
                            context, '/accessories_detail_form');
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
      },
    );
  }

  Widget _buildMainPreview(ListProductController controller) {
    final previewImageUrl = controller.selectedPreviewImageUrl;
    final previewImage = controller.selectedPreviewImage;

    if (previewImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          previewImageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildEmptyPreview(),
        ),
      );
    }

    if (previewImage == null) {
      return _buildEmptyPreview();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.memory(
        previewImage.bytes,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 100, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          'Upload product images',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(ListProductController controller, int index) {
    final existingImageCount = controller.existingImageUrls.length;

    if (index < existingImageCount) {
      final imageUrl = controller.existingImageUrls[index];
      return GestureDetector(
        onTap: () => controller.selectProductImage(index),
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.selectedImageIndex == index
                  ? AppColors.primary
                  : Colors.grey.shade200,
              width: controller.selectedImageIndex == index ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF1F4F8),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final image = controller.pickedImages[index - existingImageCount];

    return GestureDetector(
      onTap: () => controller.selectProductImage(index),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.selectedImageIndex == index
                ? AppColors.primary
                : Colors.grey.shade200,
            width: controller.selectedImageIndex == index ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.memory(
            image.bytes,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAddThumbnail(ListProductController controller) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF7E7E7E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.pickProductImages,
          borderRadius: BorderRadius.circular(12),
          child: const Icon(
            Icons.add_a_photo_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class RoundedRectanglePlatform {
  static RoundedRectangleBorder borderRadius(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
