/// Model representing a city from the SQLite database.
class CityModel {
  final int id;
  final String name;
  final int stateId;

  const CityModel({
    required this.id,
    required this.name,
    required this.stateId,
  });

  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: map['id'] as int,
      name: map['name'] as String,
      stateId: map['state_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'state_id': stateId,
    };
  }

  @override
  String toString() => 'CityModel(id: $id, name: $name, stateId: $stateId)';
}
