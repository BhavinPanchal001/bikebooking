import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/location/data/services/geonames_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectDistrictScreen extends StatefulWidget {
  const SelectDistrictScreen({super.key});

  @override
  State<SelectDistrictScreen> createState() => _SelectDistrictScreenState();
}

class _SelectDistrictScreenState extends State<SelectDistrictScreen> {
  List<Place> districts = [];
  List<Place> filteredDistricts = [];
  bool isLoading = true;
  Place selectedState = Place(geonameId: '', name: '');
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterDistricts);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedState.geonameId.isEmpty) {
      selectedState = ModalRoute.of(context)!.settings.arguments as Place;
      _clearCacheAndLoadDistricts();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _clearCacheAndLoadDistricts() async {
    // Clear ALL cache to force fresh data
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('cached_') || key.startsWith('cached_cities_') || key.startsWith('cached_areas_')) {
        await prefs.remove(key);
      }
    }
    print('DEBUG: All caches cleared');
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    try {
      final loadedDistricts = await GeoNamesService.getDistrictsInState(selectedState.geonameId);
      setState(() {
        districts = loadedDistricts;
        filteredDistricts = loadedDistricts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading districts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterDistricts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredDistricts = districts;
      } else {
        filteredDistricts = districts.where((district) =>
          district.name.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CHOOSE DISTRICT',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Current State Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedState.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search district...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          
          // Districts List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : filteredDistricts.isEmpty
                    ? Center(
                        child: Text(
                          'No districts found',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDistricts.length,
                        itemBuilder: (context, index) {
                          final district = filteredDistricts[index];
                          return _buildDistrictItem(district);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictItem(Place district) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          district.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/select_city',
            arguments: {
              'state': selectedState,
              'district': district,
            },
          );
          if (result != null && context.mounted) {
            Navigator.pop(context, result);
          }
        },
      ),
    );
  }
}
