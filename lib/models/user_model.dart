class User {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String nik;
  final String employmentStart;
  final String dept;
  final String role;
  final String pictureUrl;
  final List<HakAkses> hakakses;

  User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.nik,
    required this.employmentStart,
    required this.dept,
    required this.role,
    required this.pictureUrl,
    required this.hakakses,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Note: API only returns name and email currently.
    // Other fields will be dummy data for now as per requirements.
    var hakaksesList = <HakAkses>[];
    if (json['hakakses'] != null && json['hakakses'] is List) {
      json['hakakses'].forEach((v) {
        if (v != null && v is Map<String, dynamic>) {
          hakaksesList.add(HakAkses.fromJson(v));
        }
      });
    }

    return User(
      id: json['id']?.toString() ?? '0',
      employeeId: json['employee_id']?.toString() ?? '47', // Fallback for dev/testing
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      nik: '12345678', // Dummy
      employmentStart: '01 Jan 2020', // Dummy
      dept: 'IT Department', // Dummy
      role: 'Frontend Developer', // Dummy
      pictureUrl: 'https://via.placeholder.com/150', // Dummy
      hakakses: hakaksesList,
    );
  }
}

class HakAkses {
  final int userId;
  final int deptId;
  final int level;

  HakAkses({
    required this.userId,
    required this.deptId,
    required this.level,
  });

  factory HakAkses.fromJson(Map<String, dynamic> json) {
    return HakAkses(
      userId: _toInt(json['UserId']),
      deptId: _toInt(json['DeptId']),
      level: _toInt(json['level']),
    );
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
}
