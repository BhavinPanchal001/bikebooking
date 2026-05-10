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

  // Get cities in a state
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
      final response = await http.get(
        Uri.parse('$_baseUrl/childrenJSON?geonameId=$stateGeonameId&featureCode=PPL&username=$_username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Place> cities = [];
        
        if (data['geonames'] != null) {
          for (var item in data['geonames']) {
            cities.add(Place.fromJson(item));
          }
        }

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

  // Get areas/localities near a city
  static Future<List<Place>> getAreasInCity(double lat, double lng) async {
    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_areasCacheKeyPrefix${lat}_${lng}';
    final cachedAreas = prefs.getString(cacheKey);
    
    if (cachedAreas != null) {
      final List<dynamic> jsonList = json.decode(cachedAreas);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/searchJSON?lat=$lat&lng=$lng&radius=10&featureCode=PPLX&maxRows=50&username=$_username'),
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
        await prefs.setString(cacheKey, json.encode(areas.map((a) => a.toJson()).toList()));
        
        return areas;
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching areas: $e');
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

  Place({
    required this.geonameId,
    required this.name,
    this.adminCode1,
    this.adminCode2,
    this.lat,
    this.lng,
    this.population,
    this.countryCode,
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
    };
  }
}
