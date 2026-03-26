import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int _selectedTabIndex = 0;
  String category = 'Bikes';
  bool _initialized = false;

  List<String> get _tabs {
    if (category == 'Accessories' || category == 'Spare Parts') {
      return [
        'Brand',
        'Price',
        category,
        'Year',
        'Owners',
      ];
    }
    return [
      'Brand',
      'Price',
      'Km Driven',
      'Year',
      'Fuel Type',
      'Owners',
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        category = args;
      }
      _initialized = true;
    }
  }

  double _priceValue = 80000;
  double _kmValue = 5000;
  String? _selectedBrand;
  String? _selectedSort;
  String? _selectedQuickPrice;
  String? _selectedBikeAge;
  List<String> _selectedOwnersList = [];
  String? _selectedKmRange;
  String? _selectedFuelType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 15),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Side Tabs
                  Container(
                    width: 110,
                    color: const Color(0xFFF1F4F8),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 12),
                      itemCount: _tabs.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedTabIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = index;
                            });
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8EAF6) : Colors.transparent,
                            ),
                            child: Stack(
                              children: [
                                if (isSelected)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    _tabs[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AppColors.primary : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: _buildTabContent(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Apply Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '65',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                      ),
                      Text(
                        'Product Found',
                        style: TextStyle(fontSize: 12, color: Color(0xFF37474F)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CustomGradientButton(
                    text: 'Apply Filter',
                    width: 157,
                    height: 48,
                    onPressed: () => Navigator.pushNamed(context, '/filter_result', arguments: category),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final currentTab = _tabs[_selectedTabIndex];
    switch (currentTab) {
      case 'Brand':
        return _buildBrandContent();
      case 'Price':
        return _buildPriceContent();
      case 'Km Driven':
        return _buildKmDrivenContent();
      case 'Accessories':
        return _buildAccessoriesContent();
      case 'Spare Parts':
        return _buildSparePartsContent();
      case 'Year':
        return _buildYearContent();
      case 'Fuel Type':
        return _buildFuelTypeContent();
      case 'Owners':
        return _buildOwnersContent();
      default:
        return Center(child: Text('Content for ${_tabs[_selectedTabIndex]}'));
    }
  }

  Widget _buildAccessoriesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 20),
        const Text('All Accessories', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              _buildSelectionItem('Arm Sleeves'),
              _buildSelectionItem('Helmet'),
              _buildSelectionItem('Riding Shoe'),
              _buildSelectionItem('Riding Gloves'),
              _buildSelectionItem('Rider Protective Pants'),
              _buildSelectionItem('Rider Jacket'),
              _buildSelectionItem('Rider Face Masks'),
              _buildSelectionItem('Phone Holder'),
              _buildSelectionItem('Knee & Elbow Guards'),
              _buildSelectionItem('Saddle Bag'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSparePartsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 20),
        const Text('All Spare Parts', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              _buildSelectionItem('Engine'),
              _buildSelectionItem('Clutch Lever'),
              _buildSelectionItem('Dashboard'),
              _buildSelectionItem('Gear Shifter'),
              _buildSelectionItem('Headlight'),
              _buildSelectionItem('Brakes'),
              _buildSelectionItem('Exhaust'),
              _buildSelectionItem('Fuel Tank'),
              _buildSelectionItem('Frame'),
              _buildSelectionItem('Mirror'),
              _buildSelectionItem('Kickstand'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Image.asset(
            'assets/images/Group 1171276172.png',
            height: 13,
            width: 13,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Brand',
                hintStyle: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKmDrivenContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a range below (km)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: const Color(0xFFE5E5E5),
                    thumbColor: Colors.white,
                    overlayColor: AppColors.primary.withOpacity(0.12),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 3),
                    valueIndicatorColor: AppColors.primary,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    value: _kmValue,
                    min: 0,
                    max: 100000,
                    onChanged: (v) => setState(() => _kmValue = v),
                  ),
                ),
              ],
            ),
            // Custom Tooltip
            Positioned(
              left: (_kmValue / 100000) * (MediaQuery.of(context).size.width - 150) + 15,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('${_kmValue.toInt().toString()}km',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Min 0km', style: TextStyle(fontSize: 10, color: Color(0xFF262A36))),
            Text('Max 1,00,000km', style: TextStyle(fontSize: 10, color: Color(0xFF262A36))),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFE5E5E5)),
        const SizedBox(height: 10),
        const Text('Popular ranges',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionChip('Under 25k km',
                isSelected: _selectedKmRange == 'Under 25k km',
                onTap: () => setState(() => _selectedKmRange = 'Under 25k km')),
            _buildOptionChip('Under 50k km',
                isSelected: _selectedKmRange == 'Under 50k km',
                onTap: () => setState(() => _selectedKmRange = 'Under 50k km')),
            _buildOptionChip('Under 75k km',
                isSelected: _selectedKmRange == 'Under 75k km',
                onTap: () => setState(() => _selectedKmRange = 'Under 75k km')),
            _buildOptionChip('Under 1L km',
                isSelected: _selectedKmRange == 'Under 1L km',
                onTap: () => setState(() => _selectedKmRange = 'Under 1L km')),
          ],
        ),
      ],
    );
  }

  Widget _buildFuelTypeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose fuel type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        const SizedBox(height: 16),
        _buildRadioWithIconOnRight('Petrol', 'assets/fuel/petrol.png', _selectedFuelType == 'Petrol',
            () => setState(() => _selectedFuelType = 'Petrol')),
        _buildRadioWithIconOnRight('Electric', 'assets/fuel/electric.png', _selectedFuelType == 'Electric',
            () => setState(() => _selectedFuelType = 'Electric')),
        _buildRadioWithIconOnRight('Hybrid', 'assets/fuel/hybrid.png', _selectedFuelType == 'Hybrid',
            () => setState(() => _selectedFuelType = 'Hybrid')),
        _buildRadioWithIconOnRight(
            'CNG', 'assets/fuel/cng.png', _selectedFuelType == 'CNG', () => setState(() => _selectedFuelType = 'CNG')),
      ],
    );
  }

  Widget _buildRadioWithIconOnRight(String text, String imagePath, bool isSelected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              height: 32,
              width: 32, // Larger icons as shown in screenshot
              errorBuilder: (c, e, s) => const Icon(Icons.local_gas_station, size: 24, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF262A36), fontSize: 14)),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFD0D0D0),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a year below', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildYearInput('2003'),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('To')),
            _buildYearInput('2025'),
          ],
        ),
        const SizedBox(height: 30),
        const Text('Popular bike age', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionChip('2 year or less',
                isSelected: _selectedBikeAge == '2 year or less',
                onTap: () => setState(() => _selectedBikeAge = '2 year or less')),
            _buildOptionChip('4 year or less',
                isSelected: _selectedBikeAge == '4 year or less',
                onTap: () => setState(() => _selectedBikeAge = '4 year or less')),
            _buildOptionChip('6 year or less',
                isSelected: _selectedBikeAge == '6 year or less',
                onTap: () => setState(() => _selectedBikeAge = '6 year or less')),
            _buildOptionChip('8 year or less',
                isSelected: _selectedBikeAge == '8 year or less',
                onTap: () => setState(() => _selectedBikeAge = '8 year or less')),
          ],
        ),
      ],
    );
  }

  Widget _buildYearInput(String hint) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(hint, style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildOwnersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a owners',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        const SizedBox(height: 16),
        _buildCheckboxItem('1st owner', _selectedOwnersList.contains('1st owner'), (v) {
          setState(() {
            if (v == true) {
              _selectedOwnersList.add('1st owner');
            } else {
              _selectedOwnersList.remove('1st owner');
            }
          });
        }),
        _buildCheckboxItem('2nd owner', _selectedOwnersList.contains('2nd owner'), (v) {
          setState(() {
            if (v == true) {
              _selectedOwnersList.add('2nd owner');
            } else {
              _selectedOwnersList.remove('2nd owner');
            }
          });
        }),
        _buildCheckboxItem('3rd owner', _selectedOwnersList.contains('3rd owner'), (v) {
          setState(() {
            if (v == true) {
              _selectedOwnersList.add('3rd owner');
            } else {
              _selectedOwnersList.remove('3rd owner');
            }
          });
        }),
        _buildCheckboxItem('4th owner', _selectedOwnersList.contains('4th owner'), (v) {
          setState(() {
            if (v == true) {
              _selectedOwnersList.add('4th owner');
            } else {
              _selectedOwnersList.remove('4th owner');
            }
          });
        }),
      ],
    );
  }

  Widget _buildCheckboxItem(String text, bool isSelected, Function(bool?)? onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFD0D0D0), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF262A36), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSelectionItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2E3E5C), fontSize: 14)),
    );
  }

  Widget _buildBrandContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 20),
        const Text('All Brand', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        const SizedBox(height: 08),
        Expanded(
          child: ListView(
            children: (category == 'Accessories')
                ? [
                    _buildBrandItem('UNO Minda', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('3M', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Motul', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Castrol', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Portronics', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Raido', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Dainese', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Alpinestars', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Rynox', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Moto central', 'assets/images/pngwing.com (27) 1.png'),
                    _buildBrandItem('Studds', 'assets/images/pngwing.com (27) 1.png'),
                  ]
                : [
                    _buildBrandItem('Aprilia', 'assets/brands/aprilia.png'),
                    _buildBrandItem('TVS', 'assets/brands/tvs.png'),
                    _buildBrandItem('Bajaj', 'assets/brands/bajaj.png'),
                    _buildBrandItem('Beneli', 'assets/brands/benelli.png'),
                    _buildBrandItem('BSA', 'assets/brands/bsa.png'),
                    _buildBrandItem('Ducati', 'assets/brands/ducati.png'),
                    _buildBrandItem('Eider', 'assets/brands/eider.png'),
                    _buildBrandItem('Harley-Davidson', 'assets/brands/harley.png'),
                    _buildBrandItem('Honda', 'assets/brands/honda.png'),
                    _buildBrandItem('Jawa', 'assets/brands/jawa.png'),
                    _buildBrandItem('Kawasaki', 'assets/brands/kawasaki.png'),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandItem(String text, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _selectedBrand == text,
            onChanged: (v) => setState(() => _selectedBrand = text),
            activeColor: AppColors.primary,
            side: const BorderSide(color: Color(0xFFD0D0D0), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Image.asset(imagePath,
              height: 15, errorBuilder: (c, e, s) => const Icon(Icons.stars, size: 20, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildPriceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a price range below',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: const Color(0xFFE5E5E5),
                    thumbColor: Colors.white,
                    overlayColor: AppColors.primary.withOpacity(0.12),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 3),
                    valueIndicatorColor: AppColors.primary,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    value: _priceValue,
                    min: 5000,
                    max: 200000,
                    onChanged: (v) => setState(() => _priceValue = v),
                  ),
                ),
              ],
            ),
            // Custom Tooltip
            Positioned(
              left: ((_priceValue - 5000) / (200000 - 5000)) * (MediaQuery.of(context).size.width - 150) + 15,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: [
                    Text('₹${_priceValue.toInt().toString()}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Min ₹5,000', style: TextStyle(fontSize: 10, color: Color(0xFF262A36))),
            Text('Max ₹2,00,000', style: TextStyle(fontSize: 10, color: Color(0xFF262A36))),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Color(0xFFE5E5E5)),
        const SizedBox(height: 10),
        const Text('Quick Select',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: category == 'Spare Parts'
              ? [
                  _buildOptionChip('₹0k - ₹10k',
                      isSelected: _selectedQuickPrice == '₹0k - ₹10k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹0k - ₹10k')),
                  _buildOptionChip('₹10k - ₹20k',
                      isSelected: _selectedQuickPrice == '₹10k - ₹20k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹10k - ₹20k')),
                  _buildOptionChip('₹20k - ₹30k',
                      isSelected: _selectedQuickPrice == '₹20k - ₹30k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹20k - ₹30k')),
                  _buildOptionChip('₹30k - ₹40k',
                      isSelected: _selectedQuickPrice == '₹30k - ₹40k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹30k - ₹40k')),
                  _buildOptionChip('₹40k - ₹50k',
                      isSelected: _selectedQuickPrice == '₹40k - ₹50k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹40k - ₹50k')),
                  _buildOptionChip('₹50k - ₹60k',
                      isSelected: _selectedQuickPrice == '₹50k - ₹60k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹50k - ₹60k')),
                  _buildOptionChip('₹60k+',
                      isSelected: _selectedQuickPrice == '₹60k+',
                      onTap: () => setState(() => _selectedQuickPrice = '₹60k+')),
                ]
              : [
                  _buildOptionChip('₹0k-₹25k',
                      isSelected: _selectedQuickPrice == '₹0k-₹25k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹0k-₹25k')),
                  _buildOptionChip('₹25k-₹50k',
                      isSelected: _selectedQuickPrice == '₹25k-₹50k',
                      onTap: () => setState(() => _selectedQuickPrice = '₹25k-₹50k')),
                  _buildOptionChip('₹50k-₹1L',
                      isSelected: _selectedQuickPrice == '₹50k-₹1L',
                      onTap: () => setState(() => _selectedQuickPrice = '₹50k-₹1L')),
                  _buildOptionChip('₹1L-₹1.5L',
                      isSelected: _selectedQuickPrice == '₹1L-₹1.5L',
                      onTap: () => setState(() => _selectedQuickPrice = '₹1L-₹1.5L')),
                  _buildOptionChip('₹1L-₹1.5L', // Keeping another copy as requested or just the same list
                      isSelected: _selectedQuickPrice == '₹1L-₹1.5L',
                      onTap: () => setState(() => _selectedQuickPrice = '₹1L-₹1.5L')),
                  _buildOptionChip('₹1.5L-₹2L',
                      isSelected: _selectedQuickPrice == '₹1.5L-₹2L',
                      onTap: () => setState(() => _selectedQuickPrice = '₹1.5L-₹2L')),
                  _buildOptionChip('₹2L+',
                      isSelected: _selectedQuickPrice == '₹2L+',
                      onTap: () => setState(() => _selectedQuickPrice = '₹2L+')),
                ],
        ),
        const SizedBox(height: 30),
        const Text('Sort By', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF262A36))),
        _buildSortItem('Low to High'),
        _buildSortItem('High to Low'),
      ],
    );
  }

  Widget _buildSortItem(String text) {
    bool isSelected = _selectedSort == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedSort = text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFD0D0D0),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF262A36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(String text, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF4A5F82), AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF262A36),
          ),
        ),
      ),
    );
  }
}
