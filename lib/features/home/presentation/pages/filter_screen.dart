import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/home/data/models/product_filter_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  static const List<String> _bikeBrands = [
    'Aprilia',
    'TVS',
    'Bajaj',
    'Benelli',
    'BSA',
    'Ducati',
    'Eider',
    'Harley-Davidson',
    'Honda',
    'Jawa',
    'Kawasaki',
    'Royal Enfield',
    'Suzuki',
    'Yamaha',
  ];

  static const List<String> _accessoryBrands = [
    'UNO Minda',
    '3M',
    'Motul',
    'Castrol',
    'Portronics',
    'Raida',
    'Dainese',
    'Alpinestars',
    'Rynox',
    'Moto Central',
    'Studds',
  ];

  static const List<String> _accessoryCategories = [
    'Arm Sleeves',
    'Helmet',
    'Riding Shoe',
    'Riding Gloves',
    'Rider Protective Pants',
    'Rider Jacket',
    'Rider Face Masks',
    'Phone Holder',
    'Knee & Elbow Guards',
    'Saddle Bag',
  ];

  static const List<String> _sparePartCategories = [
    'Engine',
    'Clutch Lever',
    'Dashboard',
    'Gear Shifter',
    'Headlight',
    'Brakes',
    'Exhaust',
    'Fuel Tank',
    'Frame',
    'Mirror',
    'Kickstand',
  ];

  static const List<String> _fuelTypes = [
    'Petrol',
    'Electric',
    'Hybrid',
    'CNG',
  ];

  static const List<String> _ownerOptions = [
    '1st owner',
    '2nd owner',
    '3rd owner',
    '4th owner',
  ];

  static const List<String> _bikeAgeOptions = [
    '2 year or less',
    '4 year or less',
    '6 year or less',
    '8 year or less',
  ];

  static const List<String> _kmRangeOptions = [
    'Under 25k km',
    'Under 50k km',
    'Under 75k km',
    'Under 1L km',
  ];

  static const List<String> _conditionOptions = [
    'New',
    'Used',
    'Refurbished',
  ];

  static const List<String> _sellerTypeOptions = [
    'Individual',
    'Dealer',
  ];

  int _selectedTabIndex = 0;
  String category = 'Bikes';
  bool _initialized = false;

  late final TextEditingController _brandSearchController;
  late final TextEditingController _categorySearchController;
  late final TextEditingController _minYearController;
  late final TextEditingController _maxYearController;

  double _priceValue = _priceSliderMaxFor('Bikes');
  double _kmValue = _kmSliderMax;
  bool _hasCustomPrice = false;
  bool _hasCustomKm = false;
  String? _selectedBrand;
  String? _selectedSort;
  String? _selectedQuickPrice;
  String? _selectedBikeAge;
  List<String> _selectedOwnersList = [];
  String? _selectedKmRange;
  String? _selectedFuelType;
  String? _selectedSubCategory;
  String? _selectedCondition;
  String? _selectedSellerType;

  @override
  void initState() {
    super.initState();
    _brandSearchController = TextEditingController();
    _categorySearchController = TextEditingController();
    _minYearController = TextEditingController();
    _maxYearController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final initialFilters = ProductFilterState.fromRouteArguments(
      ModalRoute.of(context)?.settings.arguments,
    );
    category = initialFilters.category;
    _selectedBrand = initialFilters.selectedBrand;
    _selectedSort = initialFilters.selectedSort;
    _selectedQuickPrice = initialFilters.selectedQuickPrice;
    _selectedBikeAge = initialFilters.selectedBikeAge;
    _selectedOwnersList = List<String>.from(initialFilters.selectedOwners);
    _selectedKmRange = initialFilters.selectedKmRange;
    _selectedFuelType = initialFilters.selectedFuelType;
    _selectedSubCategory = initialFilters.selectedSubCategory;
    _selectedCondition = initialFilters.selectedCondition;
    _selectedSellerType = initialFilters.selectedSellerType;
    _priceValue = initialFilters.maxPrice ??
        _priceSliderMaxFor(initialFilters.baseCategory);
    _kmValue = initialFilters.maxKilometers ?? _kmSliderMax;
    _hasCustomPrice = initialFilters.maxPrice != null;
    _hasCustomKm = initialFilters.maxKilometers != null;
    _minYearController.text = initialFilters.minYear?.toString() ?? '';
    _maxYearController.text = initialFilters.maxYear?.toString() ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _brandSearchController.dispose();
    _categorySearchController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    super.dispose();
  }

  List<String> get _tabs {
    if (_isAccessoryLike) {
      return [
        'Brand',
        'Price',
        category,
        'Condition',
        'Seller Type',
        'Year',
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

  bool get _isAccessoryLike =>
      category == 'Accessories' || category == 'Spare Parts';

  String get _baseCategory =>
      ProductFilterState(category: category).baseCategory;

  List<String> get _brandOptions =>
      _isAccessoryLike ? _accessoryBrands : _bikeBrands;

  List<String> get _categoryOptions =>
      category == 'Spare Parts' ? _sparePartCategories : _accessoryCategories;

  List<String> get _filteredBrandOptions {
    final query = _brandSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _brandOptions;
    }
    return _brandOptions
        .where((brand) => brand.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<String> get _filteredCategoryOptions {
    final query = _categorySearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _categoryOptions;
    }
    return _categoryOptions
        .where((item) => item.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<String> get _quickPriceOptions {
    if (_isAccessoryLike) {
      return const [
        '₹0k - ₹10k',
        '₹10k - ₹20k',
        '₹20k - ₹30k',
        '₹30k - ₹40k',
        '₹40k - ₹50k',
        '₹50k - ₹60k',
        '₹60k+',
      ];
    }

    return const [
      '₹0k-₹25k',
      '₹25k-₹50k',
      '₹50k-₹1L',
      '₹1L-₹1.5L',
      '₹1.5L-₹2L',
      '₹2L+',
    ];
  }

  static const double _kmSliderMax = 100000;

  static double _priceSliderMaxFor(String category) {
    if (category == 'Accessories' || category == 'Spare Parts') {
      return 60000;
    }
    if (category == 'Scooter') {
      return 150000;
    }
    return 200000;
  }

  int get _activeFilterCount => _buildFilterState().activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    color: const Color(0xFFF1F4F8),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 12),
                      itemCount: _tabs.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedTabIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = index;
                            });
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE8EAF6)
                                  : Colors.transparent,
                            ),
                            child: Stack(
                              children: [
                                if (isSelected)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 4,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    _tabs[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade500,
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: _buildTabContent(),
                    ),
                  ),
                ],
              ),
            ),
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeFilterCount.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3E5C),
                        ),
                      ),
                      Text(
                        _activeFilterCount == 1
                            ? 'Filter selected'
                            : 'Filters selected',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Color(0xFF5E6E8C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomGradientButton(
                    text: 'Apply Filter',
                    width: 157,
                    height: 48,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/filter_result',
                        arguments: _buildFilterState(),
                      );
                    },
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
      case 'Spare Parts':
        return _buildCategoryContent();
      case 'Year':
        return _buildYearContent();
      case 'Fuel Type':
        return _buildFuelTypeContent();
      case 'Owners':
        return _buildOwnersContent();
      case 'Condition':
        return _buildConditionContent();
      case 'Seller Type':
        return _buildSellerTypeContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBrandContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(
          controller: _brandSearchController,
          hintText: 'Search Brand',
        ),
        const SizedBox(height: 20),
        const Text(
          'All Brand',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: _filteredBrandOptions
                .map(
                  (brand) => _buildSelectableTile(
                    label: brand,
                    selected: _selectedBrand == brand,
                    onTap: () {
                      setState(() {
                        _selectedBrand = _selectedBrand == brand ? null : brand;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceContent() {
    final sliderMax = _priceSliderMaxFor(_baseCategory);
    final sliderValue = _priceValue.clamp(0, sliderMax).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a price range below',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Up to Rs.${sliderValue.round()}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3E5C),
          ),
        ),
        Slider(
          value: sliderValue,
          min: 0,
          max: sliderMax,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _priceValue = value;
              _hasCustomPrice = true;
              _selectedQuickPrice = null;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Min Rs.0',
              style: TextStyle(fontSize: 10, color: Color(0xFF262A36)),
            ),
            Text(
              'Max Rs.${sliderMax.round()}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF262A36)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFE5E5E5)),
        const SizedBox(height: 12),
        const Text(
          'Quick Select',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickPriceOptions
              .map(
                (option) => _buildOptionChip(
                  option,
                  isSelected: _selectedQuickPrice == option,
                  onTap: () {
                    setState(() {
                      _selectedQuickPrice =
                          _selectedQuickPrice == option ? null : option;
                      _hasCustomPrice = false;
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sort By',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        _buildSortItem('Low to High'),
        _buildSortItem('High to Low'),
      ],
    );
  }

  Widget _buildKmDrivenContent() {
    final sliderValue = _kmValue.clamp(0, _kmSliderMax).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a range below (km)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Up to ${sliderValue.round()} km',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3E5C),
          ),
        ),
        Slider(
          value: sliderValue,
          min: 0,
          max: _kmSliderMax,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _kmValue = value;
              _hasCustomKm = true;
              _selectedKmRange = null;
            });
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min 0 km',
              style: TextStyle(fontSize: 10, color: Color(0xFF262A36)),
            ),
            Text(
              'Max 100000 km',
              style: TextStyle(fontSize: 10, color: Color(0xFF262A36)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFE5E5E5)),
        const SizedBox(height: 12),
        const Text(
          'Popular ranges',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kmRangeOptions
              .map(
                (option) => _buildOptionChip(
                  option,
                  isSelected: _selectedKmRange == option,
                  onTap: () {
                    setState(() {
                      _selectedKmRange =
                          _selectedKmRange == option ? null : option;
                      _hasCustomKm = false;
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildCategoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(
          controller: _categorySearchController,
          hintText:
              'Search ${category == 'Accessories' ? 'Accessories' : 'Spare Parts'}',
        ),
        const SizedBox(height: 20),
        Text(
          'All $category',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3E5C),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: _filteredCategoryOptions
                .map(
                  (option) => _buildSelectableTile(
                    label: option,
                    selected: _selectedSubCategory == option,
                    onTap: () {
                      setState(() {
                        _selectedSubCategory =
                            _selectedSubCategory == option ? null : option;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _buildFuelTypeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose fuel type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 16),
        ..._fuelTypes.map(
          (fuelType) => _buildSelectableTile(
            label: fuelType,
            selected: _selectedFuelType == fuelType,
            onTap: () {
              setState(() {
                _selectedFuelType =
                    _selectedFuelType == fuelType ? null : fuelType;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYearContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a year range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3E5C),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildYearField(
                controller: _minYearController,
                hintText: 'From',
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('To'),
            ),
            Expanded(
              child: _buildYearField(
                controller: _maxYearController,
                hintText: 'To',
              ),
            ),
          ],
        ),
        if (!_isAccessoryLike) ...[
          const SizedBox(height: 30),
          const Text(
            'Popular bike age',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3E5C),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bikeAgeOptions
                .map(
                  (option) => _buildOptionChip(
                    option,
                    isSelected: _selectedBikeAge == option,
                    onTap: () {
                      setState(() {
                        _selectedBikeAge =
                            _selectedBikeAge == option ? null : option;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _buildOwnersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose owners',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 16),
        ..._ownerOptions.map(
          (owner) => _buildCheckboxItem(
            owner,
            _selectedOwnersList.contains(owner),
            (selected) {
              setState(() {
                if (selected == true) {
                  _selectedOwnersList.add(owner);
                } else {
                  _selectedOwnersList.remove(owner);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConditionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose condition',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 16),
        ..._conditionOptions.map(
          (condition) => _buildSelectableTile(
            label: condition,
            selected: _selectedCondition == condition,
            onTap: () {
              setState(() {
                _selectedCondition =
                    _selectedCondition == condition ? null : condition;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSellerTypeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose seller type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF262A36),
          ),
        ),
        const SizedBox(height: 16),
        ..._sellerTypeOptions.map(
          (sellerType) => _buildSelectableTile(
            label: sellerType,
            selected: _selectedSellerType == sellerType,
            onTap: () {
              setState(() {
                _selectedSellerType =
                    _selectedSellerType == sellerType ? null : sellerType;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
  }) {
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
          const Icon(Icons.search, size: 16, color: Color(0xFFB0B0B0)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                ),
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

  Widget _buildYearField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSelectableTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F4FA) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? const Color(0xFF233A66)
                      : const Color(0xFF262A36),
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(
    String text,
    bool isSelected,
    ValueChanged<bool?> onChanged,
  ) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF262A36),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortItem(String text) {
    final isSelected = _selectedSort == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSort = _selectedSort == text ? null : text;
        });
      },
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
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFD0D0D0),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
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

  Widget _buildOptionChip(
    String text, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
          ),
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

  ProductFilterState _buildFilterState() {
    final minYear = int.tryParse(_minYearController.text.trim());
    final maxYear = int.tryParse(_maxYearController.text.trim());

    return ProductFilterState(
      category: category,
      selectedBrand: _selectedBrand,
      selectedSort: _selectedSort,
      maxPrice: _hasCustomPrice ? _priceValue : null,
      selectedQuickPrice: _selectedQuickPrice,
      maxKilometers: _hasCustomKm ? _kmValue : null,
      selectedKmRange: _selectedKmRange,
      selectedFuelType: _selectedFuelType,
      selectedOwners: List<String>.from(_selectedOwnersList),
      minYear: minYear,
      maxYear: maxYear,
      selectedBikeAge: _selectedBikeAge,
      selectedSubCategory: _selectedSubCategory,
      selectedCondition: _selectedCondition,
      selectedSellerType: _selectedSellerType,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedSort = null;
      _selectedQuickPrice = null;
      _selectedBikeAge = null;
      _selectedOwnersList = [];
      _selectedKmRange = null;
      _selectedFuelType = null;
      _selectedSubCategory = null;
      _selectedCondition = null;
      _selectedSellerType = null;
      _hasCustomPrice = false;
      _hasCustomKm = false;
      _priceValue = _priceSliderMaxFor(_baseCategory);
      _kmValue = _kmSliderMax;
      _brandSearchController.clear();
      _categorySearchController.clear();
      _minYearController.clear();
      _maxYearController.clear();
    });
  }
}
