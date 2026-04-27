import 'package:bikebooking/core/constants/bike_brand_catalog.dart';
import 'package:bikebooking/core/constants/product_categories.dart';
import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/home/presentation/controllers/list_product_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class BikeDetailFormScreen extends StatelessWidget {
  const BikeDetailFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ListProductController>(
      builder: (controller) {
        final baseCategory = ProductCategoryCatalog.baseCategoryFor(
          controller.category,
        );
        final detailLabel =
            baseCategory == ProductCategoryCatalog.scooter ? 'Scooter' : 'Bike';

        return Scaffold(
          backgroundColor: AppColors.background,
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
                      Text(
                        '$detailLabel Detail',
                        style: const TextStyle(
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
                        _buildLabel('Sub Category'),
                        _buildTextField(
                          controller.subCategory ??
                              'Select ${detailLabel.toLowerCase()} sub category',
                          onTap: () => _showVehicleSubCategoryBottomSheet(
                            context,
                            controller,
                            detailLabel,
                          ),
                          readOnly: true,
                          hasValue: controller.subCategory != null,
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
                                  _buildLabel('Fuel Type'),
                                  _buildTextField(
                                    controller.fuelType ?? 'Select Fuel Type',
                                    onTap: () => _showFuelTypeBottomSheet(
                                        context, controller),
                                    readOnly: true,
                                    hasValue: controller.fuelType != null,
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
                                  _buildLabel('Kilometer Driven'),
                                  _buildTextField(
                                    'Enter KM driven',
                                    controller: controller.kilometerController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Number of Owners'),
                                  _buildTextField(
                                    controller.numberOfOwners == null
                                        ? 'Select owner'
                                        : '${controller.numberOfOwners} owner',
                                    onTap: () => _showOwnersBottomSheet(
                                        context, controller),
                                    readOnly: true,
                                    hasValue: controller.numberOfOwners != null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Product Description'),
                        _buildDescriptionField(controller),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Actions
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
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
                        child: CustomGradientButton(
                          text: 'Next',
                          onPressed: () {
                            if (!controller.validateBikeDetailsStep()) {
                              return;
                            }
                            Navigator.pushNamed(
                                context, '/bike_price_location');
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

  Widget _buildDescriptionField(ListProductController controller) {
    return Column(
      children: [
        TextField(
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
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF233A66)),
            ),
          ),
        ),
      ],
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
            fontWeight: FontWeight.w500,
            color: Color(0xFF37474F),
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

  void _showVehicleSubCategoryBottomSheet(
    BuildContext context,
    ListProductController controller,
    String detailLabel,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final options = controller.vehicleSubCategoryOptions;

        return Container(
          height: MediaQuery.of(context).size.height * 0.56,
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
                'Select $detailLabel Sub Category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: options
                      .map(
                        (option) => _buildVehicleSubCategoryItem(
                          option,
                          context,
                          controller,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleSubCategoryItem(
    VehicleSubCategoryOption option,
    BuildContext context,
    ListProductController controller,
  ) {
    final isSelected = controller.subCategory == option.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF233A66)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        leading: Icon(
          option.icon,
          color: option.iconColor,
          size: 28,
        ),
        title: Text(
          option.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E3E5C),
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: Color(0xFF233A66),
              )
            : null,
        onTap: () {
          controller.setSubCategory(option.label);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showBrandBottomSheet(
    BuildContext context,
    ListProductController controller,
  ) async {
    var searchQuery = '';
    final searchController = TextEditingController();

    final selectedBrand = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final brandSections = _filteredBrandSections(searchQuery);
            final hasBrands = brandSections.isNotEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
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
                  const Text(
                    'Select a Brand',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Brand',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final sheetNavigator = Navigator.of(sheetContext);
                      final customBrand = await _showCustomBrandDialog(
                        context,
                        initialValue: searchQuery,
                      );
                      if (customBrand == null || customBrand.isEmpty) {
                        return;
                      }

                      if (sheetNavigator.canPop()) {
                        sheetNavigator.pop(customBrand);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3E8EF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Color(0xFF233A66),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Type custom brand',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E3E5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'All Brand',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: !hasBrands
                        ? const Center(
                            child: Text(
                              'No brands found.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5E6E8C),
                              ),
                            ),
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              for (final section in brandSections.entries) ...[
                                _buildBrandItem(
                                  section.key,
                                  context,
                                  isParent: true,
                                ),
                                for (final model in section.value)
                                  _buildBrandItem(
                                    model,
                                    context,
                                    value: '${section.key} $model',
                                    isModel: true,
                                  ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (selectedBrand != null && selectedBrand.trim().isNotEmpty) {
      controller.setBrand(selectedBrand.trim());
    }
  }

  Map<String, List<String>> _filteredBrandSections(String searchQuery) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final sections = <String, List<String>>{};

    for (final brand in BikeBrandCatalog.brands) {
      final models = BikeBrandCatalog.brandModels[brand] ?? const <String>[];
      if (normalizedQuery.isEmpty) {
        sections[brand] = models;
        continue;
      }

      final brandMatches = brand.toLowerCase().contains(normalizedQuery);
      final matchingModels = models
          .where(
            (model) =>
                brandMatches ||
                model.toLowerCase().contains(normalizedQuery) ||
                '$brand $model'.toLowerCase().contains(normalizedQuery),
          )
          .toList(growable: false);

      if (brandMatches || matchingModels.isNotEmpty) {
        sections[brand] = matchingModels;
      }
    }

    return sections;
  }

  Future<String?> _showCustomBrandDialog(
    BuildContext context, {
    String initialValue = '',
  }) async {
    var brandValue = initialValue;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Type Brand Name'),
          content: TextFormField(
            initialValue: initialValue,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              brandValue = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter bike brand',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final customBrand = brandValue.trim();
                if (customBrand.isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, customBrand);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrandItem(
    String name,
    BuildContext context, {
    String? value,
    bool isParent = false,
    bool isModel = false,
  }) {
    final selectedValue = value ?? name;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context, selectedValue);
      },
      child: Container(
        margin: EdgeInsets.only(
          left: isModel ? 28 : 0,
          bottom: isModel ? 8 : 12,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isModel ? 14 : 16,
          vertical: isModel ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isModel ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                color: isModel ? Colors.white : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isModel
                    ? Icons.subdirectory_arrow_right_rounded
                    : Icons.two_wheeler_rounded,
                color: isParent
                    ? const Color(0xFF233A66)
                    : const Color(0xFF5E6E8C),
                size: isModel ? 18 : 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isModel ? 14 : 16,
                  fontWeight: isParent ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF2E3E5C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelTypeBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
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
              const Text(
                'Select Fuel Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 16),
              _buildFuelItem('Petrol', Icons.local_gas_station, Colors.green,
                  context, controller),
              _buildFuelItem('Electric', Icons.electric_bike, Colors.orange,
                  context, controller),
              _buildFuelItem('Hybrid', Icons.eco, Colors.green.shade700,
                  context, controller),
              _buildFuelItem(
                  'CNG', Icons.gas_meter, Colors.blue, context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuelItem(String name, IconData icon, Color iconColor,
      BuildContext context, ListProductController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E3E5C),
          ),
        ),
        onTap: () {
          controller.setFuelType(name);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showOwnersBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
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
              const Text(
                'Select Number of Owners',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 16),
              _buildSelectableItem('1st owner', () {
                controller.setNumberOfOwners(1);
                Navigator.pop(context);
              }),
              _buildSelectableItem('2nd owner', () {
                controller.setNumberOfOwners(2);
                Navigator.pop(context);
              }),
              _buildSelectableItem('3rd owner', () {
                controller.setNumberOfOwners(3);
                Navigator.pop(context);
              }),
              _buildSelectableItem('4th owner', () {
                controller.setNumberOfOwners(4);
                Navigator.pop(context);
              }),
            ],
          ),
        );
      },
    );
  }

  void _showYearBottomSheet(
      BuildContext context, ListProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              const Text(
                'Select Manufacturing Year',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: 15,
                  itemBuilder: (context, index) {
                    final year = 2025 - index;
                    return _buildSelectableItem(year.toString(), () {
                      controller.setYear(year);
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectableItem(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6E6E6E),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    int maxLines = 1,
    VoidCallback? onTap,
    bool readOnly = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool hasValue = false,
  }) {
    final showsValue =
        hasValue || (controller?.text.trim().isNotEmpty ?? false);

    return TextField(
      maxLines: maxLines,
      onTap: onTap,
      readOnly: readOnly,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF233A66)),
        ),
      ),
    );
  }
}
