enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseCode;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final String? location;
  final String? markedBy;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseCode,
    required this.date,
    required this.status,
    this.checkInTime,
    this.location,
    this.markedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'courseId': courseId,
        'courseCode': courseCode,
        'date': date.toIso8601String(),
        'status': status.name,
        'checkInTime': checkInTime?.toIso8601String(),
        'location': location,
        'markedBy': markedBy,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        courseId: json['courseId'],
        courseCode: json['courseCode'],
        date: DateTime.parse(json['date']),
        status:
            AttendanceStatus.values.firstWhere((e) => e.name == json['status']),
        checkInTime: json['checkInTime'] != null
            ? DateTime.parse(json['checkInTime'])
            : null,
        location: json['location'],
        markedBy: json['markedBy'],
      );
}
