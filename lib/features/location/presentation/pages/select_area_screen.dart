import 'dart:convert';
import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/location/data/models/state_model.dart';
import 'package:bikebooking/features/location/data/models/city_model.dart';
import 'package:bikebooking/features/location/data/models/area_model.dart';
import 'package:bikebooking/features/location/data/services/openstreetmap_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class SelectAreaScreen extends StatefulWidget {
  const SelectAreaScreen({super.key});

  @override
  State<SelectAreaScreen> createState() => _SelectAreaScreenState();
}

class _SelectAreaScreenState extends State<SelectAreaScreen> {
  List<AreaModel> areas = [];
  List<AreaModel> filteredAreas = [];
  bool isLoading = true;
  StateModel? selectedState;
  CityModel? selectedCity;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterAreas);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedCity == null) {
      final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      selectedState = arguments['state'] as StateModel;
      selectedCity = arguments['city'] as CityModel;
      _loadAreas();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      print('DEBUG _loadAreas: selectedCity=${selectedCity?.id} "${selectedCity?.name}", selectedState="${selectedState?.name}"');
      if (selectedCity != null && selectedCity!.name.isNotEmpty) {
        final loadedAreas = await OpenStreetMapService.getAreasFromDb(
          selectedCity!.id,
          selectedCity!.name,
          selectedState!.name,
        );
        print('DEBUG _loadAreas: loadedAreas count=${loadedAreas.length}');
        if (loadedAreas.isNotEmpty) {
          print('DEBUG _loadAreas: first area="${loadedAreas.first.name}", last area="${loadedAreas.last.name}"');
        }
        setState(() {
          areas = loadedAreas;
          filteredAreas = loadedAreas;
          isLoading = false;
        });
      } else {
        print('DEBUG _loadAreas: selectedCity is null or name is empty');
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('City information not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('DEBUG _loadAreas: EXCEPTION: $e');
      print('DEBUG _loadAreas: STACK: $stackTrace');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading areas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterAreas() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredAreas = areas;
      } else {
        filteredAreas = areas.where((area) =>
          area.name.toLowerCase().contains(query)
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
          'CHOOSE LOCALITY',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Current Location Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedState?.name ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      selectedCity?.name ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
                  hintText: 'Search city, area or neighbourhood',
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
          
          // "All in City" Option
          if (!isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'All in ${selectedCity?.name ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
                onTap: () => _selectArea(null),
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Areas List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : filteredAreas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No specific areas found',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try selecting "All in ${selectedCity?.name ?? ''}"',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAreas.length,
                        itemBuilder: (context, index) {
                          final area = filteredAreas[index];
                          return _buildAreaItem(area);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaItem(AreaModel area) {
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
          area.name,
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
        onTap: () => _selectArea(area),
      ),
    );
  }

  Future<void> _selectArea(AreaModel? area) async {
    double? latitude = area?.latitude;
    double? longitude = area?.longitude;

    // If area selected but missing coordinates, geocode on-the-fly
    if (area != null && (latitude == null || longitude == null || latitude == 0 || longitude == 0)) {
      setState(() {
        isLoading = true;
      });
      
      final coords = await _geocodeArea(area.name, selectedCity?.name ?? '', selectedState?.name ?? '');
      
      setState(() {
        isLoading = false;
      });
      
      if (coords != null) {
        latitude = coords['lat'];
        longitude = coords['lng'];
      }
    }

    // Return the selected location data
    final selectedLocation = {
      'state': selectedState,
      'city': selectedCity,
      'area': area,
      'displayAddress': area != null 
          ? '${area.name}, ${selectedCity?.name ?? ''}, ${selectedState?.name ?? ''}'
          : '${selectedCity?.name ?? ''}, ${selectedState?.name ?? ''}',
      'latitude': latitude,
      'longitude': longitude,
    };
    
    if (mounted) {
      Navigator.pop(context, selectedLocation);
    }
  }

  /// Geocode an area using OpenStreetMap Nominatim API
  Future<Map<String, double>?> _geocodeArea(String areaName, String cityName, String stateName) async {
    try {
      final query = Uri.encodeComponent('$areaName, $cityName, $stateName, India');
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'BikeBookingApp/1.0'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat'].toString());
          final lon = double.tryParse(results[0]['lon'].toString());
          if (lat != null && lon != null) {
            return {'lat': lat, 'lng': lon};
          }
        }
      }
    } catch (e) {
      print('Geocoding error for $areaName: $e');
    }
    return null;
  }
}
