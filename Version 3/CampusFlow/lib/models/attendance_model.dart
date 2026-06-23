class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseCode;
  final DateTime date;
  final String status; // present, absent, late, excused
  final String? lecturerId;
  final String? note;
  final DateTime? checkInTime;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseCode,
    required this.date,
    required this.status,
    this.lecturerId,
    this.note,
    this.checkInTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'courseId': courseId,
        'courseCode': courseCode,
        'date': date.toIso8601String(),
        'status': status,
        'lecturerId': lecturerId,
        'note': note,
        'checkInTime': checkInTime?.toIso8601String(),
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        courseId: json['courseId'],
        courseCode: json['courseCode'],
        date: DateTime.parse(json['date']),
        status: json['status'],
        lecturerId: json['lecturerId'],
        note: json['note'],
        checkInTime: json['checkInTime'] != null
            ? DateTime.parse(json['checkInTime'])
            : null,
      );
}

class AttendanceStats {
  final int totalClasses;
  final int attended;
  final int absent;
  final int late;
  final int excused;
  final double percentage;
  final int classesRemaining;
  final int classesNeededToQualify;
  final String status;

  AttendanceStats({
    required this.totalClasses,
    required this.attended,
    required this.absent,
    required this.late,
    required this.excused,
    required this.percentage,
    required this.classesRemaining,
    required this.classesNeededToQualify,
    required this.status,
  });

  bool get isQualified => percentage >= 75;
  bool get isAtRisk => percentage >= 60 && percentage < 75;
  bool get isCritical => percentage < 60;
}
