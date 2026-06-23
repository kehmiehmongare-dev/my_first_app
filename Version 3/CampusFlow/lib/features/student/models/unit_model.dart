class Unit {
  final String id;
  final String code;
  final String name;
  final int credits;
  final String? instructor;
  final String? schedule;
  final String? room;

  Unit({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    this.instructor,
    this.schedule,
    this.room,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'credits': credits,
        'instructor': instructor,
        'schedule': schedule,
        'room': room,
      };

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: json['id'],
        code: json['code'],
        name: json['name'],
        credits: json['credits'],
        instructor: json['instructor'],
        schedule: json['schedule'],
        room: json['room'],
      );
}
