import 'dart:async';

import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/product_cached_image.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_filter_state.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/search_controller.dart'
    as home_search;
import 'package:bikebooking/features/home/presentation/widgets/bike_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _sortOptions = <String>[
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Newest First',
  ];

  static const List<String> _bikeQuickPriceOptions = <String>[
    '₹0k-₹25k',
    '₹25k-₹50k',
    '₹50k-₹1L',
    '₹1L-₹1.5L',
    '₹1.5L-₹2L',
    '₹2L+',
  ];

  static const List<String> _bikeAgeOptions = <String>[
    '2 year or less',
    '4 year or less',
    '6 year or less',
    '8 year or less',
  ];

  late final home_search.SearchController _searchController;
  late final FavoritesController _favoritesController;
  late final bool _ownsSearchController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<home_search.SearchController>()) {
      _searchController = Get.find<home_search.SearchController>();
      _ownsSearchController = false;
    } else {
      _searchController = Get.put(home_search.SearchController());
      _ownsSearchController = true;
    }

    _favoritesController = Get.find<FavoritesController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.initialize();
    });
  }

  @override
  void dispose() {
    if (_ownsSearchController &&
        Get.isRegistered<home_search.SearchController>()) {
      Get.delete<home_search.SearchController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<home_search.SearchController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FBFF),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      Row(
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 45,
                        child: TextField(
                          controller: controller.searchTextController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onChanged: controller.onSearchChanged,
                          onSubmitted: controller.submitSearch,
                          decoration: InputDecoration(
                            hintText: 'Search products',
                            hintStyle: const TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 15,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(
                                Icons.search,
                                size: 18,
                                color: Color(0xFF5E6E8C),
                              ),
                            ),
                            suffixIcon: controller.hasQuery
                                ? IconButton(
                                    onPressed: controller.clearSearch,
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF5E6E8C),
                                      size: 18,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF1F4F8),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(context, controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    home_search.SearchController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null) {
      return _buildStateView(
        context,
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load search',
        message: controller.errorMessage!,
        actionLabel: 'Try again',
        onAction: controller.refreshData,
      );
    }

    if (controller.hasQuery) {
      return _buildSearchResults(context, controller);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationSection(context, controller),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (controller.recentSearches.isNotEmpty)
                  TextButton(
                    onPressed: controller.clearRecentSearches,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E4475),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.recentSearches.isEmpty)
              Text(
                'Your recent searches will appear here.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: controller.recentSearches
                      .map(
                        (query) => _buildRecentSearchItem(controller, query),
                      )
                      .toList(growable: false),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (controller.recommendedProducts.isEmpty)
              Text(
                'Recommendations will appear after products are loaded.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: controller.recommendedProducts
                      .map(
                        (product) => BikeCard(
                          product: product,
                          onTap: () {
                            unawaited(controller.recordCurrentQuery());
                            Navigator.pushNamed(
                              context,
                              '/bike_detail',
                              arguments: product,
                            );
                          },
                          onFavoriteTap: () {
                            _favoritesController.toggleFavorite(product);
                            controller.refreshRecommendations();
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(
    BuildContext context,
    home_search.SearchController controller,
  ) {
    return GetBuilder<LoginController>(
      builder: (loginController) {
        final selectedLocation =
            loginController.currentUserProfile?.location?.address.trim() ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildLocationButton(
                    icon: Icons.my_location,
                    label: loginController.isFetchingCurrentLocation
                        ? 'Detecting...'
                        : 'Use Current Location',
                    onTap: loginController.isFetchingCurrentLocation ||
                            loginController.isSavingLocation
                        ? null
                        : () async {
                            final location =
                                await loginController.useCurrentLocation(
                              navigateToHome: false,
                              showSuccessSnackbar: true,
                            );
                            if (location != null) {
                              controller.refreshRecommendations();
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLocationButton(
                    icon: Icons.add_circle_outline,
                    label: loginController.isSavingLocation
                        ? 'Saving...'
                        : 'Change location',
                    onTap: loginController.isSavingLocation
                        ? null
                        : () async {
                            final didSave = await Navigator.pushNamed(
                              context,
                              '/location_search',
                              arguments: {'returnOnSave': true},
                            );
                            if (didSave == true) {
                              controller.refreshRecommendations();
                            }
                          },
                  ),
                ),
              ],
            ),
            if (selectedLocation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Current search location: $selectedLocation',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5E6E8C),
                  height: 1.5,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    home_search.SearchController controller,
  ) {
    final filterState = controller.filterState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildInlineFilterStrip(controller, filterState),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${controller.searchResults.length} results for "${controller.currentQuery}"',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              if (filterState.hasActiveFilters)
                TextButton(
                  onPressed: controller.clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: controller.searchResults.isEmpty
              ? _buildStateView(
                  context,
                  icon: Icons.search_off_outlined,
                  title: 'No products found',
                  message: filterState.hasActiveFilters
                      ? 'Try clearing one or two filters to broaden the results.'
                      : 'Try a different name, brand, location, or category to find more matches.',
                  actionLabel: filterState.hasActiveFilters
                      ? 'Clear filters'
                      : 'Clear search',
                  onAction: filterState.hasActiveFilters
                      ? controller.clearFilters
                      : controller.clearSearch,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.refreshData,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.searchResults.length,
                    itemBuilder: (context, index) {
                      final product = controller.searchResults[index];
                      return _buildSearchResultCard(
                        context,
                        controller,
                        product,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInlineFilterStrip(
    home_search.SearchController controller,
    ProductFilterState filterState,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterActionChip(
            label: _sortChipLabel(filterState),
            isActive: _hasSortFilter(filterState),
            onTap: () => _showSortFilterBottomSheet(controller),
          ),
          _buildFilterActionChip(
            label: _brandChipLabel(filterState),
            isActive: _hasBrandFilter(filterState),
            onTap: () => _showBrandFilterBottomSheet(controller),
          ),
          _buildFilterActionChip(
            label: _priceChipLabel(filterState),
            isActive: _hasPriceFilter(filterState),
            onTap: () => _showPriceFilterBottomSheet(controller),
          ),
          _buildFilterActionChip(
            label: _yearChipLabel(filterState),
            isActive: _hasYearFilter(filterState),
            onTap: () => _showYearFilterBottomSheet(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterActionChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF1F4FA) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3E5C),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isActive ? AppColors.primary : const Color(0xFF5E6E8C),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSortFilterBottomSheet(
    home_search.SearchController controller,
  ) async {
    var selectedSort = _displaySortLabel(controller.filterState.selectedSort);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return _buildBottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBottomSheetHeader('Sort By'),
                  Column(
                    children: _sortOptions
                        .map(
                          (option) => _buildSortOptionTile(
                            label: option,
                            isSelected: selectedSort == option,
                            onTap: () {
                              setModalState(() {
                                selectedSort = option;
                              });
                              controller.updateSortFilter(
                                _sortValueFromLabel(option),
                              );
                              Navigator.pop(sheetContext);
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBrandFilterBottomSheet(
    home_search.SearchController controller,
  ) async {
    final brands = controller.availableBrands;
    var selectedBrand = controller.filterState.selectedBrand;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return _buildBottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBottomSheetHeader('Brand'),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: brands.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No brands available right now.',
                                style: TextStyle(
                                  color: Color(0xFF5E6E8C),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: brands.length,
                            itemBuilder: (context, index) {
                              final brand = brands[index];
                              final isSelected = selectedBrand == brand;
                              return _buildBottomSheetTile(
                                label: brand,
                                isSelected: isSelected,
                                onTap: () {
                                  setModalState(() {
                                    selectedBrand = isSelected ? null : brand;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  _buildBottomSheetActions(
                    onClear: selectedBrand == null
                        ? null
                        : () {
                            controller.updateBrandFilter(null);
                            Navigator.pop(sheetContext);
                          },
                    onApply: () {
                      controller.updateBrandFilter(selectedBrand);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPriceFilterBottomSheet(
    home_search.SearchController controller,
  ) async {
    var selectedQuickPrice = controller.filterState.selectedQuickPrice;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return _buildBottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBottomSheetHeader('Price'),
                  const Text(
                    'Choose a price range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _bikeQuickPriceOptions
                        .map(
                          (option) => _buildBottomSheetOptionChip(
                            label: option,
                            isSelected: selectedQuickPrice == option,
                            onTap: () {
                              setModalState(() {
                                selectedQuickPrice =
                                    selectedQuickPrice == option
                                        ? null
                                        : option;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 20),
                  _buildBottomSheetActions(
                    onClear: !_hasPriceFilter(controller.filterState)
                        ? null
                        : () {
                            controller.updatePriceFilter(
                              selectedQuickPrice: null,
                              maxPrice: null,
                            );
                            Navigator.pop(sheetContext);
                          },
                    onApply: () {
                      controller.updatePriceFilter(
                        selectedQuickPrice: selectedQuickPrice,
                        maxPrice: null,
                      );
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showYearFilterBottomSheet(
    home_search.SearchController controller,
  ) async {
    final result = await showModalBottomSheet<_YearFilterSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _YearFilterBottomSheet(
        initialMinYear: controller.filterState.minYear,
        initialMaxYear: controller.filterState.maxYear,
        initialBikeAge: controller.filterState.selectedBikeAge,
        bikeAgeOptions: _bikeAgeOptions,
      ),
    );

    if (result == null) {
      return;
    }

    controller.updateYearFilter(
      minYear: result.minYear,
      maxYear: result.maxYear,
      selectedBikeAge: result.selectedBikeAge,
    );
  }

  Widget _buildBottomSheetContainer({
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFD7DDE8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF233A66),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildBottomSheetTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F4FA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF233A66)
                      : const Color(0xFF262A36),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE9EDF4)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF262A36),
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFF8EA0C1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 7,
                        backgroundColor: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F4FA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5E5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : const Color(0xFF2E3E5C),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetActions({
    required VoidCallback onApply,
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        TextButton(
          onPressed: onClear,
          child: Text(
            'Clear',
            style: TextStyle(
              color:
                  onClear == null ? const Color(0xFFB7C0D0) : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: onApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  bool _hasBrandFilter(ProductFilterState filterState) {
    final brand = filterState.selectedBrand?.trim() ?? '';
    return brand.isNotEmpty;
  }

  bool _hasSortFilter(ProductFilterState filterState) {
    final selectedSort = filterState.selectedSort?.trim() ?? '';
    return selectedSort.isNotEmpty;
  }

  bool _hasPriceFilter(ProductFilterState filterState) {
    return (filterState.selectedQuickPrice?.trim().isNotEmpty ?? false) ||
        filterState.maxPrice != null;
  }

  bool _hasYearFilter(ProductFilterState filterState) {
    return (filterState.selectedBikeAge?.trim().isNotEmpty ?? false) ||
        filterState.minYear != null ||
        filterState.maxYear != null;
  }

  String _brandChipLabel(ProductFilterState filterState) {
    final brand = filterState.selectedBrand?.trim() ?? '';
    return brand.isEmpty ? 'Brand' : brand;
  }

  String _sortChipLabel(ProductFilterState filterState) {
    return _displaySortLabel(filterState.selectedSort) ?? 'Sort';
  }

  String _priceChipLabel(ProductFilterState filterState) {
    final quickPrice = filterState.selectedQuickPrice?.trim() ?? '';
    if (quickPrice.isNotEmpty) {
      return quickPrice;
    }

    final customPrice = _customPriceSummary(filterState);
    return customPrice ?? 'Price';
  }

  String _yearChipLabel(ProductFilterState filterState) {
    final bikeAge = filterState.selectedBikeAge?.trim() ?? '';
    if (bikeAge.isNotEmpty) {
      return bikeAge;
    }

    final manualYear = _manualYearSummary(filterState);
    return manualYear ?? 'Year';
  }

  String? _customPriceSummary(ProductFilterState filterState) {
    if (filterState.maxPrice == null) {
      return null;
    }
    return 'Up to Rs.${filterState.maxPrice!.round()}';
  }

  String? _manualYearSummary(ProductFilterState filterState) {
    if (filterState.minYear == null && filterState.maxYear == null) {
      return null;
    }

    final minLabel = filterState.minYear?.toString() ?? 'Any';
    final maxLabel = filterState.maxYear?.toString() ?? 'Any';
    return '$minLabel-$maxLabel';
  }

  String? _displaySortLabel(String? sortValue) {
    return switch (sortValue) {
      null => null,
      'Low to High' => 'Price: Low to High',
      'High to Low' => 'Price: High to Low',
      _ => sortValue,
    };
  }

  String? _sortValueFromLabel(String label) {
    return switch (label) {
      'Relevance' => null,
      'Price: Low to High' => 'Low to High',
      'Price: High to Low' => 'High to Low',
      'Newest First' => 'Newest First',
      _ => null,
    };
  }

  Widget _buildSearchResultCard(
    BuildContext context,
    home_search.SearchController controller,
    ProductModel product,
  ) {
    final primaryImage = _resolvePrimaryImage(product);
    final tags = _buildTags(product);

    return GestureDetector(
      onTap: () {
        unawaited(controller.recordCurrentQuery());
        Navigator.pushNamed(
          context,
          '/bike_detail',
          arguments: product,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 108,
                  height: 108,
                  color: const Color(0xFFF1F4F8),
                  child: primaryImage != null
                      ? ProductCachedImage(
                          imageUrl: primaryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_) => _buildImageFallback(),
                          placeholderBuilder: (_) => _buildImageFallback(),
                        )
                      : _buildImageFallback(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _buildTitle(product),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0C0E1B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GetBuilder<FavoritesController>(
                          builder: (favoritesController) {
                            final isFavorite =
                                favoritesController.isFavorite(product);
                            return GestureDetector(
                              onTap: () =>
                                  _favoritesController.toggleFavorite(product),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? Colors.red
                                      : const Color(0xFF5E6E8C),
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map((tag) => _buildInfoTag(tag))
                            .toList(growable: false),
                      ),
                    if (tags.isNotEmpty) const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _buildLocation(product),
                            style: const TextStyle(
                              color: Color(0xFF262A36),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _buildPrice(product),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF2E4475),
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(product.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF9F9F9F),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateView(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFFEAF0FB),
                          child: Icon(
                            icon,
                            size: 34,
                            color: const Color(0xFF233A66),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF233A66),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF5E6E8C),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(actionLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2E3E5C)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3E5C),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(
    home_search.SearchController controller,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => controller.applyRecentSearch(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 38,
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.only(left: 12, right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, color: Colors.grey.shade400, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E3E5C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => controller.removeRecentSearch(text),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade400,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String? _resolvePrimaryImage(ProductModel product) {
    for (final imageUrl in product.imageUrls) {
      final trimmed = imageUrl.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  String _buildTitle(ProductModel product) {
    final parts = <String>[];
    if (product.year != null) {
      parts.add(product.year.toString());
    }
    if (product.brand.trim().isNotEmpty) {
      parts.add(product.brand.trim());
    }
    if (product.title.trim().isNotEmpty) {
      parts.add(product.title.trim());
    }
    return parts.isEmpty ? 'Untitled product' : parts.join(' ');
  }

  String _buildPrice(ProductModel product) {
    if (product.price == null) {
      return 'Price on request';
    }
    final price = product.price!;
    if (price == price.roundToDouble()) {
      return 'Rs.${price.toInt()}';
    }
    return 'Rs.${price.toStringAsFixed(0)}';
  }

  String _buildLocation(ProductModel product) {
    final location = product.location?.trim() ?? '';
    return location.isNotEmpty ? location : 'Location not provided';
  }

  List<String> _buildTags(ProductModel product) {
    final tags = <String>[];
    if (product.kilometerDriven != null) {
      tags.add('${product.kilometerDriven} km');
    }
    if ((product.fuelType ?? '').trim().isNotEmpty) {
      tags.add(product.fuelType!.trim());
    }
    if ((product.subCategory ?? '').trim().isNotEmpty) {
      tags.add(product.subCategory!.trim());
    }
    if (product.year != null) {
      tags.add(product.year.toString());
    }
    if ((product.condition ?? '').trim().isNotEmpty) {
      tags.add(product.condition!.trim());
    }
    return tags.take(3).toList(growable: false);
  }

  String _timeAgo(DateTime? createdAt) {
    if (createdAt == null) {
      return 'Recently added';
    }

    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    }
    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    }
    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return '$months mo ago';
    }
    final years = (difference.inDays / 365).floor();
    return '$years yr ago';
  }
}

class _YearFilterSheetResult {
  const _YearFilterSheetResult({
    required this.minYear,
    required this.maxYear,
    required this.selectedBikeAge,
  });

  final int? minYear;
  final int? maxYear;
  final String? selectedBikeAge;
}

class _YearFilterBottomSheet extends StatefulWidget {
  const _YearFilterBottomSheet({
    required this.initialMinYear,
    required this.initialMaxYear,
    required this.initialBikeAge,
    required this.bikeAgeOptions,
  });

  final int? initialMinYear;
  final int? initialMaxYear;
  final String? initialBikeAge;
  final List<String> bikeAgeOptions;

  @override
  State<_YearFilterBottomSheet> createState() => _YearFilterBottomSheetState();
}

class _YearFilterBottomSheetState extends State<_YearFilterBottomSheet> {
  late final TextEditingController _minYearController;
  late final TextEditingController _maxYearController;
  String? _selectedBikeAge;

  @override
  void initState() {
    super.initState();
    _minYearController = TextEditingController(
      text: widget.initialMinYear?.toString() ?? '',
    );
    _maxYearController = TextEditingController(
      text: widget.initialMaxYear?.toString() ?? '',
    );
    _selectedBikeAge = widget.initialBikeAge;
  }

  @override
  void dispose() {
    _minYearController.dispose();
    _maxYearController.dispose();
    super.dispose();
  }

  bool get _hasAnySelection =>
      _minYearController.text.trim().isNotEmpty ||
      _maxYearController.text.trim().isNotEmpty ||
      (_selectedBikeAge?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DDE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Text(
                'Year',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A66),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Choose a year range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 20),
              const Text(
                'Popular bike age',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.bikeAgeOptions
                    .map(
                      (option) => _buildOptionChip(
                        label: option,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: !_hasAnySelection
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).pop(
                              const _YearFilterSheetResult(
                                minYear: null,
                                maxYear: null,
                                selectedBikeAge: null,
                              ),
                            );
                          },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: !_hasAnySelection
                            ? const Color(0xFFB7C0D0)
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _apply() {
    final minYear = int.tryParse(_minYearController.text.trim());
    final maxYear = int.tryParse(_maxYearController.text.trim());

    if (minYear != null && maxYear != null && minYear > maxYear) {
      Get.snackbar(
        'Invalid year range',
        'From year should be less than or equal to To year.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      _YearFilterSheetResult(
        minYear: minYear,
        maxYear: maxYear,
        selectedBikeAge: _selectedBikeAge,
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F4FA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5E5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : const Color(0xFF2E3E5C),
          ),
        ),
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
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
