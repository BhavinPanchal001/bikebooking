#!/bin/bash
# Generate locations.db from static data using sqlite3 CLI
# Usage: bash tools/generate_db.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PATH="$PROJECT_ROOT/assets/db/locations.db"

# Remove existing DB
rm -f "$DB_PATH"

echo "Creating database at: $DB_PATH"

sqlite3 "$DB_PATH" <<'SCHEMA'
PRAGMA foreign_keys = ON;

CREATE TABLE states (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  TEXT NOT NULL UNIQUE
);

CREATE TABLE cities (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT NOT NULL,
  state_id  INTEGER NOT NULL,
  FOREIGN KEY (state_id) REFERENCES states(id),
  UNIQUE(name, state_id)
);

CREATE TABLE areas (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT NOT NULL,
  city_id   INTEGER NOT NULL,
  latitude  REAL,
  longitude REAL,
  FOREIGN KEY (city_id) REFERENCES cities(id),
  UNIQUE(name, city_id)
);

CREATE INDEX idx_cities_state_id ON cities(state_id);
CREATE INDEX idx_areas_city_id ON areas(city_id);
CREATE INDEX idx_states_name ON states(name);
CREATE INDEX idx_cities_name ON cities(name);
CREATE INDEX idx_areas_name ON areas(name);

-- ========== STATES ==========
INSERT INTO states (name) VALUES
('Andhra Pradesh'),('Arunachal Pradesh'),('Assam'),('Bihar'),('Chhattisgarh'),
('Delhi'),('Goa'),('Gujarat'),('Haryana'),('Himachal Pradesh'),
('Jharkhand'),('Karnataka'),('Kerala'),('Madhya Pradesh'),('Maharashtra'),
('Manipur'),('Meghalaya'),('Mizoram'),('Nagaland'),('Odisha'),
('Punjab'),('Rajasthan'),('Sikkim'),('Tamil Nadu'),('Telangana'),
('Tripura'),('Uttar Pradesh'),('Uttarakhand'),('West Bengal');

SCHEMA

# Now insert cities using a Python-like approach via heredoc
# We'll use a function to get state_id and insert cities

insert_cities() {
  local state_name="$1"
  shift
  local state_id
  state_id=$(sqlite3 "$DB_PATH" "SELECT id FROM states WHERE name='$state_name';")
  for city in "$@"; do
    sqlite3 "$DB_PATH" "INSERT INTO cities (name, state_id) VALUES ('$(echo "$city" | sed "s/'/''/g")', $state_id);"
  done
}

insert_areas() {
  local city_name="$1"
  shift
  local city_id
  city_id=$(sqlite3 "$DB_PATH" "SELECT id FROM cities WHERE name='$(echo "$city_name" | sed "s/'/''/g")' LIMIT 1;")
  if [ -z "$city_id" ]; then
    echo "WARNING: City not found: $city_name"
    return
  fi
  for area in "$@"; do
    sqlite3 "$DB_PATH" "INSERT INTO areas (name, city_id) VALUES ('$(echo "$area" | sed "s/'/''/g")', $city_id);"
  done
}

echo "Inserting cities..."

insert_cities "Andhra Pradesh" "Visakhapatnam" "Vijayawada" "Guntur" "Nellore" "Kurnool" "Rajahmundry" "Tirupati" "Kakinada" "Anantapur" "Kadapa" "Eluru" "Ongole" "Chittoor" "Machilipatnam" "Tenali" "Proddatur" "Adoni" "Hindupur" "Srikakulam" "Vizianagaram" "Bhimavaram" "Tadepalligudem" "Gudivada" "Narasaraopet" "Tadipatri" "Amaravati"

insert_cities "Arunachal Pradesh" "Itanagar" "Naharlagun" "Pasighat" "Namsai" "Bomdila" "Tawang" "Ziro" "Aalo" "Tezu" "Roing" "Changlang" "Khonsa"

