class Course {
  final String id;
  final String code;
  final String name;
  final int credits;
  final String department;
  final String lecturerId;
  final String lecturerName;
  final int capacity;
  final int enrolled;
  final List<String> prerequisites;
  final String schedule;
  final String room;
  final String semester;
  final int year;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.department,
    required this.lecturerId,
    required this.lecturerName,
    required this.capacity,
    required this.enrolled,
    required this.prerequisites,
    required this.schedule,
    required this.room,
    required this.semester,
    required this.year,
  });

  bool get isAvailable => enrolled < capacity;
  int get availableSeats => capacity - enrolled;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'credits': credits,
    'department': department,
    'lecturerId': lecturerId,
    'lecturerName': lecturerName,
    'capacity': capacity,
    'enrolled': enrolled,
    'prerequisites': prerequisites,
    'schedule': schedule,
    'room': room,
    'semester': semester,
    'year': year,
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'],
    code: json['code'],
    name: json['name'],
    credits: json['credits'],
    department: json['department'],
    lecturerId: json['lecturerId'],
    lecturerName: json['lecturerName'],
    capacity: json['capacity'],
    enrolled: json['enrolled'],
    prerequisites: List<String>.from(json['prerequisites']),
    schedule: json['schedule'],
    room: json['room'],
    semester: json['semester'],
    year: json['year'],
  );
}