import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = [
    'Brand',
    'Price',
    'Km Driven',
    'Year',
    'Fuel Type',
    'Owners',
  ];

  double _priceValue = 80000;
  double _kmValue = 5000;
  String? _selectedBrand;
  String? _selectedSort;
  String? _selectedFuel;
  String? _selectedOwner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2E3E5C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Side Tabs
                  Container(
                    width: 120,
                    color: const Color(0xFFF0F4F7),
                    child: ListView.builder(
                      itemCount: _tabs.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedTabIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = index;
                            });
                          },
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              border: isSelected
                                  ? const Border(
                                      left: BorderSide(color: Color(0xFF2E3E5C), width: 4),
                                    )
                                  : null,
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _tabs[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF2E3E5C) : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: _buildTabContent(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Apply Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '65',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
                      ),
                      Text(
                        'Product Found',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/filter_result'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6CAD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildBrandContent();
      case 1:
        return _buildPriceContent();
      case 2:
        return _buildKmContent();
      case 3:
        return _buildYearContent();
      case 4:
        return _buildFuelContent();
      case 5:
        return _buildOwnersContent();
      default:
        return Center(child: Text('Content for ${_tabs[_selectedTabIndex]}'));
    }
  }

  Widget _buildOwnersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a owners', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 16),
        _buildOwnerItem('1st owner'),
        _buildOwnerItem('2nd owner'),
        _buildOwnerItem('3rd owner'),
        _buildOwnerItem('4th owner'),
      ],
    );
  }

  Widget _buildOwnerItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _selectedOwner == text,
            onChanged: (v) => setState(() => _selectedOwner = text),
            activeColor: const Color(0xFF2E3E5C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2E3E5C))),
        ],
      ),
    );
  }

  Widget _buildBrandContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Brand',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('All Brand', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              _buildBrandItem('Aprilia', 'assets/brands/aprilia.png'),
              _buildBrandItem('TVS', 'assets/brands/tvs.png'),
              _buildBrandItem('Bajaj', 'assets/brands/bajaj.png'),
              _buildBrandItem('Beneli', 'assets/brands/beneli.png'),
              _buildBrandItem('BSA', 'assets/brands/bsa.png'),
              _buildBrandItem('Ducati', 'assets/brands/ducati.png'),
              _buildBrandItem('Eider', 'assets/brands/eider.png'),
              _buildBrandItem('Harley-Davidson', 'assets/brands/harley.png'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandItem(String text, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _selectedBrand == text,
            onChanged: (v) => setState(() => _selectedBrand = text),
            activeColor: const Color(0xFF2E3E5C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Image.asset(imagePath, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.stars, size: 20, color: Colors.grey)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a price range below', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 30),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF2E3E5C), borderRadius: BorderRadius.circular(6)),
            child: Text('₹${_priceValue.toInt().toString()}', style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
        Slider(
          value: _priceValue,
          min: 5000,
          max: 200000,
          activeColor: const Color(0xFF2E3E5C),
          inactiveColor: Colors.grey.shade300,
          onChanged: (v) => setState(() => _priceValue = v),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Min ₹5,000', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('Max ₹2,00,000', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 30),
        const Text('Quick Select', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionChip('₹0k - ₹25k'),
            _buildOptionChip('₹25k - ₹50k'),
            _buildOptionChip('₹50k - ₹1L'),
            _buildOptionChip('₹1L - ₹1.5L', isSelected: true),
            _buildOptionChip('₹1L - ₹1.5L'),
            _buildOptionChip('₹1.5L - ₹2L'),
            _buildOptionChip('₹ 2L+'),
          ],
        ),
        const SizedBox(height: 30),
        const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        _buildSortItem('Low to High'),
        _buildSortItem('High to Low'),
      ],
    );
  }

  Widget _buildSortItem(String text) {
    return Row(
      children: [
        Radio<String>(
          value: text,
          groupValue: _selectedSort,
          onChanged: (v) => setState(() => _selectedSort = v),
          activeColor: const Color(0xFF2E3E5C),
        ),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildKmContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a range below (km)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 30),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF2E3E5C), borderRadius: BorderRadius.circular(6)),
            child: Text('${_kmValue.toInt().toString()}km', style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
        Slider(
          value: _kmValue,
          min: 0,
          max: 100000,
          activeColor: const Color(0xFF2E3E5C),
          inactiveColor: Colors.grey.shade300,
          onChanged: (v) => setState(() => _kmValue = v),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Min 0km', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('Max 1,00,000km', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 30),
        const Text('Popular ranges', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionChip('Under 25k km'),
            _buildOptionChip('Under 50k km'),
            _buildOptionChip('Under 75k km'),
            _buildOptionChip('Under 1L km'),
          ],
        ),
      ],
    );
  }

  Widget _buildYearContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a year below', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildYearInput('2003'),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('To')),
            _buildYearInput('2025'),
          ],
        ),
        const SizedBox(height: 30),
        const Text('Popular bike age', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionChip('2 year or less'),
            _buildOptionChip('4 year or less'),
            _buildOptionChip('6 year or less'),
            _buildOptionChip('8 year or less'),
          ],
        ),
      ],
    );
  }

  Widget _buildYearInput(String hint) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(hint, style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildFuelContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose a year below', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))), // Fixed title based on image
        const SizedBox(height: 16),
        _buildFuelItem('Petrol', Icons.local_gas_station, Colors.green),
        _buildFuelItem('Electric', Icons.bolt, Colors.amber),
        _buildFuelItem('Hybrid', Icons.eco, Colors.green),
        _buildFuelItem('CNG', Icons.directions_bus, Colors.blue),
      ],
    );
  }

  Widget _buildFuelItem(String text, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
          const Spacer(),
          Radio<String>(
            value: text,
            groupValue: _selectedFuel,
            onChanged: (v) => setState(() => _selectedFuel = v),
            activeColor: const Color(0xFF2E3E5C),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(String text, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4A6CAD) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF2E3E5C),
        ),
      ),
    );
  }
}