insert_cities "Assam" "Guwahati" "Silchar" "Dibrugarh" "Nagaon" "Jorhat" "Tinsukia" "Tezpur" "Bongaigaon" "Karimganj" "Sivasagar" "Goalpara" "Barpeta" "Dhubri" "Lakhimpur" "Kamrup" "Haflong" "Diphu" "Nalbari" "Hojai" "Golaghat"

insert_cities "Bihar" "Patna" "Gaya" "Bhagalpur" "Muzaffarpur" "Darbhanga" "Arrah" "Begusarai" "Katihar" "Chapra" "Purnia" "Saharsa" "Hajipur" "Bettiah" "Sasaram" "Motihari" "Munger" "Supaul" "Madhubani" "Sitamarhi" "Siwan" "Jehanabad" "Nalanda" "Nawada" "Aurangabad" "Kishanganj"

insert_cities "Chhattisgarh" "Raipur" "Bhilai" "Korba" "Bilaspur" "Durg" "Rajnandgaon" "Jagdalpur" "Ambikapur" "Raigarh" "Janjgir" "Mahasamund" "Dhamtari" "Kanker" "Kondagaon" "Kawardha" "Bemetara" "Mungeli"

insert_cities "Delhi" "New Delhi" "Delhi Cantonment" "Dwarka" "Rohini" "Karol Bagh" "Lajpat Nagar" "Rajouri Garden" "Janakpuri" "Saket" "Vasant Kunj" "Chanakyapuri" "Mayur Vihar" "Shahdara" "Narela" "Pitampura" "Preet Vihar" "Laxmi Nagar" "Uttam Nagar" "Vikaspuri" "Paschim Vihar" "Seelampur" "Dilshad Garden" "Yamuna Vihar" "Burari" "Bawana" "Mundka"

insert_cities "Goa" "Panaji" "Vasco da Gama" "Margao" "Mapusa" "Ponda" "Bicholim" "Valpoi" "Curchorem" "Sanquelim" "Calangute" "Candolim" "Morjim" "Pernem" "Quepem" "Sanguem" "Cuncolim"

insert_cities "Gujarat" "Ahmedabad" "Surat" "Vadodara" "Rajkot" "Bhavnagar" "Jamnagar" "Gandhinagar" "Junagadh" "Anand" "Navsari" "Morbi" "Nadiad" "Surendranagar" "Bharuch" "Mehsana" "Patan" "Porbandar" "Godhra" "Amreli" "Valsad" "Botad" "Dahod" "Palanpur" "Kheda" "Veraval" "Dwarka" "Gandhidham" "Kutch" "Kalol" "Ankleshwar" "Gondal" "Jetpur" "Wankaner" "Vapi" "Billimora"

insert_cities "Haryana" "Faridabad" "Gurgaon" "Panipat" "Ambala" "Yamunanagar" "Rohtak" "Hisar" "Karnal" "Sonipat" "Panchkula" "Bhiwani" "Sirsa" "Jind" "Kurukshetra" "Rewari" "Palwal" "Fatehabad" "Jhajjar" "Kaithal" "Nuh" "Mahendragarh" "Bahadurgarh" "Narnaul" "Hansi" "Thanesar"

insert_cities "Himachal Pradesh" "Shimla" "Mandi" "Solan" "Dharamshala" "Palampur" "Baddi" "Nahan" "Una" "Kullu" "Manali" "Bilaspur" "Hamirpur" "Chamba" "Kangra" "Keylong" "Rampur" "Sundernagar" "Sarkaghat"

insert_cities "Jharkhand" "Ranchi" "Jamshedpur" "Dhanbad" "Bokaro" "Deoghar" "Hazaribagh" "Giridih" "Medininagar" "Phusro" "Ramgarh" "Dumka" "Chaibasa" "Lohardaga" "Pakur" "Simdega" "Khunti" "Sahibganj" "Godda" "Gumla"

insert_cities "Karnataka" "Bangalore" "Mysore" "Hubli" "Mangalore" "Belgaum" "Gulbarga" "Davanagere" "Bellary" "Bijapur" "Shimoga" "Tumkur" "Raichur" "Hassan" "Udupi" "Bidar" "Chitradurga" "Kolar" "Mandya" "Chamarajanagar" "Dharwad" "Gadag" "Haveri" "Koppal" "Chikmagalur" "Bagalkot" "Yadgir" "Ramnagara" "Kodagu" "Chikkaballapur" "Vijayapura" "Hosapete"

