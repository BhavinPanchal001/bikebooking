import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccessoriesDetailFormScreen extends StatelessWidget {
  const AccessoriesDetailFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ListProductController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
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
                        'Bike Detail',
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Product Title'),
                        _buildTextField(
                          'Enter Product Title',
                          controller: controller.titleController,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Brand'),
                        _buildTextField(
                          controller.brand.isEmpty
                              ? 'Select a Brand'
                              : controller.brand,
                          onTap: () =>
                              _showBrandBottomSheet(context, controller),
                          readOnly: true,
                          hasValue: controller.brand.isNotEmpty,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Year'),
                                  _buildTextField(
                                    controller.year == null
                                        ? 'Select a year'
                                        : controller.year.toString(),
                                    onTap: () => _showYearBottomSheet(
                                        context, controller),
                                    readOnly: true,
                                    hasValue: controller.year != null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Accessories'),
                                  _buildTextField(
                                    controller.subCategory ??
                                        'Select a Category',
                                    onTap: () => _showCategoryBottomSheet(
                                        context, controller),
                                    readOnly: true,
                                    hasValue: controller.subCategory != null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Condition'),
                                  _buildTextField(
                                    controller.condition ?? 'Select Condition',
                                    onTap: () => _showConditionBottomSheet(
                                        context, controller),
                                    readOnly: true,
                                    hasValue: controller.condition != null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Seller Type'),
                                  _buildTextField(
                                    controller.sellerType ??
                                        'Select a Seller Type',
                                    onTap: () => _showSellerTypeBottomSheet(
                                        context, controller),
                                    readOnly: true,
                                    hasValue: controller.sellerType != null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Product Description'),
                        _buildDescriptionField(controller),
                        const SizedBox(height: 40),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade200),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size(0, 54),
                                ),
                                child: const Text(
                                  'Previous',
                                  style: TextStyle(
                                      color: Color(0xFF2E3E5C),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!controller
                                      .validateAccessoryDetailsStep()) {
                                    return;
                                  }
                                  Navigator.pushNamed(
                                      context, '/bike_price_location');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A6495),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size(0, 54),
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionField(ListProductController controller) {
    return TextField(
      controller: controller.descriptionController,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.primary,
      maxLines: 5,
      maxLength: 1000,
      buildCounter: (context,
          {required currentLength, required isFocused, maxLength}) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min. 20 characters',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            Text(
              '$currentLength/$maxLength',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        );
      },
      decoration: InputDecoration(
        hintText: 'Describe your product in detail...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF233A66)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3E5C),
          ),
          children: const [
            TextSpan(
              text: '*',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint,
      {int maxLines = 1,
      VoidCallback? onTap,
      bool readOnly = false,
      TextEditingController? controller,
      bool hasValue = false}) {
    final showsValue =
        hasValue || (controller?.text.trim().isNotEmpty ?? false);

    return TextField(
      maxLines: maxLines,
      onTap: onTap,
      readOnly: readOnly,
      controller: controller,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: showsValue ? AppColors.primary : Colors.grey.shade400,
          fontSize: 14,
          fontWeight: showsValue ? FontWeight.w500 : FontWeight.w400,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: onTap != null
            ? Icon(
                Icons.keyboard_arrow_down,
                color: showsValue ? AppColors.primary : Colors.grey.shade400,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF233A66)),
        ),
      ),
    );
  }

  void _showBrandBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        context,
        'Select a Brand',
        searchHint: 'Search Brand',
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildListItem('UNO Minda', '', context, controller),
            _buildListItem('3M', '', context, controller),
            _buildListItem('Motul', '', context, controller),
            _buildListItem('Castrol', '', context, controller),
            _buildListItem('Portronics', '', context, controller),
            _buildListItem('Raido', '', context, controller),
            _buildListItem('Dainese', '', context, controller),
            _buildListItem('Alpinestars', '', context, controller),
            _buildListItem('Rynox', '', context, controller),
            _buildListItem('Moto central', '', context, controller),
            _buildListItem('Studds', '', context, controller),
          ],
        ),
      ),
    );
  }

  void _showYearBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        context,
        'Select Manufacturing Year',
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: 15,
          itemBuilder: (context, index) {
            final year = 2025 - index;
            return _buildSimpleListItem(year.toString(), () {
              controller.setYear(year);
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        context,
        'Select a Accessories',
        searchHint: 'Search Category',
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildSimpleListItem('Arm Sleeves', () {
              controller.setSubCategory('Arm Sleeves');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Helmet', () {
              controller.setSubCategory('Helmet');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Riding Shoe', () {
              controller.setSubCategory('Riding Shoe');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Riding Gloves', () {
              controller.setSubCategory('Riding Gloves');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Rider Protective Pants', () {
              controller.setSubCategory('Rider Protective Pants');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Rider Jacket', () {
              controller.setSubCategory('Rider Jacket');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Rider Face Masks', () {
              controller.setSubCategory('Rider Face Masks');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Phone Holder', () {
              controller.setSubCategory('Phone Holder');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Knee & Elbow Guards', () {
              controller.setSubCategory('Knee & Elbow Guards');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Saddle Bag', () {
              controller.setSubCategory('Saddle Bag');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showConditionBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        context,
        'Choose a Seller Type',
        child: Column(
          children: [
            _buildSimpleListItem('New', () {
              controller.setCondition('New');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Used', () {
              controller.setCondition('Used');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Refurbished', () {
              controller.setCondition('Refurbished');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showSellerTypeBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        context,
        'Choose a year below',
        child: Column(
          children: [
            _buildSimpleListItem('Individual', () {
              controller.setSellerType('Individual');
              Navigator.pop(context);
            }),
            _buildSimpleListItem('Dealer', () {
              controller.setSellerType('Dealer');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, String title,
      {String? searchHint, required Widget child}) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3E5C),
            ),
          ),
          if (searchHint != null) ...[
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade400, size: 24),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildListItem(String name, String logoPath, BuildContext context,
      ListProductController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: logoPath.isNotEmpty
              ? Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.shopping_bag, color: Colors.grey),
                )
              : const Icon(Icons.shopping_bag, color: Colors.grey),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E3E5C),
          ),
        ),
        onTap: () {
          controller.setBrand(name);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSimpleListItem(String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        title: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6E6E6E),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
