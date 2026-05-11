import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Google Places API Service for Indian location selection
/// Provides: State → City → Locality flow
class GooglePlacesService {
  // Get your API key from: https://developers.google.com/maps/documentation/places/web-service/get-api-key
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY'; // Replace with your key
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  // For development/testing without API key, use static data
  static bool get _useStaticData => _apiKey == 'YOUR_GOOGLE_PLACES_API_KEY';

  // Indian states with major cities
  static final Map<String, List<String>> _indianStatesAndCities = {
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Rajahmundry', 'Tirupati', 'Kakinada'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Namsai'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Nagaon', 'Jorhat', 'Tinsukia'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga', 'Arrah', 'Begusarai'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Korba', 'Bilaspur', 'Durg', 'Rajnandgaon'],
    'Delhi': ['New Delhi', 'Delhi Cantonment', 'Noida', 'Gurgaon', 'Faridabad'],
    'Goa': ['Panaji', 'Vasco da Gama', 'Margao', 'Mapusa', 'Ponda'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar', 'Junagadh', 'Anand', 'Navsari'],
    'Haryana': ['Faridabad', 'Gurgaon', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal'],
    'Himachal Pradesh': ['Shimla', 'Mandi', 'Solan', 'Dharamshala', 'Palampur'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum', 'Gulbarga', 'Davanagere', 'Bellary'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Kollam', 'Thrissur', 'Alappuzha'],
    'Madhya Pradesh': ['Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Kalyan', 'Vasai', 'Aurangabad', 'Solapur', 'Amravati', 'Kolhapur'],
    'Manipur': ['Imphal'],
    'Meghalaya': ['Shillong', 'Tura'],
    'Mizoram': ['Aizawl'],
    'Nagaland': ['Kohima', 'Dimapur'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer', 'Bhilwara', 'Alwar'],
    'Sikkim': ['Gangtok'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tiruppur', 'Erode', 'Vellore'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Ramagundam'],
    'Tripura': ['Agartala'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi', 'Meerut', 'Allahabad', 'Bareilly', 'Aligarh', 'Gorakhpur'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Haldwani'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri', 'Bardhaman', 'Malda'],
  };

  // Get all Indian states
  static Future<List<Place>> getIndianStates() async {
    final states = _indianStatesAndCities.keys.map((name) => 
      Place(geonameId: name, name: name)
    ).toList();
    
    // Sort alphabetically
    states.sort((a, b) => a.name.compareTo(b.name));
    return states;
  }

  // Get cities in a state
  static Future<List<Place>> getCitiesInState(String stateName) async {
    final cities = _indianStatesAndCities[stateName] ?? [];
    
    return cities.map((cityName) => 
      Place(geonameId: cityName, name: cityName, adminName1: stateName)
    ).toList();
  }

  // Get localities/areas in a city using Places API
  static Future<List<Place>> getLocalitiesInCity(String cityName, String stateName) async {
    if (_useStaticData) {
      // Return some default localities for testing
      return _getDefaultLocalities(cityName);
    }

    try {
      // Use Places Text Search to find localities in the city
      final query = Uri.encodeComponent('localities in $cityName, $stateName, India');
      final response = await http.get(
        Uri.parse('$_baseUrl/textsearch/json?query=$query&key=$_apiKey&types=neighborhood|sublocality'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Place> localities = [];
        
        if (data['results'] != null) {
          for (var item in data['results']) {
            final name = item['name'] ?? '';
            final placeId = item['place_id'] ?? '';
            
            if (name.isNotEmpty) {
              localities.add(Place(
                geonameId: placeId,
                name: name,
                adminName1: stateName,
                adminName2: cityName,
              ));
            }
          }
        }
        
        // If no localities found from API, use defaults
        if (localities.isEmpty) {
          return _getDefaultLocalities(cityName);
        }
        
        return localities;
      } else {
        // Fallback to default localities
        return _getDefaultLocalities(cityName);
      }
    } catch (e) {
      print('DEBUG: Error fetching localities: $e');
      return _getDefaultLocalities(cityName);
    }
  }

  // Default localities for common Indian cities
  static List<Place> _getDefaultLocalities(String cityName) {
    final Map<String, List<String>> defaultLocalities = {
      'Ahmedabad': ['Navrangpura', 'Satellite', 'Bodakdev', 'Vastrapur', 'Maninagar', 'Bopal', 'Thaltej', 'Chandkheda'],
      'Surat': ['Adajan', 'Vesu', 'City Light', 'Varachha', 'Katargam', 'Udhana'],
      'Vadodara': ['Alkapuri', 'Fatehgunj', 'Gotri', 'Manjalpur', 'Nizampura'],
      'Rajkot': ['Kalawad Road', 'Yagnik Road', 'Race Course', 'Sadhu Vasvani Road'],
      'Mumbai': ['Andheri', 'Bandra', 'Dadar', 'Borivali', 'Thane', 'Powai', 'Malad', 'Goregaon', 'Kandivali'],
      'Pune': ['Koregaon Park', 'Kothrud', 'Viman Nagar', 'Hinjewadi', 'Baner', 'Aundh', 'Kondhwa'],
      'Bangalore': ['Koramangala', 'Indiranagar', 'Whitefield', 'JP Nagar', 'HSR Layout', 'BTM Layout', 'Malleshwaram'],
      'Delhi': ['Connaught Place', 'Karol Bagh', 'Lajpat Nagar', 'Rajouri Garden', 'Dwarka', 'Rohini', 'Janakpuri'],
      'Chennai': ['T Nagar', 'Anna Nagar', 'Adyar', 'Velachery', 'Nungambakkam', 'Mylapore'],
      'Hyderabad': ['Banjara Hills', 'Jubilee Hills', 'Madhapur', 'Kukatpally', 'Secunderabad', 'Gachibowli'],
      'Kolkata': ['Salt Lake', 'Park Street', 'Howrah', 'New Town', 'Ballygunge', 'Garia'],
      'Jaipur': ['Malviya Nagar', 'Vaishali Nagar', 'C Scheme', 'Raja Park', 'Mansarovar'],
    };
    
    final localities = defaultLocalities[cityName] ?? ['City Center', 'Main Area', 'Downtown'];
    
    return localities.map((name) => Place(
      geonameId: '$cityName-$name',
      name: name,
      adminName2: cityName,
    )).toList();
  }

  // Clear cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('google_places_')) {
        await prefs.remove(key);
      }
    }
  }
}

/// Place model for Google Places data
class Place {
  final String geonameId;
  final String name;
  final String? adminName1; // State
  final String? adminName2; // City
  final double? lat;
  final double? lng;

  Place({
    required this.geonameId,
    required this.name,
    this.adminName1,
    this.adminName2,
    this.lat,
    this.lng,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      geonameId: json['geonameId']?.toString() ?? '',
      name: json['name'] ?? '',
      adminName1: json['adminName1'],
      adminName2: json['adminName2'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'geonameId': geonameId,
      'name': name,
      'adminName1': adminName1,
      'adminName2': adminName2,
      'lat': lat,
      'lng': lng,
    };
  }
}
