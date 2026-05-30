/// Model representing an area/locality from the SQLite database.
class AreaModel {
  final int id;
  final String name;
  final int cityId;
  final double? latitude;
  final double? longitude;

  const AreaModel({
    required this.id,
    required this.name,
    required this.cityId,
    this.latitude,
    this.longitude,
  });

  factory AreaModel.fromMap(Map<String, dynamic> map) {
    return AreaModel(
      id: map['id'] as int,
      name: map['name'] as String,
      cityId: map['city_id'] as int,
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city_id': cityId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() =>
      'AreaModel(id: $id, name: $name, cityId: $cityId, lat: $latitude, lng: $longitude)';
}