insert_cities "Kerala" "Thiruvananthapuram" "Kochi" "Kozhikode" "Kollam" "Thrissur" "Alappuzha" "Palakkad" "Malappuram" "Kannur" "Kottayam" "Pathanamthitta" "Idukki" "Wayanad" "Kasaragod" "Ernakulam" "Ponnani" "Chalakudy" "Irinjalakuda" "Kayamkulam" "Varkala" "Attingal" "Nedumangad" "Thalassery" "Vatakara" "Kalpetta"

insert_cities "Madhya Pradesh" "Indore" "Bhopal" "Jabalpur" "Gwalior" "Ujjain" "Sagar" "Dewas" "Satna" "Ratlam" "Rewa" "Katni" "Singrauli" "Burhanpur" "Khandwa" "Chhindwara" "Damoh" "Mandsaur" "Neemuch" "Hoshangabad" "Itarsi" "Vidisha" "Betul" "Shajapur" "Seoni" "Balaghat" "Chhatarpur" "Tikamgarh" "Shivpuri" "Guna" "Morena" "Bhind" "Datia"

insert_cities "Maharashtra" "Mumbai" "Pune" "Nagpur" "Thane" "Nashik" "Kalyan" "Vasai" "Aurangabad" "Solapur" "Amravati" "Kolhapur" "Navi Mumbai" "Sangli" "Jalgaon" "Akola" "Latur" "Dhule" "Ahmednagar" "Chandrapur" "Parbhani" "Nanded" "Ichalkaranji" "Panvel" "Bhiwandi" "Malegaon" "Jalna" "Osmanabad" "Ratnagiri" "Satara" "Beed" "Yavatmal" "Wardha" "Buldhana" "Hingoli" "Washim" "Gondia" "Bhandara" "Gadchiroli" "Sindhudurg" "Raigad" "Alibag"

insert_cities "Manipur" "Imphal" "Thoubal" "Kakching" "Lilong" "Bishnupur" "Churachandpur" "Ukhrul" "Senapati" "Tamenglong" "Chandel" "Jiribam"

insert_cities "Meghalaya" "Shillong" "Tura" "Nongstoin" "Jowai" "Baghmara" "Williamnagar" "Resubelpara" "Mairang" "Nongpoh" "Cherrapunjee"

insert_cities "Mizoram" "Aizawl" "Lunglei" "Saiha" "Champhai" "Kolasib" "Serchhip" "Mamit" "Lawngtlai" "Hnahthial"

insert_cities "Nagaland" "Kohima" "Dimapur" "Mokokchung" "Tuensang" "Wokha" "Zunheboto" "Mon" "Phek" "Longleng" "Kiphire" "Noklak"

insert_cities "Odisha" "Bhubaneswar" "Cuttack" "Rourkela" "Berhampur" "Sambalpur" "Puri" "Balasore" "Baripada" "Bhadrak" "Jharsuguda" "Jeypore" "Angul" "Dhenkanal" "Kendrapara" "Paradip" "Koraput" "Sundargarh" "Keonjhar" "Rayagada" "Bargarh" "Nabarangpur" "Malkangiri" "Bhawanipatna" "Bolangir" "Phulbani" "Kendujhar"

insert_cities "Punjab" "Ludhiana" "Amritsar" "Jalandhar" "Patiala" "Bathinda" "Mohali" "Pathankot" "Hoshiarpur" "Moga" "Firozpur" "Kapurthala" "Faridkot" "Gurdaspur" "Rupnagar" "Nawanshahr" "Barnala" "Muktsar" "Sangrur" "Fatehgarh Sahib" "Tarn Taran" "Mansa" "Fazilka" "Abohar" "Phagwara" "Khanna" "Rajpura" "Zirakpur"

