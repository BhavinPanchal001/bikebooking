/// Model representing a state from the SQLite database.
class StateModel {
  final int id;
  final String name;

  const StateModel({
    required this.id,
    required this.name,
  });

  factory StateModel.fromMap(Map<String, dynamic> map) {
    return StateModel(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'StateModel(id: $id, name: $name)';
}
