class Lecturer {
  final String id;
  final String employeeId;
  final String fullName;
  final String email;
  final String department;
  final String designation;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;
  final String? temporaryPassword;

  Lecturer({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.department,
    this.designation = 'Lecturer',
    this.phone,
    this.isActive = true,
    required this.createdAt,
    this.temporaryPassword,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'displayName': fullName,
        'email': email,
        'department': department,
        'designation': designation,
        'phone': phone,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'temporaryPassword': temporaryPassword,
      };

  factory Lecturer.fromJson(Map<String, dynamic> json) => Lecturer(
        id: json['id'] ?? '',
        employeeId: json['employeeId'] ?? '',
        fullName: json['displayName'] ?? '',
        email: json['email'] ?? '',
        department: json['department'] ?? '',
        designation: json['designation'] ?? 'Lecturer',
        phone: json['phone'],
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        temporaryPassword: json['temporaryPassword'],
      );
}
