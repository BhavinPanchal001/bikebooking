import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bikebooking/core/database/database_helper.dart';
import 'package:bikebooking/features/location/data/models/state_model.dart';
import 'package:bikebooking/features/location/data/models/city_model.dart';
import 'package:bikebooking/features/location/data/models/area_model.dart';

/// OpenStreetMap Nominatim + Overpass API Service - Completely FREE
/// Provides: State → City → Locality flow for India
/// API Docs: https://nominatim.org/release-docs/develop/api/Search/
/// Overpass: https://overpass-api.de/
class OpenStreetMapService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _postalApiUrl = 'https://api.postalpincode.in/postoffice';
  static const String _userAgent = 'BikeBookingApp/1.0';

  // Cache version — bump to invalidate old caches
  static const int _cacheVersion = 12;
  
  // Cache keys
  static const String _statesCacheKey = 'osm_states_cache_v$_cacheVersion';
  static const String _citiesCacheKeyPrefix = 'osm_cities_v${_cacheVersion}_';
  static const String _areasCacheKeyPrefix = 'osm_areas_v${_cacheVersion}_';

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
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Rajahmundry', 'Tirupati', 'Kakinada', 'Anantapur', 'Kadapa', 'Eluru', 'Ongole', 'Chittoor', 'Machilipatnam', 'Tenali', 'Proddatur', 'Adoni', 'Hindupur', 'Srikakulam', 'Vizianagaram', 'Bhimavaram', 'Tadepalligudem', 'Gudivada', 'Narasaraopet', 'Tadipatri', 'Amaravati'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Namsai', 'Bomdila', 'Tawang', 'Ziro', 'Aalo', 'Tezu', 'Roing', 'Changlang', 'Khonsa'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Nagaon', 'Jorhat', 'Tinsukia', 'Tezpur', 'Bongaigaon', 'Karimganj', 'Sivasagar', 'Goalpara', 'Barpeta', 'Dhubri', 'Lakhimpur', 'Kamrup', 'Haflong', 'Diphu', 'Nalbari', 'Hojai', 'Golaghat'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga', 'Arrah', 'Begusarai', 'Katihar', 'Chapra', 'Purnia', 'Saharsa', 'Hajipur', 'Bettiah', 'Sasaram', 'Motihari', 'Munger', 'Supaul', 'Madhubani', 'Sitamarhi', 'Siwan', 'Jehanabad', 'Nalanda', 'Nawada', 'Aurangabad', 'Kishanganj'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Korba', 'Bilaspur', 'Durg', 'Rajnandgaon', 'Jagdalpur', 'Ambikapur', 'Raigarh', 'Janjgir', 'Mahasamund', 'Dhamtari', 'Kanker', 'Kondagaon', 'Kawardha', 'Bemetara', 'Mungeli'],
    'Delhi': ['New Delhi', 'Delhi Cantonment', 'Dwarka', 'Rohini', 'Karol Bagh', 'Lajpat Nagar', 'Rajouri Garden', 'Janakpuri', 'Saket', 'Vasant Kunj', 'Chanakyapuri', 'Mayur Vihar', 'Shahdara', 'Narela', 'Pitampura', 'Preet Vihar', 'Laxmi Nagar', 'Uttam Nagar', 'Vikaspuri', 'Paschim Vihar', 'Seelampur', 'Dilshad Garden', 'Yamuna Vihar', 'Burari', 'Bawana', 'Mundka'],
    'Goa': ['Panaji', 'Vasco da Gama', 'Margao', 'Mapusa', 'Ponda', 'Bicholim', 'Valpoi', 'Curchorem', 'Sanquelim', 'Calangute', 'Candolim', 'Morjim', 'Pernem', 'Quepem', 'Sanguem', 'Cuncolim'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar', 'Junagadh', 'Anand', 'Navsari', 'Morbi', 'Nadiad', 'Surendranagar', 'Bharuch', 'Mehsana', 'Patan', 'Porbandar', 'Godhra', 'Amreli', 'Valsad', 'Botad', 'Dahod', 'Palanpur', 'Kheda', 'Veraval', 'Dwarka', 'Gandhidham', 'Kutch', 'Kalol', 'Ankleshwar', 'Gondal', 'Jetpur', 'Wankaner', 'Vapi', 'Billimora'],
    'Haryana': ['Faridabad', 'Gurgaon', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal', 'Sonipat', 'Panchkula', 'Bhiwani', 'Sirsa', 'Jind', 'Kurukshetra', 'Rewari', 'Palwal', 'Fatehabad', 'Jhajjar', 'Kaithal', 'Nuh', 'Mahendragarh', 'Bahadurgarh', 'Narnaul', 'Hansi', 'Thanesar'],
    'Himachal Pradesh': ['Shimla', 'Mandi', 'Solan', 'Dharamshala', 'Palampur', 'Baddi', 'Nahan', 'Una', 'Kullu', 'Manali', 'Bilaspur', 'Hamirpur', 'Chamba', 'Kangra', 'Keylong', 'Rampur', 'Sundernagar', 'Sarkaghat'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh', 'Giridih', 'Medininagar', 'Phusro', 'Ramgarh', 'Dumka', 'Chaibasa', 'Lohardaga', 'Pakur', 'Simdega', 'Khunti', 'Sahibganj', 'Godda', 'Gumla'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum', 'Gulbarga', 'Davanagere', 'Bellary', 'Bijapur', 'Shimoga', 'Tumkur', 'Raichur', 'Hassan', 'Udupi', 'Bidar', 'Chitradurga', 'Kolar', 'Mandya', 'Chamarajanagar', 'Dharwad', 'Gadag', 'Haveri', 'Koppal', 'Chikmagalur', 'Bagalkot', 'Yadgir', 'Ramnagara', 'Kodagu', 'Chikkaballapur', 'Vijayapura', 'Hosapete'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Kollam', 'Thrissur', 'Alappuzha', 'Palakkad', 'Malappuram', 'Kannur', 'Kottayam', 'Pathanamthitta', 'Idukki', 'Wayanad', 'Kasaragod', 'Ernakulam', 'Ponnani', 'Chalakudy', 'Irinjalakuda', 'Kayamkulam', 'Varkala', 'Attingal', 'Nedumangad', 'Thalassery', 'Vatakara', 'Kalpetta'],
    'Madhya Pradesh': ['Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas', 'Satna', 'Ratlam', 'Rewa', 'Katni', 'Singrauli', 'Burhanpur', 'Khandwa', 'Chhindwara', 'Damoh', 'Mandsaur', 'Neemuch', 'Hoshangabad', 'Itarsi', 'Vidisha', 'Betul', 'Shajapur', 'Seoni', 'Balaghat', 'Chhatarpur', 'Tikamgarh', 'Shivpuri', 'Guna', 'Morena', 'Bhind', 'Datia'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Kalyan', 'Vasai', 'Aurangabad', 'Solapur', 'Amravati', 'Kolhapur', 'Navi Mumbai', 'Sangli', 'Jalgaon', 'Akola', 'Latur', 'Dhule', 'Ahmednagar', 'Chandrapur', 'Parbhani', 'Nanded', 'Ichalkaranji', 'Panvel', 'Bhiwandi', 'Malegaon', 'Jalna', 'Osmanabad', 'Ratnagiri', 'Satara', 'Beed', 'Yavatmal', 'Wardha', 'Buldhana', 'Hingoli', 'Washim', 'Gondia', 'Bhandara', 'Gadchiroli', 'Sindhudurg', 'Raigad', 'Alibag'],
    'Manipur': ['Imphal', 'Thoubal', 'Kakching', 'Lilong', 'Bishnupur', 'Churachandpur', 'Ukhrul', 'Senapati', 'Tamenglong', 'Chandel', 'Jiribam'],
    'Meghalaya': ['Shillong', 'Tura', 'Nongstoin', 'Jowai', 'Baghmara', 'Williamnagar', 'Resubelpara', 'Mairang', 'Nongpoh', 'Cherrapunjee'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Saiha', 'Champhai', 'Kolasib', 'Serchhip', 'Mamit', 'Lawngtlai', 'Hnahthial'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha', 'Zunheboto', 'Mon', 'Phek', 'Longleng', 'Kiphire', 'Noklak'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur', 'Puri', 'Balasore', 'Baripada', 'Bhadrak', 'Jharsuguda', 'Jeypore', 'Angul', 'Dhenkanal', 'Kendrapara', 'Paradip', 'Koraput', 'Sundargarh', 'Keonjhar', 'Rayagada', 'Bargarh', 'Nabarangpur', 'Malkangiri', 'Bhawanipatna', 'Bolangir', 'Phulbani', 'Kendujhar'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Pathankot', 'Hoshiarpur', 'Moga', 'Firozpur', 'Kapurthala', 'Faridkot', 'Gurdaspur', 'Rupnagar', 'Nawanshahr', 'Barnala', 'Muktsar', 'Sangrur', 'Fatehgarh Sahib', 'Tarn Taran', 'Mansa', 'Fazilka', 'Abohar', 'Phagwara', 'Khanna', 'Rajpura', 'Zirakpur'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer', 'Bhilwara', 'Alwar', 'Bharatpur', 'Sikar', 'Pali', 'Tonk', 'Kishangarh', 'Beawar', 'Hanumangarh', 'Sri Ganganagar', 'Churu', 'Jhunjhunu', 'Nagaur', 'Barmer', 'Jaisalmer', 'Sawai Madhopur', 'Dausa', 'Dholpur', 'Karauli', 'Bundi', 'Jhalawar', 'Baran', 'Dungarpur', 'Banswara', 'Rajsamand', 'Pratapgarh', 'Chittorgarh'],
    'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing', 'Rangpo', 'Singtam', 'Jorethang', 'Mangan', 'Ravangla', 'Yuksom'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tiruppur', 'Erode', 'Vellore', 'Thoothukudi', 'Dindigul', 'Thanjavur', 'Sivakasi', 'Cuddalore', 'Kanchipuram', 'Rameswaram', 'Tirunelveli', 'Nagercoil', 'Karur', 'Namakkal', 'Ariyalur', 'Perambalur', 'Villupuram', 'Krishnagiri', 'Dharmapuri', 'Nilgiris', 'Tiruvannamalai', 'Pudukkottai', 'Ramanathapuram', 'Sivaganga', 'Virudhunagar', 'Theni', 'Kallakurichi', 'Ranipet', 'Chengalpattu', 'Tenkasi', 'Mayiladuthurai', 'Tirupattur'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Ramagundam', 'Khammam', 'Mahbubnagar', 'Nalgonda', 'Adilabad', 'Suryapet', 'Siddipet', 'Vikarabad', 'Wanaparthy', 'Gadwal', 'Nagarkurnool', 'Narayanpet', 'Jagtial', 'Mancherial', 'Nirmal', 'Kumuram Bheem', 'Peddapalli', 'Jayashankar', 'Mulugu', 'Bhadradri Kothagudem', 'Yadadri Bhongir', 'Medchal', 'Sangareddy', 'Medak', 'Kamareddy', 'Rajanna Sircilla', 'Jangaon'],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailashahar', 'Belonia', 'Sabroom', 'Ambassa', 'Khowai', 'Sonamura', 'Bishalgarh'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi', 'Meerut', 'Allahabad', 'Bareilly', 'Aligarh', 'Gorakhpur', 'Noida', 'Moradabad', 'Saharanpur', 'Jhansi', 'Muzaffarnagar', 'Mathura', 'Firozabad', 'Shahjahanpur', 'Rampur', 'Bulandshahr', 'Hapur', 'Sambhal', 'Amroha', 'Bijnor', 'Muzaffarnagar', 'Lakhimpur', 'Hardoi', 'Unnao', 'Rae Bareli', 'Sultanpur', 'Faizabad', 'Ambedkar Nagar', 'Azamgarh', 'Mau', 'Ghazipur', 'Jaunpur', 'Mirzapur', 'Sonbhadra', 'Chandauli', 'Bhadohi', 'Ballia', 'Deoria', 'Kushinagar', 'Maharajganj', 'Siddharthnagar', 'Basti', 'Gonda', 'Bahraich', 'Shravasti', 'Balrampur', 'Pilibhit', 'Etawah', 'Mainpuri', 'Auraiya', 'Kannauj', 'Farrukhabad', 'Hamirpur', 'Banda', 'Chitrakoot', 'Mahoba', 'Lalitpur', 'Etah', 'Kasganj', 'Hathras'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Haldwani', 'Rudrapur', 'Kashipur', 'Rishikesh', 'Pithoragarh', 'Almora', 'Nainital', 'Kotdwar', 'Ramnagar', 'Mussoorie', 'Tehri', 'Uttarkashi', 'Chamoli', 'Bageshwar', 'Champawat'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri', 'Bardhaman', 'Malda', 'Kharagpur', 'Baharampur', 'Habra', 'Kanchrapara', 'Haldia', 'Raiganj', 'Jalpaiguri', 'Cooch Behar', 'Midnapore', 'Bankura', 'Bishnupur', 'Purulia', 'Bolpur', 'Berhampore', 'Krishnanagar', 'Nabadwip', 'Ranaghat', 'Kalyani', 'Barrackpore', 'Titagarh', 'Panihati', 'Kamarhati', 'South Dum Dum', 'North Dum Dum', 'Bidhannagar', 'Chandannagar', 'Serampore', 'Uttarpara', 'Hugli', 'Arambag'],
  };

  // Common localities for major cities
  static final Map<String, List<String>> _commonLocalities = {
    // Gujarat
    'Ahmedabad': ['Navrangpura', 'Satellite', 'Bodakdev', 'Vastrapur', 'Maninagar', 'Bopal', 'Thaltej', 'Chandkheda', 'Gota', 'Sarkhej', 'Naroda', 'Ellis Bridge', 'Paldi', 'Gurukul', 'Memnagar', 'Jodhpur', 'Vejalpur', 'Ghodasar', 'Isanpur', 'Lal Darwaja', 'Odhav', 'Vatva', 'Naranpura', 'Sabarmati', 'Shahibaug', 'Bapunagar', 'Amraiwadi', 'Nikol', 'Vastral', 'Tragad', 'Motera', 'Ranip', 'Hansol', 'Bhadaj', 'Sola', 'Science City Road', 'Prahlad Nagar', 'Ambawadi', 'Nehru Nagar', 'Usmanpura', 'Drive In Road'],
    'Surat': ['Adajan', 'Vesu', 'City Light', 'Varachha', 'Katargam', 'Udhana', 'Rander', 'Olpad', 'Piplod', 'Athwa', 'Ghod Dod Road', 'Parle Point', 'Dumas', 'Althan', 'Pal', 'Bhatar', 'Palanpur', 'Amroli', 'Sachin', 'Kim', 'Kamrej', 'Magdalla', 'Dindoli', 'Pandesara', 'Limbayat', 'Salabatpura', 'Gopipura', 'Nanpura', 'Ring Road'],
    'Vadodara': ['Alkapuri', 'Fatehgunj', 'Gotri', 'Manjalpur', 'Nizampura', 'Tarsali', 'Vasna', 'Sayajigunj', 'Waghodia', 'Karelibaug', 'Akota', 'Productivity Road', 'Race Course', 'New VIP Road', 'Makarpura', 'Sama', 'Gorwa', 'Harni', 'Subhanpura', 'Chhani'],
    'Rajkot': ['Kalawad Road', 'Yagnik Road', 'Race Course', 'Sadhu Vasvani Road', 'Madhapar', 'Amin Marg', 'Sadar', 'Bajrang Wadi', 'University Road', 'Gondal Road', 'Kuvadva Road', 'Bhaktinagar', 'Raiya Road', 'Kotecha Chowk', '150 Feet Ring Road'],
    'Gandhinagar': ['Sector 1', 'Sector 7', 'Sector 11', 'Sector 14', 'Sector 21', 'Sector 23', 'Kudasan', 'Infocity', 'Adalaj', 'Koba', 'Vavol', 'Sargasan'],
    'Jamnagar': ['Bedi Gate', 'Digvijay Plot', 'Park Colony', 'Ranjit Nagar', 'Shastri Nagar', 'New Super Market', 'Khambhalia Road'],
    'Bhavnagar': ['Subhashnagar', 'Waghawadi Road', 'Kalanala', 'Crescent Circle', 'Jail Road', 'Atabhai Chowk'],
    'Junagadh': ['Kalwa Chowk', 'Chittakhana Chowk', 'Joshipura', 'Sahkar Nagar', 'Rajmahal Road'],
    'Anand': ['Vidyanagar', 'Karamsad', 'Bakrol', 'Boriavi', 'Sarsa', 'Vallabh Vidyanagar'],
    'Gandhidham': ['Ward 1', 'Ward 2', 'Ward 6', 'Ward 9', 'Ward 10', 'Ward 12', 'Adipur', 'Kandla Port'],
    'Valod': ['Valod Bazar', 'Station Road', 'Mota Bazar', 'Nana Bazar', 'Patel Street', 'Manekpor Road', 'Ashram Road', 'Talav Road'],
    'Bardoli': ['Bardoli Bazar', 'Station Road', 'Kapodra', 'Vejalpor Road', 'Sagrampura'],
    'Vyara': ['Vyara Bazar', 'Station Road', 'Ukai Road', 'Nagar Palika', 'Talav Chowk'],
    'Mahuva': ['Mahuva Bazar', 'Station Road', 'Talav Road', 'Rajmarg', 'Vegetable Market'],
    'Songadh': ['Songadh Bazar', 'Main Road', 'Ambica Nagar'],
    'Mandvi': ['Mandvi Bazar', 'Port Road', 'Station Road', 'Vijay Nagar'],
    'Umbergaon': ['Umbergaon Bazar', 'Station Road', 'GIDC', 'Nargol Road'],
    'Bilimora': ['Bilimora Bazar', 'Station Road', 'Gandevi Road', 'GIDC'],
    'Navsari': ['Navsari Bazar', 'Station Road', 'Lunsikui Road', 'Sayaji Road', 'College Road', 'Abrama Road'],
    'Valsad': ['Tithal Road', 'Station Road', 'Dharampur Road', 'Halar Road', 'Koparli Road'],

    // Maharashtra
    'Mumbai': ['Andheri', 'Bandra', 'Dadar', 'Borivali', 'Thane', 'Powai', 'Malad', 'Goregaon', 'Kandivali', 'Juhu', 'Chembur', 'Vashi', 'Navi Mumbai', 'Worli', 'Lower Parel', 'Colaba', 'Churchgate', 'Marine Lines', 'Sion', 'Mulund', 'Ghatkopar', 'Kurla', 'Bhandup', 'Mahim', 'Santacruz', 'Khar', 'Versova', 'Jogeshwari', 'Vikhroli', 'Nahur', 'Dombivli', 'Ambarnath', 'Ulhasnagar', 'Badlapur', 'Airoli', 'Ghansoli', 'Kopar Khairane', 'Turbhe', 'CBD Belapur'],
    'Pune': ['Koregaon Park', 'Kothrud', 'Viman Nagar', 'Hinjewadi', 'Baner', 'Aundh', 'Kondhwa', 'Magarpatta', 'Hadapsar', 'Shivaji Nagar', 'Deccan', 'Camp', 'Kalyani Nagar', 'Wakad', 'Pimpri', 'Chinchwad', 'Katraj', 'Ambegaon', 'Warje', 'Bibwewadi', 'Swargate', 'Yerawada', 'Vishrantwadi', 'Lohegaon', 'Wagholi', 'Nagar Road', 'Undri', 'Sus', 'Balewadi', 'Pashan', 'Bavdhan', 'Karve Nagar', 'Erandwane', 'Model Colony'],
    'Nagpur': ['Dharampeth', 'Sitabuldi', 'Manish Nagar', 'Pratap Nagar', 'Ramdaspeth', 'Sadar', 'Gandhibagh', 'Wardha Road', 'Koradi Road', 'Amravati Road', 'Hingna', 'Wadi', 'Kamptee', 'Bhandara Road', 'Trimurti Nagar', 'Nandanvan', 'Laxmi Nagar', 'Bajaj Nagar', 'Sakkardara', 'Ajni'],
    'Nashik': ['Panchavati', 'Gangapur Road', 'College Road', 'Satpur', 'Indira Nagar', 'Cidco', 'Deolali', 'Trimbak Road', 'Mumbai Naka', 'Mahatma Nagar', 'Sarda Circle', 'Nashik Road'],
    'Aurangabad': ['CIDCO', 'Garkheda', 'Usmanpura', 'Samarth Nagar', 'Jalna Road', 'Cantonment', 'Osmanpura', 'Nirala Bazar', 'TV Centre', 'Harsul'],
    'Thane': ['Vasant Vihar', 'Ghodbunder Road', 'Kasarvadavali', 'Hiranandani Estate', 'Naupada', 'Wagle Estate', 'Majiwada', 'Manpada', 'Pokhran Road', 'Kolbad', 'Kopri', 'Vartak Nagar'],
    'Solapur': ['Hotgi Road', 'Murarji Peth', 'Shivaji Nagar', 'Budhwar Peth', 'Vijapur Road'],
    'Kolhapur': ['Rajarampuri', 'Shahupuri', 'Tarabai Park', 'Kasba Bawada', 'Mangalwar Peth'],
    'Navi Mumbai': ['Vashi', 'Belapur', 'Airoli', 'Ghansoli', 'Kopar Khairane', 'Rabale', 'Turbhe', 'Sanpada', 'Nerul', 'Seawoods', 'Kharghar', 'Panvel', 'Ulwe', 'Taloja', 'Kamothe'],

    // Karnataka
    'Bangalore': ['Koramangala', 'Indiranagar', 'Whitefield', 'JP Nagar', 'HSR Layout', 'BTM Layout', 'Malleshwaram', 'Electronic City', 'Marathahalli', 'Bannerghatta Road', 'Jayanagar', 'Rajajinagar', 'Yelahanka', 'Hebbal', 'Bellandur', 'Sarjapur', 'MG Road', 'Basavanagudi', 'Domlur', 'Bommanahalli', 'Begur', 'Akshayanagar', 'Hosa Road', 'Silk Board', 'Wilson Garden', 'Richmond Town', 'Shivaji Nagar', 'Frazer Town', 'Cox Town', 'Banaswadi', 'Hoodi', 'Mahadevapura', 'Kaggadasapura', 'Varthur', 'Devanahalli', 'Kengeri', 'Vijayanagar', 'Magadi Road', 'Tumkur Road', 'Peenya'],
    'Mysore': ['Vontikoppal', 'Gokulam', 'Jayalakshmipuram', 'Vijayanagar', 'Nazarbad', 'Kuvempunagar', 'Hebbal', 'Saraswathipuram', 'Chamundipuram', 'N R Mohalla', 'Mandi Mohalla', 'Lashkar Mohalla'],
    'Mangalore': ['Kankanady', 'Bejai', 'Kadri', 'Attavar', 'Mallikatte', 'Falnir', 'Hampankatta', 'Kodialbail', 'Balmatta', 'Bendoorwell', 'Kulur', 'Urwa', 'Kavoor', 'Bikarnakatte'],
    'Hubli': ['Vidyanagar', 'Keshwapur', 'Gokul Road', 'Navalur', 'Unkal', 'Deshpande Nagar', 'Hosur', 'Lingarajnagar', 'Shirur', 'Hebsur'],
    'Belgaum': ['Camp', 'Tilakwadi', 'Shastri Nagar', 'Khanapur Road', 'Angol', 'Udyambag', 'Nehru Nagar'],
    'Gulbarga': ['Sedam Road', 'Jayanagar', 'Super Market', 'Balajinagar', 'Ashok Nagar'],

    // Delhi NCR
    'New Delhi': ['Connaught Place', 'Karol Bagh', 'Lajpat Nagar', 'Rajouri Garden', 'Dwarka', 'Rohini', 'Janakpuri', 'Saket', 'Vasant Kunj', 'Chanakyapuri', 'Mayur Vihar', 'Shahdara', 'Narela', 'Pitampura', 'Janpath', 'India Gate', 'Hauz Khas', 'Greater Kailash', 'Kalkaji', 'Okhla', 'Sarita Vihar', 'Nehru Place', 'Badarpur', 'Mehrauli', 'Chattarpur', 'Vasant Vihar', 'RK Puram', 'Moti Bagh', 'Lodhi Colony', 'Jangpura', 'Laxmi Nagar', 'Preet Vihar', 'Paschim Vihar', 'Uttam Nagar', 'Vikaspuri', 'Subhash Nagar', 'Tilak Nagar', 'Hari Nagar'],
    'Gurgaon': ['Sector 14', 'Sector 29', 'DLF Phase 1', 'DLF Phase 2', 'DLF Phase 3', 'DLF Phase 4', 'DLF Phase 5', 'Cyber Hub', 'Golf Course Road', 'MG Road', 'Sohna Road', 'Palam Vihar', 'South City', 'Nirvana Country', 'Vatika City', 'Unitech Colony', 'Sector 56', 'Sector 57', 'Sector 67', 'Sector 82', 'New Colony', 'Civil Lines', 'Sheetla Colony'],
    'Faridabad': ['Sector 14', 'Sector 16', 'Sector 21', 'NIT', 'Old Faridabad', 'Ballabgarh', 'NHPC Colony', 'Neelam Colony'],
    'Noida': ['Sector 18', 'Sector 62', 'Sector 15', 'Sector 50', 'Greater Noida', 'Indirapuram', 'Sector 44', 'Sector 45', 'Sector 55', 'Sector 56', 'Sector 78', 'Sector 100', 'Sector 110', 'Sector 119', 'Sector 120', 'Sector 137', 'Sector 150', 'Sector 168', 'Knowledge Park', 'Techzone', 'Expressway'],
    'Ghaziabad': ['Indirapuram', 'Raj Nagar', 'Vaishali', 'Kavi Nagar', 'Sahibabad', 'Vasundhara', 'Crossings Republik', 'Siddharth Vihar', 'Tronica City', 'Loni', 'Mohan Nagar', 'Shyam Park'],

    // Tamil Nadu
    'Chennai': ['T Nagar', 'Anna Nagar', 'Adyar', 'Velachery', 'Nungambakkam', 'Mylapore', 'Kodambakkam', 'Anna Salai', 'Mount Road', 'Royapettah', 'Egmore', 'Washermenpet', 'Parrys', 'Guindy', 'Tambaram', 'Pallavaram', 'Perungudi', 'Sholinganallur', 'OMR', 'Porur', 'Madipakkam', 'Besant Nagar', 'Thiruvanmiyur', 'Thoraipakkam', 'Perambur', 'Kolathur', 'Villivakkam', 'Ambattur', 'Avadi', 'Poonamallee', 'Chromepet', 'Medavakkam', 'Nanganallur', 'Alandur', 'St. Thomas Mount', 'Virugambakkam', 'Valasaravakkam', 'Ashok Nagar', 'KK Nagar'],
    'Coimbatore': ['RS Puram', 'Gandhipuram', 'Peelamedu', 'Saibaba Colony', 'Singanallur', 'Race Course', 'Ukkadam', 'Ganapathy', 'Vadavalli', 'Kuniyamuthur', 'Kovaipudur', 'Thudiyalur', 'Kalapatti', 'Avinashi Road', 'Trichy Road', 'Pollachi Road'],
    'Madurai': ['Anna Nagar', 'K.K. Nagar', 'Mattuthavani', 'Tallakulam', 'Simmakkal', 'Goripalayam', 'Vishwanathapuram', 'Koodal Nagar', 'Alwarpet', 'Palanganatham'],
    'Tiruchirappalli': ['Woraiyur', 'Srirangam', 'Thillai Nagar', 'Ariyamangalam', 'KK Nagar', 'Ponmalai', 'Teppakulam'],
    'Salem': ['Suramangalam', 'Fairlands', 'Shevapet', 'Four Roads', 'Kitchipalayam'],

    // Telangana
    'Hyderabad': ['Banjara Hills', 'Jubilee Hills', 'Madhapur', 'Kukatpally', 'Secunderabad', 'Gachibowli', 'Begumpet', 'Charminar', 'Mehdipatnam', 'Ameerpet', 'Dilsukhnagar', 'Lakdi Ka Pul', 'Hitech City', 'Miyapur', 'LB Nagar', 'Uppal', 'Habsiguda', 'Tarnaka', 'Malkajgiri', 'Sainikpuri', 'Alwal', 'Bowenpally', 'Kompally', 'Bachupally', 'Nizampet', 'Pragathi Nagar', 'KPHB Colony', 'Moosapet', 'Erragadda', 'SR Nagar', 'Yousufguda', 'Somajiguda', 'Raj Bhavan Road', 'Narayanguda', 'Himayatnagar', 'Barkatpura', 'Koti', 'Abids', 'Nampally', 'Goshamahal', 'Malakpet', 'Santoshnagar', 'Attapur', 'Rajendra Nagar', 'Shamshabad'],
    'Warangal': ['Hanamkonda', 'Kazipet', 'Subedari', 'Naimnagar', 'Desaipet', 'Shayampet', 'Balasamudram'],
    'Karimnagar': ['Jagtial Road', 'Manakondur Road', 'Sriram Nagar', 'Godavarikhani'],
    'Nizamabad': ['Dichpally', 'Armoor', 'Bodhan', 'Kammarpally'],

    // West Bengal
    'Kolkata': ['Salt Lake', 'Park Street', 'New Town', 'Ballygunge', 'Garia', 'Rajarhat', 'Esplanade', 'Dalhousie', 'Alipore', 'Behala', 'Jadavpur', 'Dum Dum', 'Barasat', 'Barrackpore', 'Tollygunge', 'Gariahat', 'Kasba', 'Dhakuria', 'Santoshpur', 'Anandapur', 'Narendrapur', 'Sonarpur', 'Jodhpur Park', 'Lake Gardens', 'Lansdowne', 'Hazra', 'Kalighat', 'New Alipore', 'Regent Park', 'Southern Avenue', 'Bhowanipore', 'Rashbehari'],
    'Howrah': ['Shibpur', 'Kadamtala', 'Bally', 'Uluberia', 'Domjur', 'Jagachha', 'Ghusuri', 'Liluah', 'Santragachi', 'Andul', 'Manikpur'],
    'Siliguri': ['Hakim Para', 'Khalpara', 'City Center', 'Patthargata', 'Pradhan Nagar', 'Sevoke Road', 'Matigara', 'Bagdogra', 'Burdwan Road'],
    'Durgapur': ['Bidhannagar', 'City Centre', 'Benachity', 'Nachan Road', 'A Zone', 'B Zone', 'C Zone'],
    'Asansol': ['Burnpur', 'Raniganj', 'Barakar', 'Kulti', 'Hirapur', 'Ukra', 'Chittaranjan'],

    // Rajasthan
    'Jaipur': ['Malviya Nagar', 'Vaishali Nagar', 'C Scheme', 'Raja Park', 'Mansarovar', 'Jhotwara', 'Tonk Road', 'Jagatpura', 'Bapu Nagar', 'Adarsh Nagar', 'Shastri Nagar', 'M.I. Road', 'Bani Park', 'Sanganer', 'Murlipura', 'Vidhyadhar Nagar', 'Nirman Nagar', 'Pratap Nagar', 'Sitapura', 'Amrapali Circle', 'Gandhi Nagar', 'Sodala', 'Gopalpura', 'Hanuman Nagar', 'New Colony'],
    'Jodhpur': ['Sardarpura', 'Ratanada', 'Paota', 'Shastri Circle', 'Basni', 'Sangria', 'Chopasni Road', 'Shyam Nagar', 'Pal Road', 'Kamla Nehru Nagar', 'Siwanchi Gate', 'Mahamandir'],
    'Udaipur': ['Hiran Magri', 'Ashok Nagar', 'Bapu Bazar', 'Fateh Sagar', 'Chetak Circle', 'Sukhadia Circle', 'Savina', 'Bedwas', 'Bhopalpura', 'Pratap Nagar', 'Ambamata', 'Udaipole'],
    'Kota': ['Talwandi', 'Vigyan Nagar', 'Mahaveer Nagar', 'Ranpur', 'Dadi Bari', 'Gumanpura', 'DCM', 'Aerodrome Circle', 'Jawahar Nagar'],
    'Bikaner': ['Ganga Shahar', 'Shastri Nagar', 'Rani Bazar', 'Sadul Ganj', 'Ambedkar Circle', 'Kote Gate'],
    'Ajmer': ['Civil Lines', 'Vaishali Nagar', 'Naya Bazar', 'Agra Gate', 'Ramganj', 'Kharsia Road'],

    // Uttar Pradesh
    'Lucknow': ['Hazratganj', 'Gomti Nagar', 'Indira Nagar', 'Aliganj', 'Aminabad', 'Chowk', 'Alambagh', 'Charbagh', 'Mahanagar', 'Jankipuram', 'Aashiana', 'Vikas Nagar', 'Rajajipuram', 'Kapoorthala', 'Sitapur Road', 'Faizabad Road', 'Kanpur Road', 'Sultanpur Road', 'Chinhat', 'Telibagh', 'Sushant Golf City'],
    'Kanpur': ['Swaroop Nagar', 'Civil Lines', 'Pandu Nagar', 'Kakadeo', 'Lajpat Nagar', 'Rawatpur', 'Kidwai Nagar', 'Arya Nagar', 'Govind Nagar', 'Khalasi Line', 'Harsh Nagar', 'Tilak Nagar', 'Shyam Nagar', 'Vikas Nagar', 'Naubasta'],
    'Agra': ['Sadar Bazar', 'Sikandra', 'Kamla Nagar', 'Dayal Bagh', 'Civil Lines', 'Taj Nagri', 'Balkeshwar', 'Pratap Pura', 'Shastri Puram', 'Trans Yamuna'],
    'Varanasi': ['Cantt', 'Lanka', 'Sigra', 'Mahmoorganj', 'Bhelupur', 'Pandeypur', 'Orderly Bazar', 'Luxa', 'Kabirchaura', 'Jaitpura', 'Sarnath'],
    'Allahabad': ['Civil Lines', 'George Town', 'Naini', 'Jhunsi', 'Colonelganj', 'Lukerganj', 'Mumfordganj', 'Kydganj', 'Bahadurganj', 'Phaphamau'],
    'Meerut': ['Civil Lines', 'Cantonment', 'Shastri Nagar', 'Ganga Nagar', 'Saket', 'Lisari Gate', 'Begum Bridge', 'Hapur Road'],
    'Bareilly': ['Civil Lines', 'Cantonment', 'Subhash Nagar', 'Ram Nagar', 'Nawabganj', 'Izatnagar'],

    // Bihar
    'Patna': ['Boring Road', 'Kankarbagh', 'Patliputra', 'Raja Bazar', 'Bailey Road', 'Ashok Rajpath', 'Gandhi Maidan', 'Rajendra Nagar', 'Saguna More', 'Phulwarisharif', 'Danapur', 'Kurji', 'Anisabad', 'Gardanibagh', 'Bankipore'],
    'Gaya': ['Civil Lines', 'Magadh Colony', 'Bodh Gaya Road', 'Delha', 'Rampur', 'Manpur', 'Tekari Road'],
    'Muzaffarpur': ['Saraiyaganj', 'Mithanpura', 'Ramna', 'Juran Chapra', 'Motijheel'],
    'Bhagalpur': ['Adampur', 'Tatarpur', 'Champanagar', 'Nath Nagar', 'Sabour'],

    // Madhya Pradesh
    'Indore': ['Vijay Nagar', 'Rajendra Nagar', 'Sapna Sangeeta', 'Geeta Bhawan', 'Malhar Mega Mall', 'Rau', 'Palasia', 'MG Road', 'Tilak Nagar', 'Sukhliya', 'Bhawarkua', 'LIG Colony', 'MIG Colony', 'Lasudia Mori', 'Ring Road', 'Dewas Naka', 'Nipania', 'Super Corridor'],
    'Bhopal': ['Arera Colony', 'Shahpura', 'Kolar Road', 'MP Nagar', 'New Market', 'Bairagarh', 'Ayodhya Nagar', 'Karond', 'Shyamla Hills', 'Nayapura', 'Rohit Nagar', 'Kotra Sultanabad', 'Hoshangabad Road', 'E-7', 'E-8', 'Govindpura'],
    'Jabalpur': ['Civil Lines', 'Vijay Nagar', 'Ranjhi', 'Gwarighat', 'Gorakhpur', 'Napier Town', 'Madan Mahal', 'Adhartal'],
    'Gwalior': ['City Centre', 'Lashkar', 'Morar', 'Thatipur', 'Hazira', 'Padav', 'Gola Ka Mandir'],

    // Punjab
    'Ludhiana': ['Model Town', 'Civil Lines', 'Ferozepur Road', 'Dugri', 'Sarabha Nagar', 'BRS Nagar', 'Bhai Randhir Singh Nagar', 'Rajguru Nagar', 'Haibowal', 'Shivpuri', 'Focal Point', 'Gill Road'],
    'Amritsar': ['Ranjit Avenue', 'Civil Lines', 'Lawrence Road', 'Golden Temple', 'Majitha Road', 'GT Road', 'Batala Road', 'Guru Nanak Dev University Area', 'Verka', 'Sultanwind'],
    'Jalandhar': ['Model Town', 'Civil Lines', 'Nakodar Road', 'Lajpat Nagar', 'Guru Nanak Colony', 'Basti Sheikh', 'Kartarpur Road'],
    'Patiala': ['Tripuri', 'Urban Estate', 'Rajpura', 'Sirhind Road', 'Lehalpur', 'Sanaur Road'],
    'Mohali': ['Phase 1', 'Phase 3B2', 'Phase 7', 'Phase 10', 'Phase 11', 'Sector 62', 'Sector 68', 'Aerocity', 'Zirakpur'],

    // Kerala
    'Thiruvananthapuram': ['Kowdiar', 'Palayam', 'Statue', 'Vellayambalam', 'Pattom', 'Karamana', 'Killipalam', 'Kesavadasapuram', 'Bakery Junction', 'MG Road', 'Vazhuthacaud', 'Thampanoor', 'Sreekaryam', 'Ulloor', 'Medical College'],
    'Kochi': ['Ernakulam', 'Fort Kochi', 'Kakkanad', 'Edappally', 'Aluva', 'Tripunithura', 'Thrippunithura', 'Maradu', 'Kalamassery', 'Perumbavoor', 'Angamaly', 'Panangad', 'Cheranalloor', 'Vyttila', 'Palarivattom'],
    'Kozhikode': ['Palayam', 'Beach Road', 'Mavoor Road', 'Nadakkavu', 'Westhill', 'Chevayur', 'Bilathikulam', 'Vandipetta'],
    'Thrissur': ['Poothole', 'Thrissur Round', 'Ollur', 'Kunnamkulam Road', 'Ayyanthole', 'Puzhakkal'],
    'Kollam': ['Chinnakada', 'Asramam', 'Mundakkal', 'Kadappakada', 'Kilikollur'],

    // Odisha
    'Bhubaneswar': ['Jaydev Vihar', 'Sahid Nagar', 'Patia', 'Khandagiri', 'Old Town', 'Nayapalli', 'Vani Vihar', 'VSS Nagar', 'IRC Village', 'Bhoi Nagar', 'Unit 4', 'Unit 6', 'Chandrasekharpur', 'Niladri Vihar', 'Dumduma'],
    'Cuttack': ['Chowdwar', 'Link Road', 'Badambadi', 'Tulsipur', 'Nayabazar', 'Buxi Bazar', 'Cantonment', 'Mangalabag', 'Dolamundai'],
    'Rourkela': ['Steel Township', 'Chhend', 'Udit Nagar', 'Bisra Road', 'Bondamunda', 'Koel Nagar'],

    // Assam
    'Guwahati': ['Dispur', 'Paltan Bazar', 'Fancy Bazar', 'Ganeshguri', 'Six Mile', 'Zoo Road', 'Bhangagarh', 'Silpukhuri', 'Ulubari', 'Lachit Nagar', 'Geetanagar', 'Hengerabari', 'Narengi', 'Beltola', 'Khanapara', 'Jalukbari', 'Azara', 'Lokhra', 'Hatigaon'],

    // Chhattisgarh
    'Raipur': ['Devendra Nagar', 'Pandri', 'Telibandha', 'Shankar Nagar', 'Avanti Vihar', 'Kankali Para', 'Sunder Nagar', 'Mowa', 'Tatiband', 'Fafadih', 'Ram Nagar', 'Saddu'],
    'Bhilai': ['Sector 1', 'Sector 2', 'Sector 6', 'Sector 9', 'Smriti Nagar', 'Supela', 'Charoda', 'Durg Road'],
    'Bilaspur': ['Gole Bazar', 'Vyapar Vihar', 'Torwa', 'Tikrapara', 'Sadar Bazar'],

    // Jharkhand
    'Ranchi': ['Lalpur', 'Doranda', 'Hinoo', 'Kokar', 'Argora', 'Booty More', 'Harmu', 'Ashok Nagar', 'Bariatu', 'Kantatoli', 'Namkum', 'Hatia'],
    'Jamshedpur': ['Bistupur', 'Sakchi', 'Sonari', 'Kadma', 'Adityapur', 'Jugsalai', 'Telco', 'Agrico', 'Baridih', 'Mango'],
    'Dhanbad': ['Bank More', 'Hirapur', 'Jharia', 'Katras', 'Sindri', 'Baghmara'],

    // Goa
    'Panaji': ['Campal', 'Fontainhas', 'Miramar', 'Caranzalem', 'Altinho', 'Dona Paula', 'Taleigao'],
    'Vasco da Gama': ['Swatantra Path', 'Mormugao', 'Baina', 'Hansa', 'Headland Sada', 'Zuarinagar'],
    'Margao': ['Monte Hill', 'Pajifond', 'Gogol', 'Fatorda', 'Aquem'],

    // Himachal Pradesh
    'Shimla': ['The Mall', 'Lakkar Bazar', 'Kasumpti', 'New Shimla', 'Chhota Shimla', 'Boileauganj', 'Vikas Nagar', 'Panthaghati', 'Mehli', 'Dhalli'],
    'Manali': ['Old Manali', 'Mall Road', 'Aleo', 'Rangri', 'Vashisht', 'Kullu Road', 'Nasogi'],
    'Dharamshala': ['McLeodganj', 'Bhagsu', 'Kotwali Bazar', 'Sidhpur', 'Forsyth Ganj'],

    // Uttarakhand
    'Dehradun': ['Rajpur Road', 'Chakrata Road', 'Sahastradhara Road', 'Clement Town', 'Patel Nagar', 'Karanpur', 'Niranjanpur', 'Raipur', 'Balliwala Chowk', 'GMS Road', 'Haridwar Road', 'Doiwala', 'Selaqui', 'Jakhan', 'Turner Road', 'Vasant Vihar'],
    'Haridwar': ['BHEL', 'Jwalapur', 'Kankhal', 'Ranipur More', 'Shivalik Nagar', 'Sidcul', 'Uttarakhand SIDCUL'],
    'Nainital': ['Mallital', 'Tallital', 'Haldwani Road', 'Bhimtal Road'],
    'Rishikesh': ['Tapovan', 'Rishikesh Bypass', 'Dehradun Road', 'Ram Jhula', 'Laxman Jhula'],

    // North East cities
    'Imphal': ['Thangal Bazar', 'Paona Bazar', 'Kwakeithel', 'Singjamei', 'Chingmeirong', 'Keishampat', 'Lamphelpat'],
    'Shillong': ['Police Bazar', 'Laitumkhrah', 'Nongthymmai', 'Mawkhar', 'Riatsamthiah', 'New Colony', 'Lachumiere'],
    'Aizawl': ['Chanmari', 'Zarkawt', 'Ramthar', 'Bawngkawn', 'Dawrpui', 'Tuikual', 'Mission Veng'],
    'Kohima': ['Kohima Village', 'Upper Shiloi', 'Lower Shiloi', 'Meriema', 'Tsiminyu'],
    'Dimapur': ['Circular Road', 'Purana Bazar', 'New Market', 'Naga Bazaar', 'Chumukedima'],
    'Gangtok': ['MG Marg', 'Tibet Road', 'Tadong', 'Ranipool', 'Deorali'],
    'Agartala': ['VIP Road', 'Krishnanagar', 'Battala', 'Ramnagar', 'Motor Stand', 'Dhaleswar'],
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

  /// Get cities in a state — fetches dynamically from Overpass API,
  /// falls back to static data if the API call fails or returns empty.
  static Future<List<Place>> getCitiesInState(String stateName) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_citiesCacheKeyPrefix$stateName';
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      final List<dynamic> jsonList = json.decode(cached);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    List<Place> cities = [];

    try {
      cities = await _fetchCitiesFromOverpass(stateName);
    } catch (e) {
      print('DEBUG: Overpass city fetch failed, using static fallback: $e');
    }

    // Static fallback if API fails or returns nothing
    if (cities.isEmpty) {
      final cityNames = _indianCities[stateName] ?? [];
      cities = cityNames.map((cityName) => Place(
        geonameId: cityName,
        name: cityName,
        adminName1: stateName,
      )).toList();
    }

    // Cache
    await prefs.setString(cacheKey, json.encode(cities.map((c) => c.toJson()).toList()));

    return cities;
  }

  /// Fetch cities/towns in a state using Overpass API.
  static Future<List<Place>> _fetchCitiesFromOverpass(String stateName) async {
    // Step 1: Resolve state OSM area ID via Nominatim
    final geocodeQuery = Uri.encodeComponent('$stateName, India');
    final geocodeResp = await http.get(
      Uri.parse('$_baseUrl/search?q=$geocodeQuery&format=json&limit=1&addressdetails=0'),
      headers: {'User-Agent': _userAgent},
    );

    if (geocodeResp.statusCode != 200) {
      throw Exception('Nominatim geocode failed for state: ${geocodeResp.statusCode}');
    }

    final geocodeData = json.decode(geocodeResp.body) as List<dynamic>;
    if (geocodeData.isEmpty) {
      throw Exception('State not found in Nominatim: $stateName');
    }

    final osmType = geocodeData[0]['osm_type'] as String? ?? '';
    final osmId = int.tryParse(geocodeData[0]['osm_id']?.toString() ?? '');
    if (osmId == null) {
      throw Exception('No OSM ID for state: $stateName');
    }

    int areaId;
    if (osmType == 'relation') {
      areaId = 3600000000 + osmId;
    } else if (osmType == 'way') {
      areaId = 2400000000 + osmId;
    } else {
      areaId = osmId;
    }

    // Step 2: Query Overpass for city/town/municipality nodes inside the state
    final overpassQuery = '''
[out:json][timeout:30];
area($areaId)->.state;
(
  node["place"~"city|town|municipality"](area.state);
  way["place"~"city|town|municipality"](area.state);
);
out center 300;
''';

    final overpassResp = await http.post(
      Uri.parse(_overpassUrl),
      headers: {
        'User-Agent': _userAgent,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'data=${Uri.encodeComponent(overpassQuery)}',
    );

    if (overpassResp.statusCode != 200) {
      throw Exception('Overpass API failed for cities: ${overpassResp.statusCode}');
    }

    final overpassData = json.decode(overpassResp.body) as Map<String, dynamic>;
    final elements = overpassData['elements'] as List<dynamic>? ?? [];

    final List<Place> cities = [];
    final Set<String> seen = {};

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = (tags['name'] as String?) ?? '';
      if (name.isEmpty || seen.contains(name)) continue;
      seen.add(name);

      final lat = (el['lat'] ?? el['center']?['lat']) as num?;
      final lon = (el['lon'] ?? el['center']?['lon']) as num?;

      cities.add(Place(
        geonameId: '${el['type']}_${el['id']}',
        name: name,
        adminName1: stateName,
        lat: lat?.toDouble(),
        lng: lon?.toDouble(),
      ));
    }

    // Sort alphabetically
    cities.sort((a, b) => a.name.compareTo(b.name));
    return cities;
  }

  /// Get localities in a city
  /// Priority: India Postal API → Overpass OSM → static fallback
  static Future<List<Place>> getLocalitiesInCity(String cityName, String stateName) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_areasCacheKeyPrefix${cityName}_$stateName';
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      final List<dynamic> jsonList = json.decode(cached);
      return jsonList.map((json) => Place.fromJson(json)).toList();
    }

    List<Place> localities = [];

    // 1. Try India Postal Pincode API (most comprehensive for India)
    try {
      localities = await _fetchLocalitiesFromPostalApi(cityName, stateName);
    } catch (e) {
      print('DEBUG: Postal API failed: $e');
    }

    // 2. Try Overpass OSM if postal API returned nothing
    if (localities.isEmpty) {
      try {
        localities = await _fetchLocalitiesFromOSM(cityName, stateName);
      } catch (e) {
        print('DEBUG: OSM fetch failed: $e');
      }
    }

    // 3. Static fallback
    if (localities.isEmpty) {
      final localityNames = _commonLocalities[cityName] ?? [
        '$cityName Bazar',
        'Station Road',
        'Main Road',
        'Nagar Palika Area',
        'Old Town',
        'New Colony',
        'Market Area',
      ];
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

  /// Fetch localities using India Postal Pincode API (free, no key, covers all of India)
  /// Step 1: Search city name → get its pincode
  /// Step 2: Search by pincode → get all branch post offices (real locality names)
  static Future<List<Place>> _fetchLocalitiesFromPostalApi(String cityName, String stateName) async {
    final cityNameLower = cityName.toLowerCase();
    final stateNameLower = stateName.toLowerCase();

    // Step 1: Get pincode for the city
    final encodedCity = Uri.encodeComponent(cityName);
    final step1Resp = await http.get(
      Uri.parse('$_postalApiUrl/$encodedCity'),
      headers: {'User-Agent': _userAgent},
    );

    if (step1Resp.statusCode != 200) {
      throw Exception('Postal API step1 HTTP error: ${step1Resp.statusCode}');
    }

    final List<dynamic> step1Data = json.decode(step1Resp.body);
    if (step1Data.isEmpty) throw Exception('Empty step1 response');

    final step1Result = step1Data[0] as Map<String, dynamic>;
    if (step1Result['Status'] != 'Success') {
      throw Exception('City not found in Postal API: $cityName');
    }

    final step1PostOffices = step1Result['PostOffice'] as List<dynamic>? ?? [];

    // Find the pincode for this city in the correct state
    String? pincode;
    for (final po in step1PostOffices) {
      final poState = (po['State'] as String? ?? '').toLowerCase();
      final poPincode = po['Pincode']?.toString() ?? '';
      if (poPincode.isNotEmpty &&
          (poState == stateNameLower ||
           poState.contains(stateNameLower) ||
           stateNameLower.contains(poState))) {
        pincode = poPincode;
        break;
      }
    }

    if (pincode == null || pincode.isEmpty) {
      throw Exception('No pincode found for $cityName in $stateName');
    }

    // Step 2: Fetch the city pincode + adjacent pincodes (±20) in parallel
    // to collect all localities across the city/taluka area
    final basePin = int.tryParse(pincode);
    if (basePin == null) throw Exception('Invalid pincode: $pincode');

    final pincodeRange = List.generate(41, (i) => basePin - 20 + i);

    final futures = pincodeRange.map((pin) => http
        .get(Uri.parse('https://api.postalpincode.in/pincode/$pin'),
            headers: {'User-Agent': _userAgent})
        .then((r) => r.statusCode == 200 ? json.decode(r.body) : null)
        .catchError((_) => null));

    final results = await Future.wait(futures);

    final List<Place> localities = [];
    final Set<String> seen = {};

    for (final result in results) {
      if (result == null) continue;
      final List<dynamic> dataList = result as List<dynamic>;
      if (dataList.isEmpty) continue;
      final resultMap = dataList[0] as Map<String, dynamic>;
      if (resultMap['Status'] != 'Success') continue;

      final postOffices = resultMap['PostOffice'] as List<dynamic>? ?? [];
      for (final po in postOffices) {
        final name = (po['Name'] as String? ?? '').trim();
        final block = (po['Block'] as String? ?? '').toLowerCase();
        final poState = (po['State'] as String? ?? '').toLowerCase();

        if (name.isEmpty || seen.contains(name)) continue;
        if (name.toLowerCase() == cityNameLower) continue;

        // Only include post offices in the same block/taluka or state
        // to avoid pulling in completely unrelated areas
        final inSameBlock = block == cityNameLower ||
            block.contains(cityNameLower) ||
            cityNameLower.contains(block);
        final inSameState = poState == stateNameLower ||
            poState.contains(stateNameLower) ||
            stateNameLower.contains(poState);

        if (!inSameState) continue;
        // For adjacent pincodes, only include if same block
        final pin = (po['Pincode']?.toString() ?? '');
        if (pin != pincode && !inSameBlock) continue;

        seen.add(name);
        localities.add(Place(
          geonameId: 'postal_${pin}_$name',
          name: name,
          adminName1: stateName,
          adminName2: cityName,
        ));
      }
    }

    // Sort alphabetically
    localities.sort((a, b) => a.name.compareTo(b.name));
    return localities;
  }

  /// Fetch localities using Overpass API — queries suburbs/neighbourhoods inside the city boundary.
  /// For cities that are OSM relations/ways (have a boundary), uses area-based query.
  /// For cities that are OSM nodes (no boundary, e.g. small towns), uses radius-based query.
  static Future<List<Place>> _fetchLocalitiesFromOSM(String cityName, String stateName) async {
    // Step 1: Resolve the city via Nominatim — need osm_type, osm_id and lat/lon
    final geocodeQuery = Uri.encodeComponent('$cityName, $stateName, India');
    final geocodeResp = await http.get(
      Uri.parse('$_baseUrl/search?q=$geocodeQuery&format=json&limit=1&addressdetails=0'),
      headers: {'User-Agent': _userAgent},
    );

    if (geocodeResp.statusCode != 200) {
      throw Exception('Nominatim geocode failed: ${geocodeResp.statusCode}');
    }

    final geocodeData = json.decode(geocodeResp.body) as List<dynamic>;
    if (geocodeData.isEmpty) {
      throw Exception('City not found in Nominatim: $cityName');
    }

    final osmType = geocodeData[0]['osm_type'] as String? ?? '';
    final osmId = int.tryParse(geocodeData[0]['osm_id']?.toString() ?? '');
    final cityLat = double.tryParse(geocodeData[0]['lat']?.toString() ?? '');
    final cityLon = double.tryParse(geocodeData[0]['lon']?.toString() ?? '');

    if (osmId == null) {
      throw Exception('No OSM ID for city: $cityName');
    }

    String overpassQuery;

    if (osmType == 'relation' || osmType == 'way') {
      // City has a boundary — query inside the area
      final int areaId = osmType == 'relation'
          ? 3600000000 + osmId
          : 2400000000 + osmId;

      overpassQuery = '''
[out:json][timeout:25];
area($areaId)->.city;
(
  node["place"~"suburb|neighbourhood|quarter|residential|village|hamlet"](area.city);
  way["place"~"suburb|neighbourhood|quarter|residential"](area.city);
);
out center 150;
''';
    } else {
      // City is a node (no boundary) — two-pass radius-based search
      if (cityLat == null || cityLon == null) {
        throw Exception('No coordinates for city node: $cityName');
      }
      // Pass 1: strict sub-city place types within 10km
      overpassQuery = '''
[out:json][timeout:30];
(
  node["place"~"suburb|neighbourhood|quarter|locality|isolated_dwelling"](around:10000,$cityLat,$cityLon);
  way["place"~"suburb|neighbourhood|quarter|locality"](around:10000,$cityLat,$cityLon);
);
out center 200;
''';

      // Run pass 1 first — if it returns results, we'll use them
      // If not, _fetchLocalitiesFromOSM returns empty → caller does pass 2 via fallback
      // We handle pass 2 inline here:
      final pass1Resp = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'User-Agent': _userAgent,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'data=${Uri.encodeComponent(overpassQuery)}',
      );

      if (pass1Resp.statusCode == 200) {
        final pass1Data = json.decode(pass1Resp.body) as Map<String, dynamic>;
        final pass1Elements = pass1Data['elements'] as List<dynamic>? ?? [];
        final cityNameLower = cityName.toLowerCase();
        final List<Place> pass1Localities = [];
        final Set<String> pass1Seen = {};

        for (final el in pass1Elements) {
          final tags = el['tags'] as Map<String, dynamic>? ?? {};
          final name = (tags['name'] as String?) ?? '';
          final placeType = (tags['place'] as String?) ?? '';
          if (name.isEmpty || pass1Seen.contains(name)) continue;
          if (name.toLowerCase() == cityNameLower) continue;
          if (placeType == 'town' || placeType == 'city' || placeType == 'municipality' ||
              placeType == 'village' || placeType == 'hamlet') continue;
          pass1Seen.add(name);
          final lat = (el['lat'] ?? el['center']?['lat']) as num?;
          final lon = (el['lon'] ?? el['center']?['lon']) as num?;
          pass1Localities.add(Place(
            geonameId: '${el['type']}_${el['id']}',
            name: name,
            adminName1: stateName,
            adminName2: cityName,
            lat: lat?.toDouble(),
            lng: lon?.toDouble(),
          ));
        }

        if (pass1Localities.isNotEmpty) {
          pass1Localities.sort((a, b) => a.name.compareTo(b.name));
          return pass1Localities;
        }
      }

      // Pass 2: include villages/hamlets within tight 5km radius
      overpassQuery = '''
[out:json][timeout:30];
(
  node["place"~"suburb|neighbourhood|quarter|locality|village|hamlet|isolated_dwelling"](around:5000,$cityLat,$cityLon);
  way["place"~"suburb|neighbourhood|quarter|locality|village|hamlet"](around:5000,$cityLat,$cityLon);
);
out center 200;
''';
    }

    final overpassResp = await http.post(
      Uri.parse(_overpassUrl),
      headers: {
        'User-Agent': _userAgent,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'data=${Uri.encodeComponent(overpassQuery)}',
    );

    if (overpassResp.statusCode != 200) {
      throw Exception('Overpass API failed: ${overpassResp.statusCode}');
    }

    final overpassData = json.decode(overpassResp.body) as Map<String, dynamic>;
    final elements = overpassData['elements'] as List<dynamic>? ?? [];

    final List<Place> localities = [];
    final Set<String> seen = {};

    final cityNameLower = cityName.toLowerCase();

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = (tags['name'] as String?) ?? '';
      final placeType = (tags['place'] as String?) ?? '';

      if (name.isEmpty || seen.contains(name)) continue;
      // Skip the city itself appearing in its own locality list
      if (name.toLowerCase() == cityNameLower) continue;
      // Skip only city/town-level places — village/hamlet allowed as they are sub-localities
      if (placeType == 'town' || placeType == 'city' || placeType == 'municipality') continue;

      seen.add(name);

      final lat = (el['lat'] ?? el['center']?['lat']) as num?;
      final lon = (el['lon'] ?? el['center']?['lon']) as num?;

      localities.add(Place(
        geonameId: '${el['type']}_${el['id']}',
        name: name,
        adminName1: stateName,
        adminName2: cityName,
        lat: lat?.toDouble(),
        lng: lon?.toDouble(),
      ));
    }

    // Sort alphabetically for consistent display
    localities.sort((a, b) => a.name.compareTo(b.name));
    return localities;
  }

  /// =========================================================================
  /// SQLite-first query methods.
  /// These try the local SQLite database first and fall back to the existing
  /// API-based methods when the DB returns no results.
  /// =========================================================================

  /// Get states from SQLite, falling back to API.
  static Future<List<StateModel>> getStatesFromDb() async {
    try {
      final states = await DatabaseHelper.instance.getStates();
      if (states.isNotEmpty) return states;
    } catch (e) {
      print('DEBUG: SQLite getStates failed, falling back to API: $e');
    }

    // Fallback: convert API Place objects to StateModel
    final places = await getIndianStates();
    return places
        .asMap()
        .entries
        .map((e) => StateModel(id: e.key + 1, name: e.value.name))
        .toList();
  }

  /// Get cities for a state from SQLite, falling back to API.
  ///
  /// [stateId] is the SQLite row id from [StateModel.id].
  /// [stateName] is used as the API fallback key.
  static Future<List<CityModel>> getCitiesFromDb(
    int stateId,
    String stateName,
  ) async {
    try {
      final cities = await DatabaseHelper.instance.getCitiesByState(stateId);
      if (cities.isNotEmpty) return cities;
    } catch (e) {
      print('DEBUG: SQLite getCities failed, falling back to API: $e');
    }

    // Fallback: convert API Place objects to CityModel
    final places = await getCitiesInState(stateName);
    return places
        .asMap()
        .entries
        .map((e) => CityModel(
              id: e.key + 1,
              name: e.value.name,
              stateId: stateId,
            ))
        .toList();
  }

  /// Get areas for a city from SQLite, falling back to API.
  ///
  /// [cityId] is the SQLite row id from [CityModel.id].
  /// [cityName] and [stateName] are used as API fallback keys.
  static Future<List<AreaModel>> getAreasFromDb(
    int cityId,
    String cityName,
    String stateName,
  ) async {
    try {
      final areas = await DatabaseHelper.instance.getAreasByCity(cityId);
      if (areas.isNotEmpty) return areas;
    } catch (e) {
      print('DEBUG: SQLite getAreas failed, falling back to API: $e');
    }

    // Fallback: convert API Place objects to AreaModel
    final places = await getLocalitiesInCity(cityName, stateName);
    return places
        .asMap()
        .entries
        .map((e) => AreaModel(
              id: e.key + 1,
              name: e.value.name,
              cityId: cityId,
              latitude: e.value.lat,
              longitude: e.value.lng,
            ))
        .toList();
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
