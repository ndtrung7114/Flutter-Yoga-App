class Instance {
  final int id;
  final int courseId;
  final String name;
  final String date;
  final String teacher;
  final String? comments;

  Instance({
    required this.id,
    required this.courseId,
    required this.name,
    required this.date,
    required this.teacher,
    this.comments,
  });

  factory Instance.fromFirestore(Map<String, dynamic> data, String id) {
    return Instance(
      id: int.parse(id),
      courseId: (data['course_id'] as num?)?.toInt() ?? 0,
      name: data['name'] ?? '',
      date: data['date'] ?? '',
      teacher: data['teacher'] ?? '',
      comments: data['comments'],
    );
  }
}