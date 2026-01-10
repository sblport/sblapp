class Organization {
  final int id;
  final String name;
  final String chartname;

  Organization({
    required this.id,
    required this.name,
    required this.chartname,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String,
      chartname: json['chartname'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chartname': chartname,
    };
  }
}