insert_cities "Rajasthan" "Jaipur" "Jodhpur" "Udaipur" "Kota" "Bikaner" "Ajmer" "Bhilwara" "Alwar" "Bharatpur" "Sikar" "Pali" "Tonk" "Kishangarh" "Beawar" "Hanumangarh" "Sri Ganganagar" "Churu" "Jhunjhunu" "Nagaur" "Barmer" "Jaisalmer" "Sawai Madhopur" "Dausa" "Dholpur" "Karauli" "Bundi" "Jhalawar" "Baran" "Dungarpur" "Banswara" "Rajsamand" "Pratapgarh" "Chittorgarh"

insert_cities "Sikkim" "Gangtok" "Namchi" "Gyalshing" "Rangpo" "Singtam" "Jorethang" "Mangan" "Ravangla" "Yuksom"

insert_cities "Tamil Nadu" "Chennai" "Coimbatore" "Madurai" "Tiruchirappalli" "Salem" "Tiruppur" "Erode" "Vellore" "Thoothukudi" "Dindigul" "Thanjavur" "Sivakasi" "Cuddalore" "Kanchipuram" "Rameswaram" "Tirunelveli" "Nagercoil" "Karur" "Namakkal" "Ariyalur" "Perambalur" "Villupuram" "Krishnagiri" "Dharmapuri" "Nilgiris" "Tiruvannamalai" "Pudukkottai" "Ramanathapuram" "Sivaganga" "Virudhunagar" "Theni" "Kallakurichi" "Ranipet" "Chengalpattu" "Tenkasi" "Mayiladuthurai" "Tirupattur"

insert_cities "Telangana" "Hyderabad" "Warangal" "Nizamabad" "Karimnagar" "Ramagundam" "Khammam" "Mahbubnagar" "Nalgonda" "Adilabad" "Suryapet" "Siddipet" "Vikarabad" "Wanaparthy" "Gadwal" "Nagarkurnool" "Narayanpet" "Jagtial" "Mancherial" "Nirmal" "Kumuram Bheem" "Peddapalli" "Jayashankar" "Mulugu" "Bhadradri Kothagudem" "Yadadri Bhongir" "Medchal" "Sangareddy" "Medak" "Kamareddy" "Rajanna Sircilla" "Jangaon"

insert_cities "Tripura" "Agartala" "Udaipur" "Dharmanagar" "Kailashahar" "Belonia" "Sabroom" "Ambassa" "Khowai" "Sonamura" "Bishalgarh"

insert_cities "Uttar Pradesh" "Lucknow" "Kanpur" "Ghaziabad" "Agra" "Varanasi" "Meerut" "Allahabad" "Bareilly" "Aligarh" "Gorakhpur" "Noida" "Moradabad" "Saharanpur" "Jhansi" "Muzaffarnagar" "Mathura" "Firozabad" "Shahjahanpur" "Rampur" "Bulandshahr" "Hapur" "Sambhal" "Amroha" "Bijnor" "Lakhimpur" "Hardoi" "Unnao" "Rae Bareli" "Sultanpur" "Faizabad" "Ambedkar Nagar" "Azamgarh" "Mau" "Ghazipur" "Jaunpur" "Mirzapur" "Sonbhadra" "Chandauli" "Bhadohi" "Ballia" "Deoria" "Kushinagar" "Maharajganj" "Siddharthnagar" "Basti" "Gonda" "Bahraich" "Shravasti" "Balrampur" "Pilibhit" "Etawah" "Mainpuri" "Auraiya" "Kannauj" "Farrukhabad" "Hamirpur" "Banda" "Chitrakoot" "Mahoba" "Lalitpur" "Etah" "Kasganj" "Hathras"

insert_cities "Uttarakhand" "Dehradun" "Haridwar" "Roorkee" "Haldwani" "Rudrapur" "Kashipur" "Rishikesh" "Pithoragarh" "Almora" "Nainital" "Kotdwar" "Ramnagar" "Mussoorie" "Tehri" "Uttarkashi" "Chamoli" "Bageshwar" "Champawat"

