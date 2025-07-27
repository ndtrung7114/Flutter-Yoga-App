import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/instance.dart';

class ClassViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Course> _courses = [];
  List<Instance> _instances = [];

  Stream<List<Instance>> getInstances(String dayQuery, String timeQuery) {
    return _firestore.collection('instances').snapshots().map((snapshot) {
      _instances = snapshot.docs
          .map((doc) => Instance.fromFirestore(doc.data(), doc.id))
          .where(
            (instance) =>
                (dayQuery.isEmpty ||
                    instance.date.toLowerCase().contains(
                      dayQuery.toLowerCase(),
                    )) &&
                (timeQuery.isEmpty ||
                    instance.date.toLowerCase().contains(
                      timeQuery.toLowerCase(),
                    )),
          )
          .toList();
      return _instances;
    });
  }

  // Enhanced search method for instances with multiple criteria
  Stream<List<Instance>> searchInstances({
    String nameQuery = '',
    String teacherQuery = '',
    String dateQuery = '',
    String timeQuery = '',
  }) {
    return _firestore.collection('instances').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Instance.fromFirestore(doc.data(), doc.id))
          .where((instance) {
            final matchesName =
                nameQuery.isEmpty ||
                instance.name.toLowerCase().contains(nameQuery.toLowerCase());

            final matchesTeacher =
                teacherQuery.isEmpty ||
                instance.teacher.toLowerCase().contains(
                  teacherQuery.toLowerCase(),
                );

            final matchesDate =
                dateQuery.isEmpty ||
                instance.date.toLowerCase().contains(dateQuery.toLowerCase());

            final matchesTime =
                timeQuery.isEmpty ||
                instance.date.toLowerCase().contains(timeQuery.toLowerCase());

            return matchesName && matchesTeacher && matchesDate && matchesTime;
          })
          .toList();
    });
  }

  Stream<List<Instance>> getInstancesByCourse(int courseId) {
    return _firestore
        .collection('instances')
        .where('course_id', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Instance.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Course>> getCoursesStream() {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      _courses = snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
      return _courses;
    });
  }

  Future<List<Course>> getCourses() async {
    if (_courses.isEmpty) {
      final snapshot = await _firestore.collection('courses').get();
      _courses = snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    }
    return _courses;
  }

  Course getCourseById(int courseId) {
    return _courses.firstWhere(
      (course) => course.id == courseId,
      orElse: () => Course(
        id: 0,
        dayOfWeek: '',
        time: '',
        capacity: 0,
        duration: 0,
        price: 0.0,
        type: '',
        name: 'Unknown',
      ),
    );
  }
}
