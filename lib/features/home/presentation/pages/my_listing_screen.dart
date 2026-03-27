import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class MyListingScreen extends StatefulWidget {
  const MyListingScreen({super.key});

  @override
  State<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends State<MyListingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['showBoost'] == true) {
        _showBoostBottomSheet(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'My Listing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Listings List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildManagedListingCard(
                    context,
                    'Aprilia rs 125',
                    'RS.85,000',
                    '2024-57 km',
                    'Madhya Pradesh 458468',
                    'assets/images/bike.png',
                  ),
                  _buildManagedListingCard(
                    context,
                    'Humder 360',
                    'RS.85,000',
                    '2024-57 km',
                    'Madhya Pradesh 458468',
                    'assets/images/bike.png',
                  ),
                  _buildManagedListingCard(
                    context,
                    'Humder 360',
                    'RS.85,000',
                    '2024-57 km',
                    'Madhya Pradesh 458468',
                    'assets/images/bike.png',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildManagedListingCard(
    BuildContext context,
    String title,
    String price,
    String stats,
    String location,
    String imagePath,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bike Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 110,
                    height: 90,
                    color: Colors.white,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.directions_bike, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Bike Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5E6E8C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF151314),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF37474F)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF37474F),
                              ),
                              overflow: TextOverflow.ellipsis,
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
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Remove logic
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(0.05)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Color(0xFF5E6E8C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomGradientButton(
                    height: 42,
                    text: 'Edit',
                    onPressed: () {
                      Navigator.pushNamed(context, '/product_images');
                      // Edit logic
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3, // My Post tab active
      selectedItemColor: const Color(0xFF233A66),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (index) {
        if (index == 0) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        if (index == 1) Navigator.pushNamed(context, '/filter_result', arguments: 'Bikes');
        if (index == 2) Navigator.pushNamed(context, '/list_product');
        if (index == 4) Navigator.pushNamed(context, '/profile_overview');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 24), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_bike, size: 24), label: 'Buy'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 24), label: 'Sell'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border, size: 24), label: 'My Post'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 24), label: 'Profile'),
      ],
    );
  }

  void _showBoostBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 140,
                width: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Image.asset('assets/images/Frame 1171275371.png')),
              ),
              const SizedBox(height: 24),
              const Text(
                'Boost Your Ad',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A66),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Increase visibility and get more booking by boosting',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E6E8C)),
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'After boost you can',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  // color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('1. + 1x extra listing', style: TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('2. Free featured ads', style: TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('3. Priority Visibility', style: TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                    SizedBox(height: 3),
                    Text('4. Priority Visibility', style: TextStyle(color: Color(0xFF5E6E8C), height: 1.8)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomGradientButton(
                text: 'Choose Boost Plan',
                onPressed: () {
                  Navigator.pop(context);
                  _showBoostPlansSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBoostPlansSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Boost Your Ad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF233A66)),
              ),
              const SizedBox(height: 16),
              // Product Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        color: const Color(0xFFF9FBFF),
                        child: Center(
                          child: Image.asset('assets/images/bike.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '2021 Royal Enfield Hunter 350',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSmallTag('15,255 KM'),
                        const SizedBox(width: 8),
                        _buildSmallTag('Petrol'),
                        const SizedBox(width: 8),
                        _buildSmallTag('2021'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text('Madhya Pradesh 458468', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                          ],
                        ),
                        const Text(
                          '₹1.85 Lakh',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E4475), fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Plan Options
              _buildPlanOption('Basic Boost', '3 Days Boost', 'Rs.99.00', false),
              _buildPlanOption('Popular Boost', '7 Days Boost', 'Rs.199.00', true),
              _buildPlanOption('Premium Boost', '15 Days Boost', 'Rs.399.00', false),
              const SizedBox(height: 24),
              CustomGradientButton(
                text: 'Choose Boost Plan',
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentSuccessSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F8), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
    );
  }

  Widget _buildPlanOption(String title, String subtitle, String price, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSelected ? const Color(0xFF4A6495) : Colors.black.withOpacity(0.05), width: isSelected ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? const Color(0xFF4A6495) : Colors.grey.shade400),
            ),
            child: isSelected ? const Center(child: Icon(Icons.circle, size: 14, color: Color(0xFF4A6495))) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4475))),
        ],
      ),
    );
  }

  void _showPaymentSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Success Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Color(0xFF4CAF50),
                    child: Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Payment Successful',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Ad is Boosted!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Success! Your listing will stay at the top for the next 7 days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF5E6E8C), fontSize: 14),
              ),
              const SizedBox(height: 40),
              CustomGradientButton(
                text: 'Go to Home',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentFailedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Failed Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                  ),
                  Container(
                    height: 90,
                    width: 90,
                    decoration: const BoxDecoration(color: Color(0xFFFFCDD2), shape: BoxShape.circle),
                  ),
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Color(0xFFF44336),
                    child: Icon(Icons.close, color: Colors.white, size: 40),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Payment Failed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF44336)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Oops!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
              ),
              const SizedBox(height: 12),
              const Text(
                'We couldn\'t process your payment. Pleases try again or change method.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF5E6E8C), fontSize: 14),
              ),
              const SizedBox(height: 40),
              CustomGradientButton(
                text: 'Retry Payment',
                onPressed: () {
                  Navigator.pop(context);
                  _showBoostPlansSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
