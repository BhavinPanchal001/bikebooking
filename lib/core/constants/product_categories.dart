import 'package:flutter/material.dart';

class VehicleSubCategoryOption {
  const VehicleSubCategoryOption({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = const Color(0xFF233A66),
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
}

class ProductCategoryCatalog {
  static const String bikes = 'Bikes';
  static const String scooter = 'Scooter';
  static const String accessories = 'Accessories';
  static const String spareParts = 'Spare Parts';

  static const List<String> parentCategories = <String>[
    bikes,
    scooter,
    accessories,
    spareParts,
  ];

  static const List<String> bikeSubCategories = <String>[
    'Sports Bikes',
    'Cruiser Bikes',
    'Commuter Bikes',
    'Adventure Bikes',
    'Electric Bikes',
  ];

  static const List<String> scooterSubCategories = <String>[
    'Petrol Scooters',
    'Electric Scooters',
    'Maxi Scooters',
    'Ladies Scooters',
    'Moped Scooters',
  ];

  static const Map<String, int> figmaFallbackCounts = <String, int>{
    'Sports Bikes': 76,
    'Cruiser Bikes': 56,
    'Commuter Bikes': 98,
    'Adventure Bikes': 45,
    'Electric Bikes': 45,
    'Petrol Scooters': 76,
    'Electric Scooters': 56,
    'Maxi Scooters': 98,
    'Ladies Scooters': 45,
    'Moped Scooters': 45,
  };

  static const List<VehicleSubCategoryOption> bikeOptions =
      <VehicleSubCategoryOption>[
        VehicleSubCategoryOption(
          label: 'Sports Bikes',
          icon: Icons.sports_motorsports_rounded,
          backgroundColor: Color(0xFFD4E7C5),
        ),
        VehicleSubCategoryOption(
          label: 'Cruiser Bikes',
          icon: Icons.two_wheeler_rounded,
          backgroundColor: Color(0xFFFFD1A5),
        ),
        VehicleSubCategoryOption(
          label: 'Commuter Bikes',
          icon: Icons.commute_rounded,
          backgroundColor: Color(0xFFC9C9EB),
        ),
        VehicleSubCategoryOption(
          label: 'Adventure Bikes',
          icon: Icons.terrain_rounded,
          backgroundColor: Color(0xFFB9E5F3),
        ),
        VehicleSubCategoryOption(
          label: 'Electric Bikes',
          icon: Icons.electric_bike_rounded,
          backgroundColor: Color(0xFFFFD580),
        ),
      ];

  static const List<VehicleSubCategoryOption> scooterOptions =
      <VehicleSubCategoryOption>[
        VehicleSubCategoryOption(
          label: 'Petrol Scooters',
          icon: Icons.moped_rounded,
          backgroundColor: Color(0xFFD4E7C5),
        ),
        VehicleSubCategoryOption(
          label: 'Electric Scooters',
          icon: Icons.electric_scooter_rounded,
          backgroundColor: Color(0xFFFFD1A5),
        ),
        VehicleSubCategoryOption(
          label: 'Maxi Scooters',
          icon: Icons.motorcycle_rounded,
          backgroundColor: Color(0xFFC9C9EB),
        ),
        VehicleSubCategoryOption(
          label: 'Ladies Scooters',
          icon: Icons.two_wheeler_rounded,
          backgroundColor: Color(0xFFB9E5F3),
        ),
        VehicleSubCategoryOption(
          label: 'Moped Scooters',
          icon: Icons.pedal_bike_rounded,
          backgroundColor: Color(0xFFFFD580),
        ),
      ];

  static bool isBikeParent(String? value) => value?.trim() == bikes;

  static bool isScooterParent(String? value) =>
      value?.trim() == scooter || value?.trim() == 'Scooters';

  static bool isAccessoryParent(String? value) => value?.trim() == accessories;

  static bool isSparePartsParent(String? value) => value?.trim() == spareParts;

  static bool isBikeSubCategory(String? value) =>
      bikeSubCategories.contains(value?.trim() ?? '');

  static bool isScooterSubCategory(String? value) =>
      scooterSubCategories.contains(value?.trim() ?? '');

  static bool isVehicleParent(String? value) =>
      isBikeParent(value) || isScooterParent(value);

  static bool isVehicleSubCategory(String? value) =>
      isBikeSubCategory(value) || isScooterSubCategory(value);

  static bool isVehicleCategory(String? value) =>
      isVehicleParent(value) || isVehicleSubCategory(value);

  static String baseCategoryFor(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return bikes;
    }
    if (isBikeParent(trimmed) || isBikeSubCategory(trimmed)) {
      return bikes;
    }
    if (isScooterParent(trimmed) || isScooterSubCategory(trimmed)) {
      return scooter;
    }
    if (isAccessoryParent(trimmed)) {
      return accessories;
    }
    if (isSparePartsParent(trimmed)) {
      return spareParts;
    }
    return bikes;
  }

  static List<String> vehicleSubCategoriesFor(String? category) {
    final baseCategory = baseCategoryFor(category);
    if (baseCategory == bikes) {
      return bikeSubCategories;
    }
    if (baseCategory == scooter) {
      return scooterSubCategories;
    }
    return const <String>[];
  }

  static List<VehicleSubCategoryOption> vehicleOptionsFor(String? category) {
    final baseCategory = baseCategoryFor(category);
    if (baseCategory == bikes) {
      return bikeOptions;
    }
    if (baseCategory == scooter) {
      return scooterOptions;
    }
    return const <VehicleSubCategoryOption>[];
  }

  static VehicleSubCategoryOption? optionForLabel(String? value) {
    final trimmed = value?.trim() ?? '';
    for (final option in bikeOptions) {
      if (option.label == trimmed) {
        return option;
      }
    }
    for (final option in scooterOptions) {
      if (option.label == trimmed) {
        return option;
      }
    }
    return null;
  }

  static String? resolveVehicleSubCategory({
    required String category,
    String? subCategory,
    String? fuelType,
  }) {
    final baseCategory = baseCategoryFor(category);
    if (baseCategory != bikes && baseCategory != scooter) {
      return null;
    }

    final availableOptions = vehicleSubCategoriesFor(baseCategory);
    final normalizedSubCategory = subCategory?.trim() ?? '';
    if (availableOptions.contains(normalizedSubCategory)) {
      return normalizedSubCategory;
    }

    final normalizedCategory = category.trim();
    if (availableOptions.contains(normalizedCategory)) {
      return normalizedCategory;
    }

    if (baseCategory == scooter) {
      final normalizedFuelType = fuelType?.trim().toLowerCase() ?? '';
      if (normalizedFuelType == 'electric') {
        return 'Electric Scooters';
      }
      if (normalizedFuelType == 'petrol') {
        return 'Petrol Scooters';
      }
    }

    return null;
  }

  static bool matchesVehicleSubCategory({
    required String selectedSubCategory,
    required String category,
    String? subCategory,
    String? fuelType,
  }) {
    final resolvedSubCategory = resolveVehicleSubCategory(
      category: category,
      subCategory: subCategory,
      fuelType: fuelType,
    );
    return resolvedSubCategory?.trim().toLowerCase() ==
        selectedSubCategory.trim().toLowerCase();
  }
}
