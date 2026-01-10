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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Note: API only returns name and email currently.
    // Other fields will be dummy data for now as per requirements.
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
    );
  }
}
