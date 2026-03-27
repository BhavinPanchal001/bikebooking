import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';

class ListProductController extends GetxController {
  final ProductFirestoreService _firestoreService = ProductFirestoreService();

  // ── Step 1: Category ──
  String _category = '';
  String get category => _category;

  void setCategory(String value) {
    _category = value;
    update();
  }

  // ── Step 2: Images (URLs — placeholder for now) ──
  List<String> _imageUrls = [];
  List<String> get imageUrls => _imageUrls;

  void setImageUrls(List<String> urls) {
    _imageUrls = urls;
    update();
  }

  // ── Step 3: Bike / Scooter Detail Fields ──
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController kilometerController = TextEditingController();

  String _brand = '';
  String get brand => _brand;

  void setBrand(String value) {
    _brand = value;
    update();
  }

  int? _year;
  int? get year => _year;

  void setYear(int value) {
    _year = value;
    update();
  }

  String? _fuelType;
  String? get fuelType => _fuelType;

  void setFuelType(String value) {
    _fuelType = value;
    update();
  }

  int? _numberOfOwners;
  int? get numberOfOwners => _numberOfOwners;

  void setNumberOfOwners(int value) {
    _numberOfOwners = value;
    update();
  }

  // ── Step 3 (alt): Accessories / Spare Parts specific ──
  String? _subCategory;
  String? get subCategory => _subCategory;

  void setSubCategory(String value) {
    _subCategory = value;
    update();
  }

  String? _condition;
  String? get condition => _condition;

  void setCondition(String value) {
    _condition = value;
    update();
  }

  String? _sellerType;
  String? get sellerType => _sellerType;

  void setSellerType(String value) {
    _sellerType = value;
    update();
  }

  // ── Step 4: Price & Location ──
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // ── Loading state ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Submit Product ──
  Future<bool> submitProduct() async {
    _isLoading = true;
    update();

    try {
      final user = FirebaseAuth.instance.currentUser;

      final product = ProductModel(
        category: _category,
        title: titleController.text.trim(),
        brand: _brand,
        year: _year,
        description: descriptionController.text.trim(),
        price: double.tryParse(priceController.text.trim()),
        location: locationController.text.trim(),
        imageUrls: _imageUrls,
        sellerId: user?.uid ?? '',
        sellerName: user?.displayName ?? '',
        status: 'active',
        // Bike / Scooter fields
        fuelType: _fuelType,
        kilometerDriven: int.tryParse(kilometerController.text.trim()),
        numberOfOwners: _numberOfOwners,
        // Accessories / Spare Parts fields
        subCategory: _subCategory,
        condition: _condition,
        sellerType: _sellerType,
      );

      await _firestoreService.addProduct(product);

      _isLoading = false;
      update();
      return true;
    } catch (e) {
      _isLoading = false;
      update();
      debugPrint('Error submitting product: $e');
      return false;
    }
  }

  /// Resets all form fields to their initial state.
  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    kilometerController.clear();
    priceController.clear();
    locationController.clear();
    _category = '';
    _brand = '';
    _year = null;
    _fuelType = null;
    _numberOfOwners = null;
    _subCategory = null;
    _condition = null;
    _sellerType = null;
    _imageUrls = [];
    _isLoading = false;
    update();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    kilometerController.dispose();
    priceController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
