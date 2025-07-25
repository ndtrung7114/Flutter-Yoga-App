class Booking {
  final String id;
  final String userId;
  final String userEmail;
  final int instanceId;
  final int courseId;
  final String courseName;
  final String className; // Name of the specific class instance
  final String date; // Date when the class takes place
  final String time;
  final String teacher;
  final DateTime bookedAt; // Date when the user made the booking

  Booking({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.instanceId,
    required this.courseId,
    required this.courseName,
    required this.className,
    required this.date,
    required this.time,
    required this.teacher,
    required this.bookedAt,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      instanceId: (data['instanceId'] as num?)?.toInt() ?? 0,
      courseId: (data['courseId'] as num?)?.toInt() ?? 0,
      courseName: data['courseName'] ?? '',
      className: data['className'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      teacher: data['teacher'] ?? '',
      bookedAt: data['bookedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['bookedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'instanceId': instanceId,
      'courseId': courseId,
      'courseName': courseName,
      'className': className,
      'date': date,
      'time': time,
      'teacher': teacher,
      'bookedAt': bookedAt.millisecondsSinceEpoch,
    };
  }
}
