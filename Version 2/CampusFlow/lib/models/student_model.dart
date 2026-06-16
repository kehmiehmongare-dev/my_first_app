class Student {
  final String id;
  final String userId;
  final String regNumber;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String course;
  final int yearOfStudy;
  final int semester;
  final String batch;
  final String enrollmentDate;
  final String status;
  final double currentGPA;
  final double cumulativeGPA;
  final String password;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final String expiryDate;

  Student({
    required this.id,
    required this.userId,
    required this.regNumber,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.course,
    required this.yearOfStudy,
    required this.semester,
    required this.batch,
    required this.enrollmentDate,
    required this.status,
    required this.currentGPA,
    required this.cumulativeGPA,
    required this.password,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    required this.expiryDate,
  });

  String get fullName =>
      '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'regNumber': regNumber,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'course': course,
        'yearOfStudy': yearOfStudy,
        'semester': semester,
        'batch': batch,
        'enrollmentDate': enrollmentDate,
        'status': status,
        'currentGPA': currentGPA,
        'cumulativeGPA': cumulativeGPA,
        'password': password,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin.toIso8601String(),
        'isActive': isActive,
        'expiryDate': expiryDate,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        userId: json['userId'],
        regNumber: json['regNumber'],
        firstName: json['firstName'],
        middleName: json['middleName'] ?? '',
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        course: json['course'],
        yearOfStudy: json['yearOfStudy'],
        semester: json['semester'],
        batch: json['batch'],
        enrollmentDate: json['enrollmentDate'],
        status: json['status'],
        currentGPA: (json['currentGPA'] ?? 0.0).toDouble(),
        cumulativeGPA: (json['cumulativeGPA'] ?? 0.0).toDouble(),
        password: json['password'],
        createdAt: DateTime.parse(json['createdAt']),
        lastLogin: DateTime.parse(json['lastLogin']),
        isActive: json['isActive'],
        expiryDate: json['expiryDate'],
      );
}
