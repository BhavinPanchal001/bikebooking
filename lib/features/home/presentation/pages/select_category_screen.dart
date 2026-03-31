import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/presentation/controllers/select_category_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectCategoryScreen extends StatefulWidget {
  const SelectCategoryScreen({super.key});

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen> {
  late final SelectCategoryController _controller;
  late final bool _ownsController;
  bool _loadedRouteArguments = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SelectCategoryController>()) {
      _controller = Get.find<SelectCategoryController>();
      _ownsController = false;
    } else {
      _controller = Get.put(SelectCategoryController());
      _ownsController = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.bindCategories();
    });
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<SelectCategoryController>()) {
      Get.delete<SelectCategoryController>();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRouteArguments) {
      return;
    }

    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    _controller.setFocusedParentCategory(_readParentCategory(routeArguments));
    _loadedRouteArguments = true;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SelectCategoryController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, controller),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: controller.refreshCategories,
                    child: _buildBody(context, controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SelectCategoryController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C274C).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/Group 1171276172.png',
                          height: 15,
                          width: 15,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'search',
                          style: TextStyle(
                            color: Color(0xFFADB4C1),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/filter',
                    arguments: controller.focusedParentCategory,
                  );
                },
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/Group.png',
                      height: 17,
                      width: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SelectCategoryController controller,
  ) {
    if (controller.isLoading && controller.sections.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    if (controller.errorMessage != null && controller.sections.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.category_outlined,
            size: 56,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load categories',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF233A66),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: controller.refreshCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        child:
            controller.sections.isEmpty ? const SizedBox.shrink() : _buildSection(context, controller.sections.first),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    SelectCategorySection section,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sectionTitle(section.parentCategory),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF262A36),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _buildCategoryCard(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    SelectCategoryItem item,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/filter_result',
          arguments: item.routeArguments,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 94,
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // gradient: LinearGradient(
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                //   colors: [
                //     Colors.white.withOpacity(0.55),
                //     item.backgroundColor,
                //   ],
                // ),
              ),
              child: Stack(
                children: [
                  // Positioned(
                  //   top: -18,
                  //   left: -14,
                  //   child: Container(
                  //     width: 72,
                  //     height: 72,
                  //     decoration: BoxDecoration(
                  //       shape: BoxShape.circle,
                  //       color: Colors.white.withOpacity(0.22),
                  //     ),
                  //   ),
                  // ),
                  _buildCardArtwork(item),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF121926),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.countLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9F9F9F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionTitle(String parentCategory) {
    if (parentCategory == 'Bikes') {
      return 'Bike';
    }
    if (parentCategory == 'Scooter') {
      return 'Scooter';
    }
    return parentCategory;
  }

  String _readParentCategory(dynamic routeArguments) {
    if (routeArguments is String) {
      return routeArguments;
    }

    if (routeArguments is Map<String, dynamic>) {
      final category = routeArguments['category'];
      if (category is String && category.trim().isNotEmpty) {
        return category;
      }
    }

    return 'Bikes';
  }

  Widget _buildCardArtwork(SelectCategoryItem item) {
    switch (item.categoryKey) {
      case 'Sports Bikes':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278018.png',
          width: 150,
        );
      case 'Cruiser Bikes':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278020.png',
          width: 150,
          // width: 150,
        );
      case 'Commuter Bikes':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278021.png',
          width: 150,
          // alignment: Alignment.centerLeft,
        );
      case 'Adventure Bikes':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278022.png',
          width: 150,
          // rotation: 0.04,
        );
      case 'Electric Bikes':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278023.png',
          width: 150,
          // rotation: 0.04,
        );
      case 'Petrol Scooters':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278024.png',
          width: 150,
          // rotation: 0.04,
        );
      case 'Electric Scooters':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278025.png',
          width: 150,
          // rotation: 0.04,
        );
      case 'Maxi Scooters':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278026.png',
          width: 150,
          // rotation: 0.04,
        );
      case 'Ladies Scooters':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278027.png',
          width: 150,
          // rotation: 0.04,
        );
      case 'Moped Scooters':
        return _buildAssetArtwork(
          assetPath: 'assets/images/Group 1171278028.png',
          width: 150,
          // rotation: 0.04,
        );
      default:
        return _buildIconArtwork(
          icon: item.icon,
          size: 48,
        );
    }
  }

  Widget _buildAssetArtwork({
    required String assetPath,
    required double width,
    double rotation = 0,
    Alignment alignment = Alignment.center,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: rotation,
        child: Image.asset(
          assetPath,
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildIconArtwork({
    required IconData icon,
    required double size,
  }) {
    return Center(
      child: Icon(
        icon,
        size: size,
        color: const Color(0xFF2F3645),
      ),
    );
  }
}