insert_cities "West Bengal" "Kolkata" "Howrah" "Durgapur" "Asansol" "Siliguri" "Bardhaman" "Malda" "Kharagpur" "Baharampur" "Habra" "Kanchrapara" "Haldia" "Raiganj" "Jalpaiguri" "Cooch Behar" "Midnapore" "Bankura" "Bishnupur" "Purulia" "Bolpur" "Berhampore" "Krishnanagar" "Nabadwip" "Ranaghat" "Kalyani" "Barrackpore" "Titagarh" "Panihati" "Kamarhati" "South Dum Dum" "North Dum Dum" "Bidhannagar" "Chandannagar" "Serampore" "Uttarpara" "Hugli" "Arambag"

echo "Inserting areas..."

# Gujarat
insert_areas "Ahmedabad" "Navrangpura" "Satellite" "Bodakdev" "Vastrapur" "Maninagar" "Bopal" "Thaltej" "Chandkheda" "Gota" "Sarkhej" "Naroda" "Ellis Bridge" "Paldi" "Gurukul" "Memnagar" "Jodhpur" "Vejalpur" "Ghodasar" "Isanpur" "Lal Darwaja" "Odhav" "Vatva" "Naranpura" "Sabarmati" "Shahibaug" "Bapunagar" "Amraiwadi" "Nikol" "Vastral" "Tragad" "Motera" "Ranip" "Hansol" "Bhadaj" "Sola" "Science City Road" "Prahlad Nagar" "Ambawadi" "Nehru Nagar" "Usmanpura" "Drive In Road"
insert_areas "Surat" "Adajan" "Vesu" "City Light" "Varachha" "Katargam" "Udhana" "Rander" "Olpad" "Piplod" "Athwa" "Ghod Dod Road" "Parle Point" "Dumas" "Althan" "Pal" "Bhatar" "Palanpur" "Amroli" "Sachin" "Kim" "Kamrej" "Magdalla" "Dindoli" "Pandesara" "Limbayat" "Salabatpura" "Gopipura" "Nanpura" "Ring Road"
insert_areas "Vadodara" "Alkapuri" "Fatehgunj" "Gotri" "Manjalpur" "Nizampura" "Tarsali" "Vasna" "Sayajigunj" "Waghodia" "Karelibaug" "Akota" "Productivity Road" "Race Course" "New VIP Road" "Makarpura" "Sama" "Gorwa" "Harni" "Subhanpura" "Chhani"
insert_areas "Rajkot" "Kalawad Road" "Yagnik Road" "Race Course" "Sadhu Vasvani Road" "Madhapar" "Amin Marg" "Sadar" "Bajrang Wadi" "University Road" "Gondal Road" "Kuvadva Road" "Bhaktinagar" "Raiya Road" "Kotecha Chowk" "150 Feet Ring Road"
insert_areas "Gandhinagar" "Sector 1" "Sector 7" "Sector 11" "Sector 14" "Sector 21" "Sector 23" "Kudasan" "Infocity" "Adalaj" "Koba" "Vavol" "Sargasan"

# Maharashtra
insert_areas "Mumbai" "Andheri" "Bandra" "Dadar" "Borivali" "Thane" "Powai" "Malad" "Goregaon" "Kandivali" "Juhu" "Chembur" "Vashi" "Navi Mumbai" "Worli" "Lower Parel" "Colaba" "Churchgate" "Marine Lines" "Sion" "Mulund" "Ghatkopar" "Kurla" "Bhandup" "Mahim" "Santacruz" "Khar" "Versova" "Jogeshwari" "Vikhroli" "Nahur" "Dombivli" "Ambarnath" "Ulhasnagar" "Badlapur" "Airoli" "Ghansoli" "Kopar Khairane" "Turbhe" "CBD Belapur"
insert_areas "Pune" "Koregaon Park" "Kothrud" "Viman Nagar" "Hinjewadi" "Baner" "Aundh" "Kondhwa" "Magarpatta" "Hadapsar" "Shivaji Nagar" "Deccan" "Camp" "Kalyani Nagar" "Wakad" "Pimpri" "Chinchwad" "Katraj" "Ambegaon" "Warje" "Bibwewadi" "Swargate" "Yerawada" "Vishrantwadi" "Lohegaon" "Wagholi" "Nagar Road" "Undri" "Sus" "Balewadi" "Pashan" "Bavdhan" "Karve Nagar" "Erandwane" "Model Colony"
insert_areas "Nagpur" "Dharampeth" "Sitabuldi" "Manish Nagar" "Pratap Nagar" "Ramdaspeth" "Sadar" "Gandhibagh" "Wardha Road" "Koradi Road" "Amravati Road"

