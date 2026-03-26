import 'package:bikebooking/core/constants/global.dart';
import 'package:flutter/material.dart';

class AccessoriesDetailFormScreen extends StatelessWidget {
  const AccessoriesDetailFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bike Detail', // As per screenshot
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
                    _buildTextField('Enter Product Title'),
                    const SizedBox(height: 16),

                    _buildLabel('Brand'),
                    _buildTextField(
                      'Select a Brand',
                      onTap: () => _showBrandBottomSheet(context),
                      readOnly: true,
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
                                'Select a year',
                                onTap: () => _showYearBottomSheet(context),
                                readOnly: true,
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
                                'Select a Category',
                                onTap: () => _showCategoryBottomSheet(context),
                                readOnly: true,
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
                                'Select a year', // Hint from screenshot
                                onTap: () => _showConditionBottomSheet(context),
                                readOnly: true,
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
                                'Select a Seller Type',
                                onTap: () => _showSellerTypeBottomSheet(context),
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Product Description'),
                    _buildTextField(
                      'Describe your product in detail...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Min. 20 characters',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        Text(
                          '0/1000',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(0, 54),
                            ),
                            child: const Text(
                              'Pervious', // Screenshot typo preserved
                              style: TextStyle(color: Color(0xFF2E3E5C), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/bike_price_location');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A6495),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(0, 54),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildTextField(String hint, {int maxLines = 1, VoidCallback? onTap, bool readOnly = false}) {
    return TextField(
      maxLines: maxLines,
      onTap: onTap,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: onTap != null ? Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400) : null,
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

  void _showBrandBottomSheet(BuildContext context) {
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
            _buildListItem('UNO Minda', ''), // Placeholder icon
            _buildListItem('3M', ''),
            _buildListItem('Motul', ''),
            _buildListItem('Castrol', ''),
            _buildListItem('Portronics', ''),
            _buildListItem('Raido', ''),
            _buildListItem('Dainese', ''),
            _buildListItem('Alpinestars', ''),
            _buildListItem('Rynox', ''),
            _buildListItem('Moto central', ''),
            _buildListItem('Studds', ''),
          ],
        ),
      ),
    );
  }

  void _showYearBottomSheet(BuildContext context) {
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
            final year = (2025 - index).toString();
            return _buildSimpleListItem(year, () => Navigator.pop(context));
          },
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
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
            _buildSimpleListItem('Arm Sleeves', () => Navigator.pop(context)),
            _buildSimpleListItem('Helmet', () => Navigator.pop(context)),
            _buildSimpleListItem('Riding Shoe', () => Navigator.pop(context)),
            _buildSimpleListItem('Riding Gloves', () => Navigator.pop(context)),
            _buildSimpleListItem('Rider Protective Pants', () => Navigator.pop(context)),
            _buildSimpleListItem('Rider Jacket', () => Navigator.pop(context)),
            _buildSimpleListItem('Rider Face Masks', () => Navigator.pop(context)),
            _buildSimpleListItem('Phone Holder', () => Navigator.pop(context)),
            _buildSimpleListItem('Knee & Elbow Guards', () => Navigator.pop(context)),
            _buildSimpleListItem('Saddle Bag', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showConditionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        context,
        'Choose a Seller Type',
        child: Column(
          children: [
            _buildSimpleListItem('New', () => Navigator.pop(context)),
            _buildSimpleListItem('Used', () => Navigator.pop(context)),
            _buildSimpleListItem('Refurbished', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showSellerTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        context,
        'Choose a year below',
        child: Column(
          children: [
            _buildSimpleListItem('Individual', () => Navigator.pop(context)),
            _buildSimpleListItem('Dealer', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, String title, {String? searchHint, required Widget child}) {
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
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 24),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildListItem(String name, String logoPath) {
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
          child: logoPath.isNotEmpty ? Image.asset(
            logoPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shopping_bag, color: Colors.grey),
          ) : const Icon(Icons.shopping_bag, color: Colors.grey),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E3E5C),
          ),
        ),
        onTap: () {},
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
