enum UserType {
  student,
  lecturer,
}

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserType type;
  final String? course; // For students only
  final String? department; // For lecturers only
  final String? employeeId; // For lecturers only
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.type,
    this.course,
    this.department,
    this.employeeId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'type': type.name,
      'course': course,
      'department': department,
      'employeeId': employeeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      type: UserType.values.firstWhere((e) => e.name == json['type']),
      course: json['course'],
      department: json['department'],
      employeeId: json['employeeId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