# Karnataka
insert_areas "Bangalore" "Koramangala" "Indiranagar" "Whitefield" "JP Nagar" "HSR Layout" "BTM Layout" "Malleshwaram" "Electronic City" "Marathahalli" "Bannerghatta Road" "Jayanagar" "Rajajinagar" "Yelahanka" "Hebbal" "Bellandur" "Sarjapur" "MG Road" "Basavanagudi" "Domlur" "Bommanahalli"

# Tamil Nadu
insert_areas "Chennai" "T Nagar" "Anna Nagar" "Adyar" "Velachery" "Nungambakkam" "Mylapore" "Kodambakkam" "Anna Salai" "Mount Road" "Royapettah" "Egmore" "Washermenpet" "Parrys" "Guindy" "Tambaram" "Pallavaram" "Perungudi" "Sholinganallur" "OMR" "Porur"
insert_areas "Coimbatore" "RS Puram" "Gandhipuram" "Peelamedu" "Saibaba Colony" "Singanallur" "Race Course" "Ukkadam" "Ganapathy" "Vadavalli" "Kuniyamuthur"

# Telangana
insert_areas "Hyderabad" "Banjara Hills" "Jubilee Hills" "Madhapur" "Kukatpally" "Secunderabad" "Gachibowli" "Begumpet" "Charminar" "Mehdipatnam" "Ameerpet" "Dilsukhnagar" "Lakdi Ka Pul" "Hitech City" "Miyapur" "LB Nagar" "Uppal" "Habsiguda" "Tarnaka" "Malkajgiri" "Sainikpuri"

# West Bengal
insert_areas "Kolkata" "Salt Lake" "Park Street" "New Town" "Ballygunge" "Garia" "Rajarhat" "Esplanade" "Dalhousie" "Alipore" "Behala" "Jadavpur" "Dum Dum" "Barasat" "Barrackpore" "Tollygunge" "Gariahat" "Kasba" "Dhakuria" "Santoshpur" "Anandapur"

# Delhi
insert_areas "New Delhi" "Connaught Place" "Karol Bagh" "Lajpat Nagar" "Rajouri Garden" "Dwarka" "Rohini" "Janakpuri" "Saket" "Vasant Kunj" "Chanakyapuri" "Mayur Vihar" "Shahdara" "Narela" "Pitampura" "Janpath" "India Gate" "Hauz Khas" "Greater Kailash" "Kalkaji" "Okhla"

# Rajasthan
insert_areas "Jaipur" "Malviya Nagar" "Vaishali Nagar" "C Scheme" "Raja Park" "Mansarovar" "Jhotwara" "Tonk Road" "Jagatpura" "Bapu Nagar" "Adarsh Nagar" "Shastri Nagar" "M.I. Road" "Bani Park" "Sanganer" "Murlipura"

# Uttar Pradesh
insert_areas "Lucknow" "Hazratganj" "Gomti Nagar" "Indira Nagar" "Aliganj" "Aminabad" "Chowk" "Alambagh" "Charbagh" "Mahanagar" "Jankipuram" "Aashiana" "Vikas Nagar" "Rajajipuram" "Kapoorthala" "Sitapur Road"

# Bihar
insert_areas "Patna" "Boring Road" "Kankarbagh" "Patliputra" "Raja Bazar" "Bailey Road" "Ashok Rajpath" "Gandhi Maidan" "Rajendra Nagar" "Saguna More" "Phulwarisharif"

