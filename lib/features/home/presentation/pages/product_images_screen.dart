import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/core/widgets/product_cached_image.dart';
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
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _buildMainPreview(controller),
                              ),
                              if (controller.hasAnyImages)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _confirmRemoveImage(
                                      context,
                                      controller,
                                      controller.selectedImageIndex,
                                    ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: Row(
                              children: [
                                for (var index = 0;
                                    index < controller.totalImageCount;
                                    index++)
                                  _buildThumbnail(context, controller, index),
                                if (controller.totalImageCount < 6)
                                  _buildAddThumbnail(controller),
                              ],
                            ),
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
        child: ProductCachedImage(
          imageUrl: previewImageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_) => _buildEmptyPreview(),
          placeholderBuilder: (_) => _buildEmptyPreview(),
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

  Widget _buildThumbnail(
      BuildContext context, ListProductController controller, int index) {
    final existingImageCount = controller.existingImageUrls.length;

    Widget thumbnailImage;
    if (index < existingImageCount) {
      final imageUrl = controller.existingImageUrls[index];
      thumbnailImage = ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ProductCachedImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          errorBuilder: (_) => Container(
            color: const Color(0xFFF1F4F8),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8),
            ),
          ),
          placeholderBuilder: (_) => Container(
            color: const Color(0xFFF1F4F8),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF233A66),
            ),
          ),
        ),
      );
    } else {
      final image = controller.pickedImages[index - existingImageCount];
      thumbnailImage = ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.memory(
          image.bytes,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
        ),
      );
    }

    return GestureDetector(
      onTap: () => controller.selectProductImage(index),
      onLongPress: () => _confirmRemoveImage(context, controller, index),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
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
              child: thumbnailImage,
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => _confirmRemoveImage(context, controller, index),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
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

  void _confirmRemoveImage(
    BuildContext context,
    ListProductController controller,
    int index,
  ) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove image'),
          content: const Text('Are you sure you want to remove this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        controller.removeImage(index);
      }
    });
  }
}

class RoundedRectanglePlatform {
  static RoundedRectangleBorder borderRadius(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
