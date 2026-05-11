import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bikebooking/core/config/geonames_config.dart';

class GeoNamesService {
  static const String _baseUrl = GeoNamesConfig.baseUrl;
  static const String _username = GeoNamesConfig.username;
  static const String _statesCacheKey = GeoNamesConfig.statesCacheKey;
  static const String _citiesCacheKeyPrefix = GeoNamesConfig.citiesCacheKeyPrefix;
  static const String _areasCacheKeyPrefix = GeoNamesConfig.areasCacheKeyPrefix;

  // Get all Indian states
  static Future<List<Place>> getIndianStates() async {
    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedStates = prefs.getString(_statesCacheKey);
    
    if (cachedStates != null) {
      final List<dynamic> jsonList = json.decode(cachedStates);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/childrenJSON?geonameId=1269750&username=$_username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Place> states = [];
        
        if (data['geonames'] != null) {
          for (var item in data['geonames']) {
            states.add(Place.fromJson(item));
          }
        }

        // Cache the results
        await prefs.setString(_statesCacheKey, json.encode(states.map((s) => s.toJson()).toList()));
        
        return states;
      } else {
        throw Exception('Failed to load states: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching states: $e');
    }
  }

  // Get districts in a state (ADM2 - second-level administrative divisions)
  static Future<List<Place>> getDistrictsInState(String stateGeonameId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_districts_$stateGeonameId';
    final cachedDistricts = prefs.getString(cacheKey);
    
    if (cachedDistricts != null) {
      final List<dynamic> jsonList = json.decode(cachedDistricts);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    try {
      // Fetch all children and filter for ADM2 (districts)
      final response = await http.get(
        Uri.parse('$_baseUrl/childrenJSON?geonameId=$stateGeonameId&username=$_username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Place> districts = [];
        
        if (data['geonames'] != null) {
          for (var item in data['geonames']) {
            final featureCode = item['fcode'] ?? '';
            
            // ADM2 = second-order administrative division (district in India)
            // Also include PPLA2 which are district headquarters
            if (featureCode == 'ADM2' || featureCode == 'PPLA2') {
              districts.add(Place.fromJson(item));
            }
          }
        }

        // Sort by name
        districts.sort((a, b) => a.name.compareTo(b.name));

        // Cache the results
        await prefs.setString(cacheKey, json.encode(districts.map((d) => d.toJson()).toList()));
        
        return districts;
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  // Get cities in a district
  static Future<List<Place>> getCitiesInDistrict(String districtGeonameId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_cities_$districtGeonameId';
    final cachedCities = prefs.getString(cacheKey);
    
    if (cachedCities != null) {
      final List<dynamic> jsonList = json.decode(cachedCities);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    try {
      // Fetch all populated places in the district
      final response = await http.get(
        Uri.parse('$_baseUrl/childrenJSON?geonameId=$districtGeonameId&username=$_username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Place> cities = [];
        
        print('DEBUG: getCitiesInDistrict - Total places returned: ${data['geonames']?.length ?? 0}');
        
        if (data['geonames'] != null) {
          for (var item in data['geonames']) {
            final featureCode = item['fcode'] ?? '';
            final population = item['population'] ?? 0;
            final name = item['name'] ?? '';
            
            print('DEBUG: Place: $name, Code: $featureCode, Pop: $population');
            
            // Include ALL populated places regardless of population
            // GeoNames for India may not have accurate population data
            if (featureCode.startsWith('PPL')) {
              cities.add(Place.fromJson(item));
            }
          }
        }

        print('DEBUG: Filtered cities count: ${cities.length}');

        // Sort by population (descending) - major cities first
        cities.sort((a, b) => (b.population ?? 0).compareTo(a.population ?? 0));

        // Cache the results
        await prefs.setString(cacheKey, json.encode(cities.map((c) => c.toJson()).toList()));
        
        return cities;
      } else {
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cities: $e');
    }
  }

  // DEPRECATED: Old method - kept for compatibility
  static Future<List<Place>> getCitiesInState(String stateGeonameId) async {
    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_citiesCacheKeyPrefix$stateGeonameId';
    final cachedCities = prefs.getString(cacheKey);
    
    if (cachedCities != null) {
      final List<dynamic> jsonList = json.decode(cachedCities);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    try {
      // Fetch all populated places including cities, towns, villages
      final response = await http.get(
        Uri.parse('$_baseUrl/childrenJSON?geonameId=$stateGeonameId&featureClass=P&username=$_username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Place> cities = [];
        
        if (data['geonames'] != null) {
          for (var item in data['geonames']) {
            final featureCode = item['fcode'] ?? '';
            final population = item['population'] ?? 0;
            
            // Include all populated places that could be cities
            // PPLA/PPLA2/PPLA3 = administrative centers (cities)
            // PPL = populated places (cities, towns)
            // PPLA4/PPLG = other city types
            final isPopulatedPlace = featureCode.startsWith('PPL') || 
                                    featureCode == 'ADM2' ||
                                    featureCode == 'ADM3';
            
            // Skip villages and very small places (population < 1000)
            final isSignificant = population == 0 || population > 1000;
            
            if (isPopulatedPlace && isSignificant) {
              cities.add(Place.fromJson(item));
            }
          }
        }

        // If filtered list is empty, include all places as fallback
        if (cities.isEmpty && data['geonames'] != null) {
          for (var item in data['geonames']) {
            cities.add(Place.fromJson(item));
          }
        }

        // Sort by population (descending) to show major cities first
        cities.sort((a, b) => (b.population ?? 0).compareTo(a.population ?? 0));

        // Cache the results
        await prefs.setString(cacheKey, json.encode(cities.map((c) => c.toJson()).toList()));
        
        return cities;
      } else {
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cities: $e');
    }
  }

  // Get areas/localities in a city using childrenJSON for accurate results
  static Future<List<Place>> getAreasInCity(String cityGeonameId) async {
    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_areasCacheKeyPrefix${cityGeonameId}';
    final cachedAreas = prefs.getString(cacheKey);
    
    if (cachedAreas != null) {
      final List<dynamic> jsonList = json.decode(cachedAreas);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    try {
      // Try to get city children (subdivisions/localities)
      final response = await http.get(
        Uri.parse('$_baseUrl/childrenJSON?geonameId=$cityGeonameId&username=$_username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Place> areas = [];
        
        print('DEBUG: getAreasInCity - Total places returned: ${data['geonames']?.length ?? 0}');
        
        if (data['geonames'] != null) {
          for (var item in data['geonames']) {
            final featureCode = item['fcode'] ?? '';
            final name = item['name'] ?? '';
            
            print('DEBUG: Area Place: $name, Code: $featureCode');
            
            // Include ALL places as potential localities
            if (featureCode.startsWith('PPL') || featureCode.startsWith('ADM')) {
              areas.add(Place.fromJson(item));
            }
          }
        }

        print('DEBUG: Filtered areas count: ${areas.length}');

        // If no children found, try nearby search as fallback
        if (areas.isEmpty) {
          return await _getNearbyAreasFallback(cityGeonameId, cacheKey);
        }

        // Cache the results
        await prefs.setString(cacheKey, json.encode(areas.map((a) => a.toJson()).toList()));
        
        return areas;
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching areas: $e');
    }
  }

  // Fallback: Get nearby areas using search if childrenJSON returns empty
  static Future<List<Place>> _getNearbyAreasFallback(String cityGeonameId, String cacheKey) async {
    try {
      // Get city details first to get lat/lng
      final cityResponse = await http.get(
        Uri.parse('$_baseUrl/getJSON?geonameId=$cityGeonameId&username=$_username'),
      );
      
      if (cityResponse.statusCode == 200) {
        final cityData = json.decode(cityResponse.body);
        final lat = double.tryParse(cityData['lat']?.toString() ?? '');
        final lng = double.tryParse(cityData['lng']?.toString() ?? '');
        
        if (lat != null && lng != null) {
          final response = await http.get(
            Uri.parse('$_baseUrl/searchJSON?lat=$lat&lng=$lng&radius=5&featureCode=PPLX&maxRows=30&username=$_username'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final List<Place> areas = [];
            
            if (data['geonames'] != null) {
              for (var item in data['geonames']) {
                areas.add(Place.fromJson(item));
              }
            }

            // Cache the results
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(cacheKey, json.encode(areas.map((a) => a.toJson()).toList()));
            
            return areas;
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Clear all cached data
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statesCacheKey);
    
    // Clear all city caches
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith(_citiesCacheKeyPrefix) || key.startsWith(_areasCacheKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}

class Place {
  final String geonameId;
  final String name;
  final String? adminCode1;
  final String? adminCode2;
  final double? lat;
  final double? lng;
  final int? population;
  final String? countryCode;
  final String? featureCode;

  Place({
    required this.geonameId,
    required this.name,
    this.adminCode1,
    this.adminCode2,
    this.lat,
    this.lng,
    this.population,
    this.countryCode,
    this.featureCode,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      geonameId: json['geonameId']?.toString() ?? '',
      name: json['name'] ?? '',
      adminCode1: json['adminCode1'],
      adminCode2: json['adminCode2'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      population: json['population'] != null ? int.tryParse(json['population'].toString()) : null,
      countryCode: json['countryCode'],
      featureCode: json['fcode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'geonameId': geonameId,
      'name': name,
      'adminCode1': adminCode1,
      'adminCode2': adminCode2,
      'lat': lat,
      'lng': lng,
      'population': population,
      'countryCode': countryCode,
      'fcode': featureCode,
    };
  }
}
