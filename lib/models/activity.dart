class Activity {
  final int id;
  final String name;

  Activity({
    required this.id,
    required this.name,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
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
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
