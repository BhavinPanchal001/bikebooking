class GeoNamesConfig {
  // Your GeoNames username
  // Account: https://www.geonames.org/login
  static const String username = 'bhavinpanchal';
  
  // API endpoints
  static const String baseUrl = 'http://api.geonames.org';
  
  // Cache keys
  static const String statesCacheKey = 'cached_states';
  static const String citiesCacheKeyPrefix = 'cached_cities_';
  static const String areasCacheKeyPrefix = 'cached_areas_';
  
  // Rate limiting
  static const int hourlyLimit = 1000;
  static const int dailyLimit = 10000;
}
