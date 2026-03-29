import 'dart:math';

import 'package:bikebooking/core/constants/product_categories.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_filter_state.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class FilterResultController extends GetxController {
  FilterResultController({
    ProductFirestoreService? firestoreService,
    SellerActionFirestoreService? sellerActionService,
    LoginController? loginController,
  })  : _firestoreService = firestoreService ?? ProductFirestoreService(),
        _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  static const Object _noChange = Object();

  final ProductFirestoreService _firestoreService;
  final SellerActionFirestoreService _sellerActionService;
  final LoginController _loginController;

  ProductFilterState _filterState = ProductFilterState(category: 'Bikes');
  ProductFilterState get filterState => _filterState;

  List<ProductModel> _allProducts = [];
  Set<String> _hiddenUserIds = <String>{};
  List<ProductModel> get products => List.unmodifiable(_products);
  List<ProductModel> _products = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String get categoryLabel => _filterState.selectedCategoryLabel;
  List<String> get availableBrands {
    final brands = _allProducts
        .map((product) => product.brand.trim())
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort((first, second) =>
          first.toLowerCase().compareTo(second.toLowerCase()));
    return brands;
  }

  String get screenTitle {
    if (_filterState.hasSpecificBikeCategory) {
      return _filterState.selectedCategoryLabel;
    }
    if (_filterState.baseCategory == 'Accessories') {
      return 'Accessories';
    }
    if (_filterState.baseCategory == 'Spare Parts') {
      return 'Spare Parts';
    }
    if (_filterState.baseCategory == 'Scooter') {
      return 'Scooters';
    }
    return 'Motorcycles';
  }

  Future<void> loadProducts(ProductFilterState filterState) async {
    _filterState = filterState;
    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      _hiddenUserIds = await _loadHiddenUserIds();
      final allProducts = await _firestoreService.getProducts(
        categories: filterState.queryCategories,
      );
      _allProducts = _filterHiddenProducts(allProducts);
      _products = _applyFilters(_allProducts, filterState);
    } catch (error, stackTrace) {
      _products = [];
      _errorMessage = 'Unable to load products right now. Please try again.';
      debugPrint('Error loading products: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts(_filterState);
  }

  void applyFilters(ProductFilterState filterState) {
    _filterState = filterState;
    _products = _applyFilters(_allProducts, filterState);
    update();
  }

  void updateBrandFilter(String? brand) {
    applyFilters(
      _copyFilterState(
        selectedBrand: _normalizeString(brand),
      ),
    );
  }

  void updatePriceFilter({
    String? selectedQuickPrice,
    double? maxPrice,
  }) {
    applyFilters(
      _copyFilterState(
        selectedQuickPrice: _normalizeString(selectedQuickPrice),
        maxPrice: maxPrice,
      ),
    );
  }

  void updateYearFilter({
    int? minYear,
    int? maxYear,
    String? selectedBikeAge,
  }) {
    applyFilters(
      _copyFilterState(
        minYear: minYear,
        maxYear: maxYear,
        selectedBikeAge: _normalizeString(selectedBikeAge),
      ),
    );
  }

  void updateSortFilter(String? selectedSort) {
    applyFilters(
      _copyFilterState(
        selectedSort: _normalizeString(selectedSort),
      ),
    );
  }

  void clearFilters() {
    final cleared = ProductFilterState(category: _filterState.category);
    applyFilters(cleared);
  }

  Future<Set<String>> _loadHiddenUserIds() async {
    final currentUserId = _loginController.resolvedCurrentUserId.trim();
    if (currentUserId.isEmpty) {
      return <String>{};
    }

    return _sellerActionService.getHiddenUserIds(currentUserId);
  }

  List<ProductModel> _filterHiddenProducts(List<ProductModel> products) {
    if (_hiddenUserIds.isEmpty) {
      return products;
    }

    return products
        .where((product) => !_hiddenUserIds.contains(product.sellerId.trim()))
        .toList(growable: false);
  }

  List<ProductModel> _applyFilters(
    List<ProductModel> source,
    ProductFilterState filterState,
  ) {
    final filtered = source.where((product) {
      if (!_matchesBrand(product, filterState)) return false;
      if (!_matchesPrice(product, filterState)) return false;
      if (!_matchesKilometers(product, filterState)) return false;
      if (!_matchesFuelType(product, filterState)) return false;
      if (!_matchesOwners(product, filterState)) return false;
      if (!_matchesYear(product, filterState)) return false;
      if (!_matchesSubCategory(product, filterState)) return false;
      if (!_matchesCondition(product, filterState)) return false;
      if (!_matchesSellerType(product, filterState)) return false;
      return true;
    }).toList();

    _sortProducts(filtered, filterState.selectedSort);
    return filtered;
  }

  bool _matchesBrand(ProductModel product, ProductFilterState filterState) {
    final brand = filterState.selectedBrand;
    if (brand == null || brand.trim().isEmpty) {
      return true;
    }
    return product.brand.trim().toLowerCase() == brand.trim().toLowerCase();
  }

  bool _matchesPrice(ProductModel product, ProductFilterState filterState) {
    final price = product.price;
    final quickRange = _parsePriceRange(filterState.selectedQuickPrice);
    final minPrice = quickRange.$1;
    final maxPrice = quickRange.$2 ?? filterState.maxPrice;

    if (minPrice == null && maxPrice == null) {
      return true;
    }
    if (price == null) {
      return false;
    }
    if (minPrice != null && price < minPrice) {
      return false;
    }
    if (maxPrice != null && price > maxPrice) {
      return false;
    }
    return true;
  }

  bool _matchesKilometers(
    ProductModel product,
    ProductFilterState filterState,
  ) {
    if (!filterState.isBikeLike) {
      return true;
    }

    final sliderLimit = filterState.maxKilometers?.round();
    final popularLimit = _parseKmRange(filterState.selectedKmRange);
    final maxKilometers = switch ((sliderLimit, popularLimit)) {
      (null, null) => null,
      (final slider?, null) => slider,
      (null, final popular?) => popular,
      (final slider?, final popular?) => min(slider, popular),
    };

    if (maxKilometers == null) {
      return true;
    }

    final kilometers = product.kilometerDriven;
    if (kilometers == null) {
      return false;
    }
    return kilometers <= maxKilometers;
  }

  bool _matchesFuelType(ProductModel product, ProductFilterState filterState) {
    final fuelType = filterState.selectedFuelType;
    if (fuelType == null || fuelType.trim().isEmpty) {
      return true;
    }
    return (product.fuelType ?? '').trim().toLowerCase() ==
        fuelType.trim().toLowerCase();
  }

  bool _matchesOwners(ProductModel product, ProductFilterState filterState) {
    if (filterState.selectedOwners.isEmpty) {
      return true;
    }

    final selectedOwners = filterState.selectedOwners
        .map(_ownerCountFromLabel)
        .whereType<int>()
        .toSet();
    if (selectedOwners.isEmpty) {
      return true;
    }

    final ownerCount = product.numberOfOwners;
    if (ownerCount == null) {
      return false;
    }
    return selectedOwners.contains(ownerCount);
  }

  bool _matchesYear(ProductModel product, ProductFilterState filterState) {
    final year = product.year;
    final minYear = switch ((
      filterState.minYear,
      _minYearFromBikeAge(filterState.selectedBikeAge)
    )) {
      (null, null) => null,
      (final manual?, null) => manual,
      (null, final bikeAge?) => bikeAge,
      (final manual?, final bikeAge?) => max(manual, bikeAge),
    };
    final maxYear = filterState.maxYear;

    if (minYear == null && maxYear == null) {
      return true;
    }
    if (year == null) {
      return false;
    }
    if (minYear != null && year < minYear) {
      return false;
    }
    if (maxYear != null && year > maxYear) {
      return false;
    }
    return true;
  }

  bool _matchesSubCategory(
    ProductModel product,
    ProductFilterState filterState,
  ) {
    final vehicleSubCategory = filterState.selectedVehicleSubCategory;
    if (vehicleSubCategory != null) {
      return ProductCategoryCatalog.matchesVehicleSubCategory(
        selectedSubCategory: vehicleSubCategory,
        category: product.category,
        subCategory: product.subCategory,
        fuelType: product.fuelType,
      );
    }

    final subCategory = filterState.selectedSubCategory;
    if (subCategory == null || subCategory.trim().isEmpty) {
      return true;
    }
    return (product.subCategory ?? '').trim().toLowerCase() ==
        subCategory.trim().toLowerCase();
  }

  bool _matchesCondition(
    ProductModel product,
    ProductFilterState filterState,
  ) {
    final condition = filterState.selectedCondition;
    if (condition == null || condition.trim().isEmpty) {
      return true;
    }
    return (product.condition ?? '').trim().toLowerCase() ==
        condition.trim().toLowerCase();
  }

  bool _matchesSellerType(
    ProductModel product,
    ProductFilterState filterState,
  ) {
    final sellerType = filterState.selectedSellerType;
    if (sellerType == null || sellerType.trim().isEmpty) {
      return true;
    }
    return (product.sellerType ?? '').trim().toLowerCase() ==
        sellerType.trim().toLowerCase();
  }

  void _sortProducts(List<ProductModel> products, String? selectedSort) {
    switch (selectedSort) {
      case 'Low to High':
        products.sort((first, second) {
          final firstPrice = first.price ?? double.infinity;
          final secondPrice = second.price ?? double.infinity;
          return firstPrice.compareTo(secondPrice);
        });
        break;
      case 'High to Low':
        products.sort((first, second) {
          final firstPrice = first.price ?? 0;
          final secondPrice = second.price ?? 0;
          return secondPrice.compareTo(firstPrice);
        });
        break;
      default:
        products.sort((first, second) {
          final firstCreatedAt =
              first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final secondCreatedAt =
              second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return secondCreatedAt.compareTo(firstCreatedAt);
        });
    }
  }

  (double?, double?) _parsePriceRange(String? selectedQuickPrice) {
    switch (selectedQuickPrice) {
      case '₹0k-₹25k':
        return (0, 25000);
      case '₹25k-₹50k':
        return (25000, 50000);
      case '₹50k-₹1L':
        return (50000, 100000);
      case '₹1L-₹1.5L':
        return (100000, 150000);
      case '₹1.5L-₹2L':
        return (150000, 200000);
      case '₹2L+':
        return (200000, null);
      case '₹0k - ₹10k':
        return (0, 10000);
      case '₹10k - ₹20k':
        return (10000, 20000);
      case '₹20k - ₹30k':
        return (20000, 30000);
      case '₹30k - ₹40k':
        return (30000, 40000);
      case '₹40k - ₹50k':
        return (40000, 50000);
      case '₹50k - ₹60k':
        return (50000, 60000);
      case '₹60k+':
        return (60000, null);
      default:
        return (null, null);
    }
  }

  int? _parseKmRange(String? selectedKmRange) {
    switch (selectedKmRange) {
      case 'Under 25k km':
        return 25000;
      case 'Under 50k km':
        return 50000;
      case 'Under 75k km':
        return 75000;
      case 'Under 1L km':
        return 100000;
      default:
        return null;
    }
  }

  int? _ownerCountFromLabel(String ownerLabel) {
    switch (ownerLabel) {
      case '1st owner':
        return 1;
      case '2nd owner':
        return 2;
      case '3rd owner':
        return 3;
      case '4th owner':
        return 4;
      default:
        return null;
    }
  }

  int? _minYearFromBikeAge(String? selectedBikeAge) {
    final currentYear = DateTime.now().year;
    switch (selectedBikeAge) {
      case '2 year or less':
        return currentYear - 2;
      case '4 year or less':
        return currentYear - 4;
      case '6 year or less':
        return currentYear - 6;
      case '8 year or less':
        return currentYear - 8;
      default:
        return null;
    }
  }

  ProductFilterState _copyFilterState({
    Object? category = _noChange,
    Object? selectedBrand = _noChange,
    Object? selectedSort = _noChange,
    Object? maxPrice = _noChange,
    Object? selectedQuickPrice = _noChange,
    Object? maxKilometers = _noChange,
    Object? selectedKmRange = _noChange,
    Object? selectedFuelType = _noChange,
    Object? selectedOwners = _noChange,
    Object? minYear = _noChange,
    Object? maxYear = _noChange,
    Object? selectedBikeAge = _noChange,
    Object? selectedSubCategory = _noChange,
    Object? selectedCondition = _noChange,
    Object? selectedSellerType = _noChange,
  }) {
    return ProductFilterState(
      category: identical(category, _noChange)
          ? _filterState.category
          : category as String,
      selectedBrand: identical(selectedBrand, _noChange)
          ? _filterState.selectedBrand
          : selectedBrand as String?,
      selectedSort: identical(selectedSort, _noChange)
          ? _filterState.selectedSort
          : selectedSort as String?,
      maxPrice: identical(maxPrice, _noChange)
          ? _filterState.maxPrice
          : maxPrice as double?,
      selectedQuickPrice: identical(selectedQuickPrice, _noChange)
          ? _filterState.selectedQuickPrice
          : selectedQuickPrice as String?,
      maxKilometers: identical(maxKilometers, _noChange)
          ? _filterState.maxKilometers
          : maxKilometers as double?,
      selectedKmRange: identical(selectedKmRange, _noChange)
          ? _filterState.selectedKmRange
          : selectedKmRange as String?,
      selectedFuelType: identical(selectedFuelType, _noChange)
          ? _filterState.selectedFuelType
          : selectedFuelType as String?,
      selectedOwners: identical(selectedOwners, _noChange)
          ? _filterState.selectedOwners
          : selectedOwners as List<String>,
      minYear: identical(minYear, _noChange)
          ? _filterState.minYear
          : minYear as int?,
      maxYear: identical(maxYear, _noChange)
          ? _filterState.maxYear
          : maxYear as int?,
      selectedBikeAge: identical(selectedBikeAge, _noChange)
          ? _filterState.selectedBikeAge
          : selectedBikeAge as String?,
      selectedSubCategory: identical(selectedSubCategory, _noChange)
          ? _filterState.selectedSubCategory
          : selectedSubCategory as String?,
      selectedCondition: identical(selectedCondition, _noChange)
          ? _filterState.selectedCondition
          : selectedCondition as String?,
      selectedSellerType: identical(selectedSellerType, _noChange)
          ? _filterState.selectedSellerType
          : selectedSellerType as String?,
    );
  }

  String? _normalizeString(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
