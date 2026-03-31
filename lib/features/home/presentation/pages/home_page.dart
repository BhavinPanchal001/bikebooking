import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/home_products_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/bike_card.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/custom_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final HomeProductsController _homeController;
  late final NotificationsController _notificationsController;

  @override
  void initState() {
    super.initState();

    // Ensure controllers are registered.
    _homeController = Get.isRegistered<HomeProductsController>()
        ? Get.find<HomeProductsController>()
        : Get.put(HomeProductsController());

    _notificationsController = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());

    // Defer controller updates until after the first frame so GetBuilder
    // listeners are attached before we call update().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _homeController.loadProducts();
      _notificationsController.bindNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FBFF),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar & Search
            _buildTopBanner(),

            // Scrollable Content
            Expanded(
              child: GetBuilder<HomeProductsController>(
                builder: (controller) {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (controller.errorMessage != null) {
                    return _buildErrorView(controller);
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => controller.loadProducts(showLoader: false),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Promo Banner
                            _buildPromoBanner(),
                            const SizedBox(height: 15),

                            // Top Categories
                            _buildSectionHeader('Top Categories'),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildCategoryItem(
                                      'Bikes', 'assets/images/Group 1171278014.png', const Color(0xFFD4E7C5)),
                                  _buildCategoryItem(
                                      'Scooter', 'assets/images/Group 1171278015.png', const Color(0xFFFFD1A5)),
                                  _buildCategoryItem(
                                      'Accessories', 'assets/images/Group 1171278016.png', const Color(0xFFC9C9EB)),
                                  _buildCategoryItem(
                                      'Spare Parts', 'assets/images/Group 1171278017.png', const Color(0xFFB9E5F3)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Recently Viewed Items
                            if (controller.recentlyViewedProducts.isNotEmpty) ...[
                              _buildSectionHeader(
                                'Recently Viewed Items',
                                onViewAll: () => Navigator.pushNamed(context, '/filter_result'),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: controller.recentlyViewedProducts
                                      .map((product) => BikeCard(
                                            product: product,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/bike_detail',
                                                arguments: product,
                                              );
                                            },
                                          ))
                                      .toList(growable: false),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Just Added
                            _buildSectionHeader(
                              'Just Added',
                              onViewAll: () => Navigator.pushNamed(context, '/filter_result'),
                            ),
                            const SizedBox(height: 12),
                            if (controller.justAddedProducts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No products yet. Be the first to list!',
                                    style: TextStyle(
                                      color: Color(0xFF5E6E8C),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: controller.justAddedProducts
                                      .map((product) => BikeCard(
                                            product: product,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/bike_detail',
                                                arguments: product,
                                              );
                                            },
                                          ))
                                      .toList(growable: false),
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTopBanner() {
    return Container(
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
              GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: const Icon(Icons.menu, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 8),
              // Bikenest Logo
              Row(
                children: [
                  Image.asset('assets/images/homebike.png', height: 25, width: 25),
                  const SizedBox(width: 1),
                  Image.asset('assets/images/bokenestimage.png', height: 30, width: 100),
                ],
              ),
              const Spacer(),

              // Notifications with unread badge
              GetBuilder<NotificationsController>(
                builder: (notifController) {
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          'assets/images/Group 1171278003.png',
                          height: 20,
                          width: 20,
                        ),
                        if (notifController.unreadCount > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                notifController.unreadCount > 99 ? '99+' : '${notifController.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/messages'),
                child: Image.asset('assets/images/Vector (1).png', height: 20, width: 20),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/favorites'),
                child: Image.asset('assets/images/Vector (2).png', height: 20, width: 20),
              ),
              const SizedBox(width: 12),

              // Dynamic profile avatar
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile_overview'),
                child: GetBuilder<LoginController>(
                  builder: (loginController) {
                    final photoUrl = loginController.currentUserProfile?.photoUrl ?? '';
                    return Container(
                      height: 34,
                      width: 34,
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildDefaultAvatar(loginController),
                              )
                            : _buildDefaultAvatar(loginController),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/search');
            },
            child: Container(
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
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
                      color: Color(0xFFB3B3B3),
                      fontSize: 15,
                      fontFamily: 'Neue Montreal',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fallback avatar showing the user's initials.
  Widget _buildDefaultAvatar(LoginController controller) {
    final name = controller.currentUserProfile?.displayName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: const Color(0xFFEAF0FB),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF233A66),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset('assets/images/Group 1171278220.png', fit: BoxFit.cover),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'View All',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, String imagePath, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          if (title == 'Bikes' || title == 'Scooter') {
            Navigator.pushNamed(
              context,
              '/select_category',
              arguments: title,
            );
          } else if (title == 'Accessories' || title == 'Spare Parts') {
            Navigator.pushNamed(context, '/filter_result', arguments: title);
          } else {
            Navigator.pushNamed(
              context,
              '/select_category',
              arguments: 'Bikes',
            );
          }
        },
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 90,
              child: Center(
                child: Image.asset(
                  imagePath,
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF262A36))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(HomeProductsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFF5E6E8C),
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5E6E8C),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadProducts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
