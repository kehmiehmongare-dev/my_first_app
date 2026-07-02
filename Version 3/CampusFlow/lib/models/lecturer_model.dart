class Lecturer {
  final String id;
  final String userId;
  final String employeeId;
  final String department;
  final String designation;
  final List<String> courses;

  Lecturer({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.courses,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'employeeId': employeeId,
        'department': department,
        'designation': designation,
        'courses': courses,
      };

  factory Lecturer.fromJson(Map<String, dynamic> json) => Lecturer(
        id: json['id'],
        userId: json['userId'],
        employeeId: json['employeeId'],
        department: json['department'],
        designation: json['designation'],
        courses: List<String>.from(json['courses']),
      );
}
