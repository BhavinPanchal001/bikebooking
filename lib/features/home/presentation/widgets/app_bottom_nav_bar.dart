import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF233A66),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/firstPage.png',
              width: 22,
              height: 18,
              color: currentIndex == 0 ? const Color(0xFF233A66) : Colors.grey.shade400,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/secondPage.png',
              width: 22,
              height: 18,
              color: currentIndex == 1 ? const Color(0xFF233A66) : Colors.grey.shade400,
            ),
            label: 'Buy',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/thirdPage.png',
              width: 22,
              height: 18,
              color: currentIndex == 2 ? const Color(0xFF233A66) : Colors.grey.shade400,
            ),
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/forthPage.png',
              width: 22,
              height: 18,
              color: currentIndex == 3 ? const Color(0xFF233A66) : Colors.grey.shade400,
            ),
            label: 'My Post',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/fifthPage.png',
              width: 22,
              height: 18,
              color: currentIndex == 4 ? const Color(0xFF233A66) : Colors.grey.shade400,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return;
      case 1:
        Navigator.pushNamed(context, '/filter_result', arguments: 'Bikes');
        return;
      case 2:
        Navigator.pushNamed(context, '/list_product');
        return;
      case 3:
        Navigator.pushNamed(context, '/my_listing');
        return;
      case 4:
        Navigator.pushNamed(context, '/profile_overview');
        return;
    }
  }
}
