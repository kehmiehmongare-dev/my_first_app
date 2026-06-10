// Student Model
class Student {
  final String regNumber;
  final String name;
  final String email;
  final String phone;
  final String course;
  final int semester;
  final String password;
  final DateTime registrationDate;
  String? profileImage;
  String? parentName;
  String? parentPhone;

  Student({
    required this.regNumber,
    required this.name,
    required this.email,
    required this.phone,
    required this.course,
    required this.semester,
    required this.password,
    required this.registrationDate,
    this.profileImage,
    this.parentName,
    this.parentPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'regNumber': regNumber,
      'name': name,
      'email': email,
      'phone': phone,
      'course': course,
      'semester': semester,
      'password': password,
      'registrationDate': registrationDate.toIso8601String(),
      'profileImage': profileImage,
      'parentName': parentName,
      'parentPhone': parentPhone,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      regNumber: json['regNumber'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      course: json['course'],
      semester: json['semester'],
      password: json['password'],
      registrationDate: DateTime.parse(json['registrationDate']),
      profileImage: json['profileImage'],
      parentName: json['parentName'],
      parentPhone: json['parentPhone'],
    );
  }
}
