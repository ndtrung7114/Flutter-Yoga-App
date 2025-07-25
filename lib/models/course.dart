class Course {
  final int id;
  final String dayOfWeek;
  final String time;
  final int capacity;
  final int duration;
  final double price;
  final String type;
  final String? description;
  final String name;
  final String? photoUrl;

  Course({
    required this.id,
    required this.dayOfWeek,
    required this.time,
    required this.capacity,
    required this.duration,
    required this.price,
    required this.type,
    this.description,
    required this.name,
    this.photoUrl,
  });

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    return Course(
      id: int.parse(id),
      dayOfWeek: data['day_of_week'] ?? '',
      time: data['time'] ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      type: data['type'] ?? '',
      description: data['description'],
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }
}