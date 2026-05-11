import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OpenStreetMap Nominatim API Service - Completely FREE
/// Provides: State → City → Locality flow for India
/// API Docs: https://nominatim.org/release-docs/develop/api/Search/
class OpenStreetMapService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'BikeBookingApp/1.0';
  
  // Cache keys
  static const String _statesCacheKey = 'osm_states_cache';
  static const String _citiesCacheKeyPrefix = 'osm_cities_';
  static const String _areasCacheKeyPrefix = 'osm_areas_';

  // Indian States with their OSM relation IDs for accurate boundary search
  static final Map<String, int> _indianStateIds = {
    'Andhra Pradesh': 2022099,
    'Arunachal Pradesh': 2022046,
    'Assam': 2025886,
    'Bihar': 2029036,
    'Chhattisgarh': 1972249,
    'Delhi': 1942586,
    'Goa': 1997192,
    'Gujarat': 1949089,
    'Haryana': 1942039,
    'Himachal Pradesh': 364186,
    'Jharkhand': 1960191,
    'Karnataka': 2010381,
    'Kerala': 2017879,
    'Madhya Pradesh': 1950076,
    'Maharashtra': 1950889,
    'Manipur': 2027048,
    'Meghalaya': 2027650,
    'Mizoram': 2029046,
    'Nagaland': 2027972,
    'Odisha': 1984021,
    'Punjab': 1942686,
    'Rajasthan': 1942923,
    'Sikkim': 2029047,
    'Tamil Nadu': 2068911,
    'Telangana': 3250963,
    'Tripura': 2026457,
    'Uttar Pradesh': 1942587,
    'Uttarakhand': 1473917,
    'West Bengal': 1960173,
  };

  // Major Indian cities by state (static fallback for reliability)
  static final Map<String, List<String>> _indianCities = {
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Rajahmundry', 'Tirupati', 'Kakinada', 'Anantapur', 'Kadapa', 'Eluru', 'Ongole', 'Chittoor', 'Machilipatnam', 'Tenali', 'Proddatur', 'Adoni', 'Hindupur'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Namsai', 'Bomdila', 'Tawang', 'Ziro', 'Aalo'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Nagaon', 'Jorhat', 'Tinsukia', 'Tezpur', 'Bongaigaon', 'Karimganj', 'Sivasagar', 'Goalpara', 'Barpeta'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga', 'Arrah', 'Begusarai', 'Katihar', 'Chapra', 'Purnia', 'Saharsa', 'Hajipur', 'Bettiah', 'Sasaram'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Korba', 'Bilaspur', 'Durg', 'Rajnandgaon', 'Jagdalpur', 'Ambikapur', 'Raigarh', 'Janjgir'],
    'Delhi': ['New Delhi', 'Delhi Cantonment', 'Dwarka', 'Rohini', 'Karol Bagh', 'Lajpat Nagar', 'Rajouri Garden', 'Janakpuri', 'Saket', 'Vasant Kunj', 'Chanakyapuri', 'Mayur Vihar', 'Shahdara', 'Narela', 'Pitampura', 'Preet Vihar', 'Laxmi Nagar'],
    'Goa': ['Panaji', 'Vasco da Gama', 'Margao', 'Mapusa', 'Ponda', 'Bicholim', 'Valpoi', 'Curchorem', 'Sanquelim'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar', 'Junagadh', 'Anand', 'Navsari', 'Morbi', 'Nadiad', 'Surendranagar', 'Bharuch', 'Mehsana', 'Patan', 'Porbandar', 'Godhra'],
    'Haryana': ['Faridabad', 'Gurgaon', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal', 'Sonipat', 'Panchkula', 'Bhiwani', 'Sirsa', 'Jind', 'Kurukshetra'],
    'Himachal Pradesh': ['Shimla', 'Mandi', 'Solan', 'Dharamshala', 'Palampur', 'Baddi', 'Nahan', 'Una', 'Kullu', 'Manali'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh', 'Giridih', 'Medininagar', 'Phusro', 'Ramgarh'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum', 'Gulbarga', 'Davanagere', 'Bellary', 'Bijapur', 'Shimoga', 'Tumkur', 'Raichur', 'Hassan', 'Udupi'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Kollam', 'Thrissur', 'Alappuzha', 'Palakkad', 'Malappuram', 'Kannur', 'Kottayam', 'Pathanamthitta', 'Idukki'],
    'Madhya Pradesh': ['Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas', 'Satna', 'Ratlam', 'Rewa', 'Katni', 'Singrauli', 'Burhanpur', 'Khandwa'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Kalyan', 'Vasai', 'Aurangabad', 'Solapur', 'Amravati', 'Kolhapur', 'Navi Mumbai', 'Sangli', 'Jalgaon', 'Akola', 'Latur', 'Dhule', 'Ahmednagar', 'Chandrapur', 'Parbhani'],
    'Manipur': ['Imphal', 'Thoubal', 'Kakching', 'Lilong', 'Bishnupur', 'Churachandpur'],
    'Meghalaya': ['Shillong', 'Tura', 'Nongstoin', 'Jowai', 'Baghmara', 'Williamnagar'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Saiha', 'Champhai', 'Kolasib', 'Serchhip'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha', 'Zunheboto'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur', 'Puri', 'Balasore', 'Baripada', 'Bhadrak', 'Jharsuguda', 'Jeypore', 'Angul'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Pathankot', 'Hoshiarpur', 'Moga', 'Firozpur', 'Kapurthala', 'Faridkot'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer', 'Bhilwara', 'Alwar', 'Bharatpur', 'Sikar', 'Pali', 'Tonk', 'Kishangarh', 'Beawar', 'Hanumangarh'],
    'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing', 'Rangpo', 'Singtam'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tiruppur', 'Erode', 'Vellore', 'Thoothukudi', 'Dindigul', 'Thanjavur', 'Sivakasi', 'Cuddalore', 'Kanchipuram', 'Rameswaram'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Ramagundam', 'Khammam', 'Mahbubnagar', 'Nalgonda', 'Adilabad', 'Suryapet'],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailashahar', 'Belonia'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi', 'Meerut', 'Allahabad', 'Bareilly', 'Aligarh', 'Gorakhpur', 'Noida', 'Moradabad', 'Saharanpur', 'Jhansi', 'Muzaffarnagar', 'Mathura', 'Firozabad', 'Shahjahanpur'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Haldwani', 'Rudrapur', 'Kashipur', 'Rishikesh', 'Pithoragarh', 'Almora'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri', 'Bardhaman', 'Malda', 'Kharagpur', 'Baharampur', 'Habra', 'Kanchrapara', 'Haldia'],
  };

  // Common localities for major cities
  static final Map<String, List<String>> _commonLocalities = {
    // Gujarat
    'Ahmedabad': ['Navrangpura', 'Satellite', 'Bodakdev', 'Vastrapur', 'Maninagar', 'Bopal', 'Thaltej', 'Chandkheda', 'Gota', 'Sarkhej', 'Naroda', 'Ellis Bridge', 'Paldi', 'Gurukul', 'Memnagar', 'Jodhpur', 'Vejalpur', 'Ghodasar', 'Isanpur', 'Lal Darwaja', 'Odhav', 'Vatva'],
    'Surat': ['Adajan', 'Vesu', 'City Light', 'Varachha', 'Katargam', 'Udhana', 'Rander', 'Olpad', 'Piplod', 'Athwa', 'Ghod Dod Road', 'Parle Point', 'Dumas'],
    'Vadodara': ['Alkapuri', 'Fatehgunj', 'Gotri', 'Manjalpur', 'Nizampura', 'Tarsali', 'Vasna', 'Sayajigunj', 'Waghodia', 'Karelibaug'],
    'Rajkot': ['Kalawad Road', 'Yagnik Road', 'Race Course', 'Sadhu Vasvani Road', 'Madhapar', 'Amin Marg', 'Sadar', 'Bajrang Wadi'],
    
    // Maharashtra
    'Mumbai': ['Andheri', 'Bandra', 'Dadar', 'Borivali', 'Thane', 'Powai', 'Malad', 'Goregaon', 'Kandivali', 'Juhu', 'Chembur', 'Vashi', 'Navi Mumbai', 'Worli', 'Lower Parel', 'Colaba', 'Churchgate', 'Marine Lines', 'Sion', 'Mulund', 'Ghatkopar', 'Kurla', 'Bhandup', 'Mahim'],
    'Pune': ['Koregaon Park', 'Kothrud', 'Viman Nagar', 'Hinjewadi', 'Baner', 'Aundh', 'Kondhwa', 'Magarpatta', 'Hadapsar', 'Shivaji Nagar', 'Deccan', 'Camp', 'Kalyani Nagar', 'Wakad', 'Pimpri', 'Chinchwad'],
    'Nagpur': ['Dharampeth', 'Sitabuldi', 'Manish Nagar', 'Pratap Nagar', 'Ramdaspeth', 'Sadar', 'Gandhibagh', 'Wardha Road'],
    'Nashik': ['Panchavati', 'Gangapur Road', 'College Road', 'Satpur', 'Indira Nagar', 'Cidco'],
    'Aurangabad': ['CIDCO', 'Garkheda', 'Usmanpura', 'Samarth Nagar', 'Jalna Road'],
    'Thane': ['Vasant Vihar', 'Ghodbunder Road', 'Kasarvadavali', 'Hiranandani Estate', 'Naupada'],
    
    // Karnataka
    'Bangalore': ['Koramangala', 'Indiranagar', 'Whitefield', 'JP Nagar', 'HSR Layout', 'BTM Layout', 'Malleshwaram', 'Electronic City', 'Marathahalli', 'Bannerghatta Road', 'Jayanagar', 'Rajajinagar', 'Yelahanka', 'Hebbal', 'Bellandur', 'Sarjapur', 'MG Road', 'Basavanagudi', 'Domlur'],
    'Mysore': ['Vontikoppal', 'Gokulam', 'Jayalakshmipuram', 'Vijayanagar', 'Nazarbad', 'Kuvempunagar'],
    'Mangalore': ['Kankanady', 'Bejai', 'Kadri', 'Attavar', 'Mallikatte', 'Falnir'],
    'Hubli': ['Vidyanagar', 'Keshwapur', 'Gokul Road', 'Navalur', 'Unkal'],
    
    // Delhi NCR
    'New Delhi': ['Connaught Place', 'Karol Bagh', 'Lajpat Nagar', 'Rajouri Garden', 'Dwarka', 'Rohini', 'Janakpuri', 'Saket', 'Vasant Kunj', 'Chanakyapuri', 'Mayur Vihar', 'Shahdara', 'Narela', 'Pitampura', 'Janpath', 'India Gate', 'Hauz Khas', 'Greater Kailash', 'Kalkaji'],
    'Gurgaon': ['Sector 14', 'Sector 29', 'DLF Phase 1', 'DLF Phase 2', 'DLF Phase 3', 'Cyber Hub', 'Golf Course Road', 'MG Road', 'Sohna Road', 'Palam Vihar'],
    // Tamil Nadu
    'Chennai': ['T Nagar', 'Anna Nagar', 'Adyar', 'Velachery', 'Nungambakkam', 'Mylapore', 'Kodambakkam', 'Anna Salai', 'Mount Road', 'Royapettah', 'Egmore', 'Washermenpet', 'Parrys', 'Guindy', 'Tambaram', 'Pallavaram'],
    'Coimbatore': ['RS Puram', 'Gandhipuram', 'Peelamedu', 'Saibaba Colony', 'Singanallur', 'Race Course'],
    'Madurai': ['Anna Nagar', 'K.K. Nagar', 'Mattuthavani', 'Tallakulam', 'Simmakkal'],
    
    // Telangana
    'Hyderabad': ['Banjara Hills', 'Jubilee Hills', 'Madhapur', 'Kukatpally', 'Secunderabad', 'Gachibowli', 'Begumpet', 'Charminar', 'Mehdipatnam', 'Ameerpet', 'Dilsukhnagar', 'Lakdi Ka Pul', 'Hitech City', 'Miyapur', 'LB Nagar', 'Uppal'],
    'Warangal': ['Hanamkonda', 'Kazipet', 'Subedari', 'Naimnagar'],
    
    // West Bengal
    'Kolkata': ['Salt Lake', 'Park Street', 'Howrah', 'New Town', 'Ballygunge', 'Garia', 'Rajarhat', 'Esplanade', 'Dalhousie', 'Alipore', 'Behala', 'Jadavpur', 'Dum Dum', 'Barasat', 'Barrackpore'],
    'Howrah': ['Shibpur', 'Kadamtala', 'Bally', 'Uluberia', 'Domjur'],
    'Siliguri': ['Hakim Para', 'Khalpara', 'City Center', 'Patthargata'],
    
    // Rajasthan
    'Jaipur': ['Malviya Nagar', 'Vaishali Nagar', 'C Scheme', 'Raja Park', 'Mansarovar', 'Jhotwara', 'Tonk Road', 'Jagatpura', 'Bapu Nagar', 'Adarsh Nagar', 'Shastri Nagar', 'M.I. Road', 'Bani Park'],
    'Jodhpur': ['Sardarpura', 'Ratanada', 'Paota', 'Shastri Circle', 'Basni', 'Sangria'],
    'Udaipur': ['Hiran Magri', 'Ashok Nagar', 'Bapu Bazar', 'Fateh Sagar', 'Chetak Circle'],
    'Kota': ['Talwandi', 'Vigyan Nagar', 'Mahaveer Nagar', 'Ranpur'],
    
    // Uttar Pradesh
    'Lucknow': ['Hazratganj', 'Gomti Nagar', 'Indira Nagar', 'Aliganj', 'Aminabad', 'Chowk', 'Alambagh', 'Charbagh', 'Mahanagar', 'Jankipuram', 'Aashiana'],
    'Kanpur': ['Swaroop Nagar', 'Civil Lines', 'Pandu Nagar', 'Kakadeo', 'Lajpat Nagar', 'Rawatpur', 'Kidwai Nagar'],
    'Agra': ['Sadar Bazar', 'Sikandra', 'Kamla Nagar', 'Dayal Bagh', 'Civil Lines'],
    'Varanasi': ['Cantt', 'Lanka', 'Sigra', 'Mahmoorganj', 'Bhelupur'],
    'Ghaziabad': ['Indirapuram', 'Raj Nagar', 'Vaishali', 'Kavi Nagar', 'Sahibabad'],
    'Noida': ['Sector 18', 'Sector 62', 'Sector 15', 'Sector 50', 'Greater Noida', 'Indirapuram'],
    
    // Bihar
    'Patna': ['Boring Road', 'Kankarbagh', 'Patliputra', 'Raja Bazar', 'Bailey Road', 'Ashok Rajpath', 'Gandhi Maidan'],
    'Gaya': ['Civil Lines', 'Magadh Colony', 'Bodh Gaya Road'],
    
    // Madhya Pradesh
    'Indore': ['Vijay Nagar', 'Rajendra Nagar', 'Sapna Sangeeta', 'Geeta Bhawan', 'Malhar Mega Mall', 'Rau', 'Palasia'],
    'Bhopal': ['Arera Colony', 'Shahpura', 'Kolar Road', 'MP Nagar', 'New Market', 'Bairagarh'],
    'Jabalpur': ['Civil Lines', 'Vijay Nagar', 'Ranjhi', 'Gwarighat'],
    
    // Punjab
    'Ludhiana': ['Model Town', 'Civil Lines', 'Ferozepur Road', 'Dugri', 'Sarabha Nagar'],
    'Amritsar': ['Ranjit Avenue', 'Civil Lines', 'Lawrence Road', 'Golden Temple', 'Majitha Road'],
    'Jalandhar': ['Model Town', 'Civil Lines', 'Nakodar Road'],
    
    // Kerala
    'Thiruvananthapuram': ['Kowdiar', 'Palayam', 'Statue', 'Vellayambalam', 'Pattom'],
    'Kochi': ['Ernakulam', 'Fort Kochi', 'Kakkanad', 'Edappally', 'Aluva', 'Tripunithura'],
    'Kozhikode': ['Palayam', 'Beach Road', 'Mavoor Road'],
    
    // Odisha
    'Bhubaneswar': ['Jaydev Vihar', 'Sahid Nagar', 'Patia', 'Khandagiri', 'Old Town'],
    'Cuttack': ['Chowdwar', 'Link Road', 'Badambadi'],
    
    // Assam
    'Guwahati': ['Dispur', 'Paltan Bazar', 'Fancy Bazar', 'Ganeshguri', 'Six Mile', 'Zoo Road'],
    
    // Chhattisgarh
    'Raipur': ['Devendra Nagar', 'Pandri', 'Telibandha', 'Shankar Nagar'],
    
    // Jharkhand
    'Ranchi': ['Lalpur', 'Doranda', 'Hinoo', 'Kokar', 'Argora'],
    'Jamshedpur': ['Bistupur', 'Sakchi', 'Sonari', 'Kadma'],
    
    // Goa
    'Panaji': ['Campal', 'Fontainhas', 'Miramar', 'Caranzalem'],
    'Vasco da Gama': ['Swatantra Path', 'Mormugao', 'Baina'],
    
    // Himachal Pradesh
    'Shimla': ['The Mall', 'Lakkar Bazar', 'Kasumpti', 'New Shimla'],
    'Manali': ['Old Manali', 'Mall Road', 'Aleo'],
    
    // Uttarakhand
    'Dehradun': ['Rajpur Road', 'Chakrata Road', 'Sahastradhara Road', 'Clement Town'],
    'Haridwar': ['BHEL', 'Jwalapur', 'Kankhal'],
    
    // Jammu & Kashmir (not in list but common)
    // North East cities with basic localities
    'Imphal': ['Thangal Bazar', 'Paona Bazar', 'Kwakeithel'],
    'Shillong': ['Police Bazar', 'Laitumkhrah', 'Nongthymmai'],
    'Aizawl': ['Chanmari', 'Zarkawt', 'Ramthar'],
  };

  /// Get all Indian states
  static Future<List<Place>> getIndianStates() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_statesCacheKey);
    
    if (cached != null) {
      final List<dynamic> jsonList = json.decode(cached);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    // Create states from static data
    final states = _indianStateIds.keys.map((name) => 
      Place(
        geonameId: name,
        name: name,
        osmId: _indianStateIds[name],
      )
    ).toList();
    
    // Sort alphabetically
    states.sort((a, b) => a.name.compareTo(b.name));
    
    // Cache
    await prefs.setString(_statesCacheKey, json.encode(states.map((s) => s.toJson()).toList()));
    
    return states;
  }

  /// Get cities in a state using static reliable data
  static Future<List<Place>> getCitiesInState(String stateName) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_citiesCacheKeyPrefix$stateName';
    final cached = prefs.getString(cacheKey);
    
    if (cached != null) {
      final List<dynamic> jsonList = json.decode(cached);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    // Get cities from static data
    final cityNames = _indianCities[stateName] ?? [];
    final cities = cityNames.map((cityName) => Place(
      geonameId: cityName,
      name: cityName,
      adminName1: stateName,
    )).toList();

    // Cache
    await prefs.setString(cacheKey, json.encode(cities.map((c) => c.toJson()).toList()));
    
    return cities;
  }

  /// Get localities in a city
  static Future<List<Place>> getLocalitiesInCity(String cityName, String stateName) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_areasCacheKeyPrefix${cityName}_$stateName';
    final cached = prefs.getString(cacheKey);
    
    if (cached != null) {
      final List<dynamic> jsonList = json.decode(cached);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    List<Place> localities = [];

    // Try OSM Nominatim API first (free)
    try {
      localities = await _fetchLocalitiesFromOSM(cityName, stateName);
    } catch (e) {
      print('DEBUG: OSM fetch failed, using fallback: $e');
    }

    // If OSM fails or returns empty, use static fallback
    if (localities.isEmpty) {
      final localityNames = _commonLocalities[cityName] ?? ['City Center', 'Main Area', 'Downtown', 'Central Market', 'Station Road'];
      localities = localityNames.map((name) => Place(
        geonameId: '$cityName-$name',
        name: name,
        adminName1: stateName,
        adminName2: cityName,
      )).toList();
    }

    // Cache
    await prefs.setString(cacheKey, json.encode(localities.map((l) => l.toJson()).toList()));
    
    return localities;
  }

  /// Fetch localities from OSM Nominatim API
  static Future<List<Place>> _fetchLocalitiesFromOSM(String cityName, String stateName) async {
    final query = Uri.encodeComponent('$cityName, $stateName, India');
    final response = await http.get(
      Uri.parse('$_baseUrl/search?q=$query&format=json&addressdetails=1&limit=20'),
      headers: {'User-Agent': _userAgent},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Place> localities = [];
      
      for (var item in data) {
        final name = item['name'] as String? ?? '';
        final type = item['type'] as String? ?? '';
        final address = item['address'] as Map<String, dynamic>? ?? {};
        
        // Filter for neighborhoods, suburbs, quarters
        final isLocality = type == 'suburb' || 
                          type == 'neighbourhood' || 
                          type == 'quarter' ||
                          type == 'residential' ||
                          address['suburb'] != null ||
                          address['neighbourhood'] != null;
        
        if (name.isNotEmpty && isLocality && !localities.any((l) => l.name == name)) {
          localities.add(Place(
            geonameId: item['place_id']?.toString() ?? name,
            name: name,
            adminName1: stateName,
            adminName2: cityName,
            lat: double.tryParse(item['lat']?.toString() ?? ''),
            lng: double.tryParse(item['lon']?.toString() ?? ''),
          ));
        }
      }

      return localities;
    } else {
      throw Exception('Failed to fetch from OSM: ${response.statusCode}');
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('osm_')) {
        await prefs.remove(key);
      }
    }
  }
}

/// Place model for OpenStreetMap data
class Place {
  final String geonameId;
  final String name;
  final String? adminName1; // State
  final String? adminName2; // City
  final double? lat;
  final double? lng;
  final int? osmId; // OSM relation/node ID

  Place({
    required this.geonameId,
    required this.name,
    this.adminName1,
    this.adminName2,
    this.lat,
    this.lng,
    this.osmId,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      geonameId: json['geonameId']?.toString() ?? '',
      name: json['name'] ?? '',
      adminName1: json['adminName1'],
      adminName2: json['adminName2'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      osmId: json['osmId'],
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
      'osmId': osmId,
    };
  }
}
