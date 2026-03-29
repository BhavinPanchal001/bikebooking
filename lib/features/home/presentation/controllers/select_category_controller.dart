import 'dart:async';

import 'package:bikebooking/core/constants/product_categories.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectCategoryController extends GetxController {
  SelectCategoryController({
    ProductFirestoreService? firestoreService,
    SellerActionFirestoreService? sellerActionService,
    LoginController? loginController,
  })  : _firestoreService = firestoreService ?? ProductFirestoreService(),
        _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  static const List<String> _parentOrder = <String>[
    ProductCategoryCatalog.bikes,
    ProductCategoryCatalog.scooter,
    ProductCategoryCatalog.accessories,
    ProductCategoryCatalog.spareParts,
  ];

  static const List<String> _bikeOrder =
      ProductCategoryCatalog.bikeSubCategories;

  static const List<String> _scooterOrder =
      ProductCategoryCatalog.scooterSubCategories;

  final ProductFirestoreService _firestoreService;
  final SellerActionFirestoreService _sellerActionService;
  final LoginController _loginController;
  StreamSubscription<List<ProductModel>>? _subscription;
  List<ProductModel> _allProducts = const <ProductModel>[];
  Set<String> _hiddenUserIds = <String>{};

  String _focusedParentCategory = 'Bikes';
  String get focusedParentCategory => _focusedParentCategory;

  List<SelectCategorySection> _sections = <SelectCategorySection>[];
  List<SelectCategorySection> get sections => List.unmodifiable(_sections);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setFocusedParentCategory(String? value) {
    final normalized = _normalizeParentCategory(value);
    if (_focusedParentCategory == normalized) {
      return;
    }

    _focusedParentCategory = normalized;
    _sections = _buildSections(_allProducts);
    update();
  }

  Future<void> bindCategories() async {
    if (_subscription != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      _hiddenUserIds = await _loadHiddenUserIds();
    } catch (error, stackTrace) {
      _hiddenUserIds = <String>{};
      debugPrint('Error loading hidden users: $error\n$stackTrace');
    }

    _subscription = _firestoreService.watchProducts().listen(
      (products) {
        _allProducts = _filterHiddenProducts(products);
        _sections = _buildSections(_allProducts);
        _isLoading = false;
        _errorMessage = null;
        update();
      },
      onError: (error, stackTrace) {
        _allProducts = const <ProductModel>[];
        _sections = _buildSections(const <ProductModel>[]);
        _isLoading = false;
        _errorMessage = 'Unable to load categories right now.';
        debugPrint('Error loading live categories: $error\n$stackTrace');
        update();
      },
    );
  }

  Future<void> refreshCategories() async {
    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      _hiddenUserIds = await _loadHiddenUserIds();
      final products = await _firestoreService.getProducts();
      _allProducts = _filterHiddenProducts(products);
      _sections = _buildSections(_allProducts);
      _errorMessage = null;
    } catch (error, stackTrace) {
      _allProducts = const <ProductModel>[];
      _sections = _buildSections(const <ProductModel>[]);
      _errorMessage = 'Unable to load categories right now.';
      debugPrint('Error refreshing categories: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      update();
    }
  }

  List<SelectCategorySection> _buildSections(List<ProductModel> products) {
    final grouped = <String, Map<String, int>>{
      for (final parent in _parentOrder) parent: <String, int>{},
    };

    for (final product in products) {
      final parentCategory = _resolveParentCategory(product);
      final childCategory = _resolveChildCategory(product, parentCategory);
      if (childCategory == null) {
        continue;
      }
      final parentMap = grouped.putIfAbsent(
        parentCategory,
        () => <String, int>{},
      );
      parentMap.update(childCategory, (value) => value + 1, ifAbsent: () => 1);
    }

    final allSections = _parentOrder.map((parentCategory) {
      final counts = grouped[parentCategory] ?? <String, int>{};
      final orderValues = _orderFor(parentCategory);

      final items = orderValues
          .map(
            (categoryKey) => _buildItem(
              parentCategory: parentCategory,
              categoryKey: categoryKey,
              count: counts[categoryKey] ?? 0,
            ),
          )
          .toList(growable: false);

      final totalCount = items.fold<int>(
        0,
        (sum, item) => sum + item.count,
      );

      return SelectCategorySection(
        parentCategory: parentCategory,
        totalCount: totalCount,
        items: items,
      );
    }).toList(growable: false);

    return allSections
        .where((section) => section.parentCategory == _focusedParentCategory)
        .toList(growable: false);
  }

  String _resolveParentCategory(ProductModel product) {
    return ProductCategoryCatalog.baseCategoryFor(product.category);
  }

  String? _resolveChildCategory(ProductModel product, String parentCategory) {
    if (parentCategory == 'Accessories' || parentCategory == 'Spare Parts') {
      final subCategory = product.subCategory?.trim() ?? '';
      if (subCategory.isNotEmpty) {
        return subCategory;
      }
      return _fallbackCategoryFor(parentCategory);
    }

    if (parentCategory == 'Bikes' || parentCategory == 'Scooter') {
      final resolvedSubCategory =
          ProductCategoryCatalog.resolveVehicleSubCategory(
        category: product.category,
        subCategory: product.subCategory,
        fuelType: product.fuelType,
      );
      if (resolvedSubCategory != null &&
          ProductCategoryCatalog.baseCategoryFor(resolvedSubCategory) ==
              parentCategory) {
        return resolvedSubCategory;
      }
    }

    return null;
  }

  String _fallbackCategoryFor(String parentCategory) {
    return switch (parentCategory) {
      'Bikes' => 'Bikes',
      'Scooter' => 'Scooter',
      'Accessories' => 'Accessories',
      'Spare Parts' => 'Spare Parts',
      _ => parentCategory,
    };
  }

  List<String> _orderFor(String parentCategory) {
    if (parentCategory == 'Bikes') {
      return _bikeOrder;
    }
    if (parentCategory == 'Scooter') {
      return _scooterOrder;
    }
    return <String>[_fallbackCategoryFor(parentCategory)];
  }

  SelectCategoryItem _buildItem({
    required String parentCategory,
    required String categoryKey,
    required int count,
  }) {
    final style = _styleFor(parentCategory, categoryKey);
    return SelectCategoryItem(
      parentCategory: parentCategory,
      categoryKey: categoryKey,
      title: _titleFor(parentCategory, categoryKey),
      count: count,
      countLabel: _countLabelFor(count),
      icon: style.icon,
      backgroundColor: style.backgroundColor,
      routeArguments: _routeArgumentsFor(parentCategory, categoryKey),
    );
  }

  String _titleFor(String parentCategory, String categoryKey) {
    if (categoryKey == 'Bikes') {
      return 'Bikes';
    }
    if (categoryKey == 'Scooter') {
      return 'Scooters';
    }
    if (categoryKey == 'Accessories') {
      return 'Accessories';
    }
    if (categoryKey == 'Spare Parts') {
      return 'Spare Parts';
    }
    return categoryKey;
  }

  dynamic _routeArgumentsFor(String parentCategory, String categoryKey) {
    if (parentCategory == 'Bikes' || parentCategory == 'Scooter') {
      return <String, dynamic>{
        'category': parentCategory,
        'selectedSubCategory': categoryKey,
      };
    }

    if (parentCategory == 'Accessories' || parentCategory == 'Spare Parts') {
      if (categoryKey == parentCategory) {
        return <String, dynamic>{
          'category': parentCategory,
        };
      }
      return <String, dynamic>{
        'category': parentCategory,
        'selectedSubCategory': categoryKey,
      };
    }

    return categoryKey;
  }

  String _countLabelFor(int count) {
    return '$count ${count == 1 ? 'Product' : 'Products'}';
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

  String _normalizeParentCategory(String? value) {
    return ProductCategoryCatalog.baseCategoryFor(value);
  }

  _CategoryItemStyle _styleFor(String parentCategory, String categoryKey) {
    final vehicleOption = ProductCategoryCatalog.optionForLabel(categoryKey);
    if (vehicleOption != null) {
      return _CategoryItemStyle(
        backgroundColor: vehicleOption.backgroundColor,
        icon: vehicleOption.icon,
      );
    }
    if (parentCategory == 'Accessories') {
      return const _CategoryItemStyle(
        backgroundColor: Color(0xFFDDEBFF),
        icon: Icons.shield_outlined,
      );
    }
    if (parentCategory == 'Spare Parts') {
      return const _CategoryItemStyle(
        backgroundColor: Color(0xFFE7E2FF),
        icon: Icons.build_circle_outlined,
      );
    }
    return const _CategoryItemStyle(
      backgroundColor: Color(0xFFD4E7C5),
      icon: Icons.directions_bike_rounded,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

class SelectCategorySection {
  const SelectCategorySection({
    required this.parentCategory,
    required this.totalCount,
    required this.items,
  });

  final String parentCategory;
  final int totalCount;
  final List<SelectCategoryItem> items;
}

class SelectCategoryItem {
  const SelectCategoryItem({
    required this.parentCategory,
    required this.categoryKey,
    required this.title,
    required this.count,
    required this.countLabel,
    required this.icon,
    required this.backgroundColor,
    required this.routeArguments,
  });

  final String parentCategory;
  final String categoryKey;
  final String title;
  final int count;
  final String countLabel;
  final IconData icon;
  final Color backgroundColor;
  final dynamic routeArguments;
}

class _CategoryItemStyle {
  const _CategoryItemStyle({
    required this.backgroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final IconData icon;
}
