import 'package:bikebooking/core/constants/product_categories.dart';

class ProductFilterState {
  ProductFilterState({
    required this.category,
    this.selectedBrand,
    this.selectedSort,
    this.maxPrice,
    this.selectedQuickPrice,
    this.maxKilometers,
    this.selectedKmRange,
    this.selectedFuelType,
    this.selectedOwners = const [],
    this.minYear,
    this.maxYear,
    this.selectedBikeAge,
    this.selectedSubCategory,
    this.selectedCondition,
    this.selectedSellerType,
  });

  final String category;
  final String? selectedBrand;
  final String? selectedSort;
  final double? maxPrice;
  final String? selectedQuickPrice;
  final double? maxKilometers;
  final String? selectedKmRange;
  final String? selectedFuelType;
  final List<String> selectedOwners;
  final int? minYear;
  final int? maxYear;
  final String? selectedBikeAge;
  final String? selectedSubCategory;
  final String? selectedCondition;
  final String? selectedSellerType;

  static const List<String> bikeCategories = <String>[
    ProductCategoryCatalog.bikes,
    ...ProductCategoryCatalog.bikeSubCategories,
  ];

  static const List<String> scooterCategories = <String>[
    ProductCategoryCatalog.scooter,
    ...ProductCategoryCatalog.scooterSubCategories,
  ];

  factory ProductFilterState.fromRouteArguments(dynamic arguments) {
    if (arguments is ProductFilterState) {
      return arguments;
    }

    if (arguments is String && arguments.trim().isNotEmpty) {
      return ProductFilterState(category: arguments.trim());
    }

    if (arguments is Map<String, dynamic>) {
      return ProductFilterState(
        category: (arguments['category'] as String?)?.trim().isNotEmpty == true
            ? (arguments['category'] as String).trim()
            : 'Bikes',
        selectedBrand: _readString(arguments['selectedBrand']),
        selectedSort: _readString(arguments['selectedSort']),
        maxPrice: _readDouble(arguments['maxPrice']),
        selectedQuickPrice: _readString(arguments['selectedQuickPrice']),
        maxKilometers: _readDouble(arguments['maxKilometers']),
        selectedKmRange: _readString(arguments['selectedKmRange']),
        selectedFuelType: _readString(arguments['selectedFuelType']),
        selectedOwners: _readStringList(arguments['selectedOwners']),
        minYear: _readInt(arguments['minYear']),
        maxYear: _readInt(arguments['maxYear']),
        selectedBikeAge: _readString(arguments['selectedBikeAge']),
        selectedSubCategory: _readString(arguments['selectedSubCategory']),
        selectedCondition: _readString(arguments['selectedCondition']),
        selectedSellerType: _readString(arguments['selectedSellerType']),
      );
    }

    return ProductFilterState(category: 'Bikes');
  }

  String get baseCategory {
    return ProductCategoryCatalog.baseCategoryFor(category);
  }

  bool get isBikeLike => baseCategory == 'Bikes' || baseCategory == 'Scooter';

  bool get isAccessoryLike =>
      baseCategory == 'Accessories' || baseCategory == 'Spare Parts';

  String? get selectedVehicleSubCategory {
    if (!isBikeLike) {
      return null;
    }

    final allowedOptions = ProductCategoryCatalog.vehicleSubCategoriesFor(
      baseCategory,
    );
    final explicitSubCategory = selectedSubCategory?.trim() ?? '';
    if (allowedOptions.contains(explicitSubCategory)) {
      return explicitSubCategory;
    }

    final trimmedCategory = category.trim();
    if (trimmedCategory.isNotEmpty &&
        trimmedCategory != baseCategory &&
        allowedOptions.contains(trimmedCategory)) {
      return trimmedCategory;
    }

    return null;
  }

  bool get hasSpecificBikeCategory =>
      selectedVehicleSubCategory != null;

  List<String> get queryCategories {
    if (isAccessoryLike) {
      return <String>[baseCategory];
    }

    if (baseCategory == 'Scooter') {
      final selectedVehicleCategory = selectedVehicleSubCategory;
      if (selectedVehicleCategory != null) {
        return <String>[ProductCategoryCatalog.scooter, selectedVehicleCategory];
      }
      return scooterCategories;
    }

    if (baseCategory == 'Bikes') {
      final selectedVehicleCategory = selectedVehicleSubCategory;
      if (selectedVehicleCategory != null) {
        return <String>[ProductCategoryCatalog.bikes, selectedVehicleCategory];
      }
      return bikeCategories;
    }

    return <String>[baseCategory];
  }