# Madhya Pradesh
insert_areas "Indore" "Vijay Nagar" "Rajendra Nagar" "Sapna Sangeeta" "Geeta Bhawan" "Malhar Mega Mall" "Rau" "Palasia" "MG Road" "Tilak Nagar" "Sukhliya"
insert_areas "Bhopal" "Arera Colony" "Shahpura" "Kolar Road" "MP Nagar" "New Market" "Bairagarh" "Ayodhya Nagar" "Karond" "Shyamla Hills" "Nayapura"

# Uttarakhand
insert_areas "Dehradun" "Rajpur Road" "Chakrata Road" "Sahastradhara Road" "Clement Town" "Patel Nagar" "Karanpur" "Niranjanpur" "Raipur" "Balliwala Chowk" "GMS Road"

# Kerala
insert_areas "Thiruvananthapuram" "Kowdiar" "Palayam" "Statue" "Vellayambalam" "Pattom" "Karamana" "Killipalam" "Kesavadasapuram" "Bakery Junction" "MG Road"
insert_areas "Kochi" "Ernakulam" "Fort Kochi" "Kakkanad" "Edappally" "Aluva" "Tripunithura" "Thrippunithura" "Maradu" "Kalamassery" "Perumbavoor"

# Odisha
insert_areas "Bhubaneswar" "Jaydev Vihar" "Sahid Nagar" "Patia" "Khandagiri" "Old Town" "Nayapalli" "Vani Vihar" "VSS Nagar" "IRC Village" "Bhoi Nagar"

# Assam
insert_areas "Guwahati" "Dispur" "Paltan Bazar" "Fancy Bazar" "Ganeshguri" "Six Mile" "Zoo Road" "Bhangagarh" "Silpukhuri" "Ulubari" "Lachit Nagar"

# Chhattisgarh
insert_areas "Raipur" "Devendra Nagar" "Pandri" "Telibandha" "Shankar Nagar" "Avanti Vihar" "Kankali Para" "Sunder Nagar" "Mowa" "Tatiband" "Fafadih"

# Jharkhand
insert_areas "Ranchi" "Lalpur" "Doranda" "Hinoo" "Kokar" "Argora" "Booty More" "Harmu" "Ashok Nagar" "Bariatu" "Kantatoli"

# Himachal Pradesh
insert_areas "Shimla" "The Mall" "Lakkar Bazar" "Kasumpti" "New Shimla" "Chhota Shimla" "Boileauganj" "Vikas Nagar" "Panthaghati" "Mehli" "Dhalli"

# Goa
insert_areas "Panaji" "Campal" "Fontainhas" "Miramar" "Caranzalem" "Altinho" "Dona Paula" "Taleigao"

# Sikkim
insert_areas "Gangtok" "MG Marg" "Tibet Road" "Tadong" "Ranipool" "Deorali"

# Tripura
insert_areas "Agartala" "VIP Road" "Krishnanagar" "Battala" "Ramnagar" "Motor Stand" "Dhaleswar"

# Manipur
insert_areas "Imphal" "Thangal Bazar" "Paona Bazar" "Kwakeithel" "Singjamei" "Chingmeirong" "Keishampat" "Lamphelpat"

# Meghalaya
insert_areas "Shillong" "Police Bazar" "Laitumkhrah" "Nongthymmai" "Mawkhar" "Riatsamthiah" "New Colony" "Lachumiere"

# Mizoram
insert_areas "Aizawl" "Chanmari" "Zarkawt" "Ramthar" "Bawngkawn" "Dawrpui" "Tuikual" "Mission Veng"

# Nagaland
insert_areas "Kohima" "Kohima Village" "Upper Shiloi" "Lower Shiloi" "Meriema" "Tsiminyu"
insert_areas "Dimapur" "Circular Road" "Purana Bazar" "New Market" "Naga Bazaar" "Chumukedima"

echo ""
echo "Database created successfully!"
echo "File: $DB_PATH"

# Print stats
STATES=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM states;")
CITIES=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM cities;")
AREAS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM areas;")
SIZE=$(ls -la "$DB_PATH" | awk '{print $5}')

echo "  States: $STATES"
echo "  Cities: $CITIES"
echo "  Areas:  $AREAS"
echo "  Size:   $SIZE bytes"
