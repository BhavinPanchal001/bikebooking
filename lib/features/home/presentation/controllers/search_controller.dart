import 'dart:async';

import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchController extends GetxController {
  SearchController({
    ProductFirestoreService? firestoreService,
    FavoritesController? favoritesController,
    SellerActionFirestoreService? sellerActionService,
    LoginController? loginController,
  })  : _firestoreService = firestoreService ?? ProductFirestoreService(),
        _favoritesController =
            favoritesController ?? Get.find<FavoritesController>(),
        _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  final ProductFirestoreService _firestoreService;
  final FavoritesController _favoritesController;
  final SellerActionFirestoreService _sellerActionService;
  final LoginController _loginController;

  static const int _maxRecentSearches = 8;
  static const int _minRecentSearchLength = 2;

  final TextEditingController searchTextController = TextEditingController();

  Timer? _searchDebounce;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ProductModel> _allProducts = [];
  Set<String> _hiddenUserIds = <String>{};
  List<ProductModel> _searchResults = [];
  List<ProductModel> get searchResults => List.unmodifiable(_searchResults);

  List<ProductModel> _recommendedProducts = [];
  List<ProductModel> get recommendedProducts =>
      List.unmodifiable(_recommendedProducts);

  List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  String _currentQuery = '';
  String get currentQuery => _currentQuery;
  bool get hasQuery => _currentQuery.trim().isNotEmpty;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      _recentSearches = await _loadRecentSearches();
      _hiddenUserIds = await _loadHiddenUserIds();
      _allProducts =
          _filterHiddenProducts(await _firestoreService.getProducts());
      _rebuildRecommendations();

      if (hasQuery) {
        _searchResults = _filterProducts(_currentQuery);
      } else {
        _searchResults = [];
      }
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to load search data right now.';
      debugPrint('Error loading search data: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      update();
    }
  }

  void onSearchChanged(String value) {
    _currentQuery = value.trim();
    _searchDebounce?.cancel();

    if (_currentQuery.isEmpty) {
      _searchResults = [];
      update();
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      _searchResults = _filterProducts(_currentQuery);
      if (_currentQuery.length >= _minRecentSearchLength) {
        await _saveRecentSearch(_currentQuery);
        _rebuildRecommendations();
      }
      update();
    });
  }

  Future<void> submitSearch([String? query]) async {
    final resolvedQuery = (query ?? searchTextController.text).trim();
    if (resolvedQuery.isEmpty) {
      return;
    }

    searchTextController.value = searchTextController.value.copyWith(
      text: resolvedQuery,
      selection: TextSelection.collapsed(offset: resolvedQuery.length),
    );
    _currentQuery = resolvedQuery;
    _searchResults = _filterProducts(resolvedQuery);
    await _saveRecentSearch(resolvedQuery);
    _rebuildRecommendations();
    update();
  }

  Future<void> applyRecentSearch(String query) async {
    await submitSearch(query);
  }

  Future<void> recordCurrentQuery() async {
    final resolvedQuery = _currentQuery.trim();
    if (resolvedQuery.isEmpty) {
      return;
    }
    await _saveRecentSearch(resolvedQuery);
    _rebuildRecommendations();
    update();
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.removeWhere(
      (item) => item.trim().toLowerCase() == query.trim().toLowerCase(),
    );
    await _persistRecentSearches();
    _rebuildRecommendations();
    update();
  }

  Future<void> clearSearch() async {
    _searchDebounce?.cancel();
    _currentQuery = '';
    _searchResults = [];
    searchTextController.clear();
    update();
  }

  void refreshRecommendations() {
    _rebuildRecommendations();
    update();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchTextController.dispose();
    super.onClose();
  }

  List<ProductModel> _filterProducts(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final tokens = normalizedQuery.split(RegExp(r'\s+'));
    final matchedProducts = _allProducts.where((product) {
      final haystack = _productSearchText(product);
      return tokens.every(haystack.contains);
    }).toList();

    matchedProducts.sort((first, second) {
      final firstScore = _searchScore(first, tokens);
      final secondScore = _searchScore(second, tokens);
      if (firstScore != secondScore) {
        return secondScore.compareTo(firstScore);
      }

      final firstCreatedAt =
          first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondCreatedAt =
          second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondCreatedAt.compareTo(firstCreatedAt);
    });

    return matchedProducts;
  }

  int _searchScore(ProductModel product, List<String> tokens) {
    final searchableText = _productSearchText(product);
    var score = 0;
    for (final token in tokens) {
      if (product.title.toLowerCase().contains(token)) {
        score += 6;
      }
      if (product.brand.toLowerCase().contains(token)) {
        score += 5;
      }
      if ((product.subCategory ?? '').toLowerCase().contains(token)) {
        score += 4;
      }
      if ((product.location ?? '').toLowerCase().contains(token)) {
        score += 2;
      }
      if (searchableText.contains(token)) {
        score += 1;
      }
    }
    return score;
  }

  void _rebuildRecommendations() {
    final activityQueries =
        _recentSearches.map((query) => query.toLowerCase()).toList();
    final favoriteProducts = _favoritesController.favorites;
    final favoriteIds = favoriteProducts
        .map((product) => product.id?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final userLocation = _loginController.currentUserProfile?.location?.address
            .trim()
            .toLowerCase() ??
        '';

    final scoredProducts = <({ProductModel product, int score})>[];

    for (final product in _allProducts) {
      if (favoriteIds.contains(product.id?.trim() ?? '')) {
        continue;
      }

      var score = 0;
      final searchableText = _productSearchText(product);

      for (final query in activityQueries) {
        if (query.isEmpty) {
          continue;
        }
        if (searchableText.contains(query)) {
          score += 6;
        }
        final tokens = query.split(RegExp(r'\s+'));
        score += _searchScore(product, tokens);
      }

      for (final favorite in favoriteProducts) {
        if (favorite.id != null &&
            product.id != null &&
            favorite.id == product.id) {
          continue;
        }
        if (favorite.category == product.category) {
          score += 4;
        }
        if (favorite.brand.trim().isNotEmpty &&
            favorite.brand.toLowerCase() == product.brand.toLowerCase()) {
          score += 5;
        }
        if ((favorite.subCategory ?? '').trim().isNotEmpty &&
            (favorite.subCategory ?? '').toLowerCase() ==
                (product.subCategory ?? '').toLowerCase()) {
          score += 3;
        }
      }

      if (userLocation.isNotEmpty &&
          (product.location ?? '').toLowerCase().contains(userLocation)) {
        score += 2;
      }

      scoredProducts.add((product: product, score: score));
    }

    scoredProducts.sort((first, second) {
      if (first.score != second.score) {
        return second.score.compareTo(first.score);
      }

      final firstCreatedAt =
          first.product.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondCreatedAt =
          second.product.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondCreatedAt.compareTo(firstCreatedAt);
    });

    final fallbackProducts = [..._allProducts]..sort((first, second) {
        final firstCreatedAt =
            first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final secondCreatedAt =
            second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return secondCreatedAt.compareTo(firstCreatedAt);
      });

    final hasActivity =
        activityQueries.isNotEmpty || favoriteProducts.isNotEmpty;
    final selectedProducts = hasActivity
        ? scoredProducts
            .where((entry) => entry.score > 0)
            .map((entry) => entry.product)
            .toList(growable: false)
        : fallbackProducts;

    _recommendedProducts =
        (selectedProducts.isNotEmpty ? selectedProducts : fallbackProducts)
            .take(8)
            .toList(growable: false);
  }

  Future<List<String>> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryKey = _recentSearchStorageKey;
    final storedSearches = _normalizeRecentSearches(
      prefs.getStringList(primaryKey) ?? const [],
    );
    if (storedSearches.isNotEmpty ||
        primaryKey == _guestRecentSearchStorageKey) {
      return storedSearches;
    }

    final guestSearches = _normalizeRecentSearches(
      prefs.getStringList(_guestRecentSearchStorageKey) ?? const [],
    );
    if (guestSearches.isNotEmpty) {
      await prefs.setStringList(primaryKey, guestSearches);
      await prefs.remove(_guestRecentSearchStorageKey);
    }
    return guestSearches;
  }

  List<String> _normalizeRecentSearches(List<String> searches) {
    return searches
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: true);
  }

  Future<void> _saveRecentSearch(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < _minRecentSearchLength) {
      return;
    }

    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == normalizedQuery.toLowerCase(),
    );
    _recentSearches.insert(0, normalizedQuery);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.take(_maxRecentSearches).toList();
    }

    await _persistRecentSearches();
  }

  Future<void> _persistRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryKey = _recentSearchStorageKey;
    await prefs.setStringList(primaryKey, _recentSearches);
    if (primaryKey != _guestRecentSearchStorageKey) {
      await prefs.remove(_guestRecentSearchStorageKey);
    }
  }

  String _productSearchText(ProductModel product) {
    return [
      product.title,
      product.brand,
      product.category,
      product.subCategory ?? '',
      product.location ?? '',
      product.description,
      product.fuelType ?? '',
      product.sellerType ?? '',
      product.condition ?? '',
    ].join(' ').toLowerCase();
  }

  String get _recentSearchStorageKey {
    final resolvedUserId = _loginController.resolvedCurrentUserId.trim();
    if (resolvedUserId.isNotEmpty) {
      return 'recent_searches_$resolvedUserId';
    }

    final chatUserId = _loginController.chatUserId.trim();
    if (chatUserId.isNotEmpty) {
      return 'recent_searches_$chatUserId';
    }

    return _guestRecentSearchStorageKey;
  }

  static const String _guestRecentSearchStorageKey = 'recent_searches_guest';

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
}