  String get queryCategory {
    return queryCategories.first;
  }

  String get selectedCategoryLabel {
    final explicitSubCategory = selectedSubCategory?.trim() ?? '';
    if (!isBikeLike && explicitSubCategory.isNotEmpty) {
      return explicitSubCategory;
    }

    final vehicleSubCategory = selectedVehicleSubCategory;
    if (vehicleSubCategory != null) {
      return vehicleSubCategory;
    }

    final trimmedCategory = category.trim();
    if (trimmedCategory.isNotEmpty) {
      if (trimmedCategory == 'Scooter') {
        return 'Scooters';
      }
      return trimmedCategory;
    }

    if (baseCategory == 'Scooter') {
      return 'Scooters';
    }

    return baseCategory;
  }

  int get activeFilterCount {
    var count = 0;
    if (_hasValue(selectedBrand)) count++;
    if (_hasValue(selectedSort)) count++;
    if (maxPrice != null || _hasValue(selectedQuickPrice)) count++;
    if (maxKilometers != null || _hasValue(selectedKmRange)) count++;
    if (_hasValue(selectedFuelType)) count++;
    if (selectedOwners.isNotEmpty) count++;
    if (minYear != null || maxYear != null || _hasValue(selectedBikeAge)) {
      count++;
    }
    if (_hasValue(selectedSubCategory)) count++;
    if (_hasValue(selectedCondition)) count++;
    if (_hasValue(selectedSellerType)) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  List<String> buildSummaryChips() {
    final chips = <String>[];
    if (_hasValue(selectedBrand)) {
      chips.add(selectedBrand!);
    }
    if (_hasValue(selectedQuickPrice)) {
      chips.add(selectedQuickPrice!);
    } else if (maxPrice != null) {
      chips.add('Up to Rs.${maxPrice!.round()}');
    }
    if (_hasValue(selectedKmRange)) {
      chips.add(selectedKmRange!);
    } else if (maxKilometers != null) {
      chips.add('Up to ${maxKilometers!.round()} km');
    }
    if (_hasValue(selectedFuelType)) {
      chips.add(selectedFuelType!);
    }
    if (selectedOwners.isNotEmpty) {
      chips.add(selectedOwners.join(', '));
    }
    if (_hasValue(selectedBikeAge)) {
      chips.add(selectedBikeAge!);
    } else if (minYear != null || maxYear != null) {
      final minLabel = minYear?.toString() ?? 'Any';
      final maxLabel = maxYear?.toString() ?? 'Any';
      chips.add('$minLabel-$maxLabel');
    }
    if (_hasValue(selectedSubCategory)) {
      chips.add(selectedSubCategory!);
    }
    if (_hasValue(selectedCondition)) {
      chips.add(selectedCondition!);
    }
    if (_hasValue(selectedSellerType)) {
      chips.add(selectedSellerType!);
    }
    if (_hasValue(selectedSort)) {
      chips.add(selectedSort!);
    }
    return chips;
  }

  ProductFilterState copyWith({
    String? category,
    String? selectedBrand,
    String? selectedSort,
    double? maxPrice,
    String? selectedQuickPrice,
    double? maxKilometers,
    String? selectedKmRange,
    String? selectedFuelType,
    List<String>? selectedOwners,
    int? minYear,
    int? maxYear,
    String? selectedBikeAge,
    String? selectedSubCategory,
    String? selectedCondition,
    String? selectedSellerType,
  }) {
    return ProductFilterState(
      category: category ?? this.category,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      selectedSort: selectedSort ?? this.selectedSort,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedQuickPrice: selectedQuickPrice ?? this.selectedQuickPrice,
      maxKilometers: maxKilometers ?? this.maxKilometers,
      selectedKmRange: selectedKmRange ?? this.selectedKmRange,
      selectedFuelType: selectedFuelType ?? this.selectedFuelType,
      selectedOwners: selectedOwners ?? this.selectedOwners,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      selectedBikeAge: selectedBikeAge ?? this.selectedBikeAge,
      selectedSubCategory: selectedSubCategory ?? this.selectedSubCategory,
      selectedCondition: selectedCondition ?? this.selectedCondition,
      selectedSellerType: selectedSellerType ?? this.selectedSellerType,
    );
  }

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}
