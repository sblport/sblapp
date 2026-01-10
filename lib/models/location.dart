class Location {
  final int id;
  final String name;

  Location({
    required this.id,
    required this.name,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
