import 'package:bikebooking/core/constants/product_categories.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductPreviewScreen extends StatelessWidget {
  const ProductPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ListProductController>(
      builder: (controller) {
        final isBikeOrScooter = ProductCategoryCatalog.isVehicleCategory(
          controller.category,
        );
        final previewImageUrls = controller.imageUrls
            .where((url) => url.trim().isNotEmpty)
            .toList(growable: false);
        final showRemoteImages =
            controller.pickedImages.isEmpty && previewImageUrls.isNotEmpty;
        final previewImageCount = showRemoteImages
            ? previewImageUrls.length
            : controller.pickedImages.length;
        final pageController =
            PageController(initialPage: controller.selectedImageIndex);

        return Scaffold(
          backgroundColor: AppColors.background,
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
                        'Post Preview',
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
                            child: previewImageCount > 0
                                ? PageView.builder(
                                    controller: pageController,
                                    itemCount: previewImageCount,
                                    onPageChanged:
                                        controller.selectProductImage,
                                    itemBuilder: (context, index) {
                                      if (showRemoteImages) {
                                        return Image.network(
                                          previewImageUrls[index],
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.image_outlined,
                                              size: 100,
                                              color: Colors.grey.shade300,
                                            );
                                          },
                                        );
                                      }

                                      return Image.memory(
                                        controller.pickedImages[index].bytes,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/images/bike.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_outlined,
                                        size: 100,
                                        color: Colors.grey.shade300,
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Page Indicator
                        Center(
                          child: previewImageCount > 1
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    previewImageCount,
                                    (index) {
                                      final isSelected =
                                          controller.selectedImageIndex ==
                                              index;
                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        width: isSelected ? 18 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF233A66)
                                              : const Color(0xFF233A66)
                                                  .withOpacity(0.25),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF233A66)
                                        .withOpacity(0.8),
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
                              Text(
                                controller.titleController.text.isNotEmpty
                                    ? '${controller.year ?? ''} ${controller.brand} ${controller.titleController.text}'
                                    : 'No title provided',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E3E5C)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.priceController.text.isNotEmpty
                                    ? 'Rs.${controller.priceController.text}'
                                    : 'Price not set',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF233A66)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      controller.locationController.text
                                              .isNotEmpty
                                          ? controller.locationController.text
                                          : 'Location not set',
                                      softWrap: true,
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13),
                                    ),
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
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF37474F)),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.05)),
                                ),
                                child: Column(
                                  children: [
                                    _buildSpecRow(
                                      'Category',
                                      isBikeOrScooter
                                          ? ProductCategoryCatalog
                                              .baseCategoryFor(
                                                  controller.category)
                                          : controller.category,
                                    ),
                                    _buildSpecRow(
                                        'Brand',
                                        controller.brand.isNotEmpty
                                            ? controller.brand
                                            : '—'),
                                    _buildSpecRow('Year',
                                        controller.year?.toString() ?? '—'),
                                    if (isBikeOrScooter) ...[
                                      _buildSpecRow(
                                        'Sub Category',
                                        controller.subCategory ?? '—',
                                      ),
                                      _buildSpecRow('Fuel Type',
                                          controller.fuelType ?? '—'),
                                      _buildSpecRow(
                                          'Kilometers',
                                          controller.kilometerController.text
                                                  .isNotEmpty
                                              ? controller
                                                  .kilometerController.text
                                              : '—'),
                                      _buildSpecRow(
                                          'Owners',
                                          controller.numberOfOwners != null
                                              ? '${controller.numberOfOwners}'
                                              : '—'),
                                    ],
                                    if (!isBikeOrScooter) ...[
                                      _buildSpecRow('Sub Category',
                                          controller.subCategory ?? '—'),
                                      _buildSpecRow('Condition',
                                          controller.condition ?? '—'),
                                      _buildSpecRow('Seller Type',
                                          controller.sellerType ?? '—'),
                                    ],
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
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF37474F)),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 150,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.05)),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    controller.descriptionController.text
                                            .isNotEmpty
                                        ? controller.descriptionController.text
                                        : 'No description provided.',
                                    style: const TextStyle(
                                        color: Color(0xFF5E6E8C),
                                        fontSize: 13,
                                        height: 1.5),
                                  ),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(0, 56),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                                color: Color(0xFF2E3E5C),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: controller.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CustomGradientButton(
                                text: controller.isEditing ? 'Update' : 'Post',
                                onPressed: () async {
                                  final wasEditing = controller.isEditing;
                                  final success =
                                      await controller.submitProduct();
                                  if (success && context.mounted) {
                                    Get.snackbar(
                                      'Success',
                                      controller.submissionSuccessMessage ??
                                          (wasEditing
                                              ? 'Your product has been updated!'
                                              : 'Your product has been posted!'),
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.green.shade600,
                                    );
                                    controller.resetForm();
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/my_listing',
                                      (route) => route.settings.name == '/home',
                                      arguments: wasEditing
                                          ? null
                                          : {'showBoost': true},
                                    );
                                  } else if (context.mounted) {
                                    Get.snackbar(
                                      'Error',
                                      controller.submissionErrorMessage ??
                                          (wasEditing
                                              ? 'Failed to update product. Please try again.'
                                              : 'Failed to post product. Please try again.'),
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red.shade600,
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            style: const TextStyle(
                color: Color(0xFF2E3E5C),
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
