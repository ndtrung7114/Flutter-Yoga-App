import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/instance.dart';
import '../models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartViewModel with ChangeNotifier {
  final List<Instance> _cartItems = [];
  final Map<int, bool> _selectedItems = {}; // instanceId -> isSelected

  List<Instance> get cartItems => _cartItems;
  Map<int, bool> get selectedItems => _selectedItems;

  void addToCart(Instance instance) {
    if (!_cartItems.any((item) => item.id == instance.id)) {
      _cartItems.add(instance);
      _selectedItems[instance.id] = true; // Default to selected
      notifyListeners();
    }
  }

  void removeFromCart(Instance instance) {
    _cartItems.removeWhere((item) => item.id == instance.id);
    _selectedItems.remove(instance.id);
    notifyListeners();
  }

  void toggleSelection(int instanceId) {
    _selectedItems[instanceId] = !(_selectedItems[instanceId] ?? false);
    notifyListeners();
  }

  bool isSelected(int instanceId) {
    return _selectedItems[instanceId] ?? false;
  }

  List<Instance> get selectedCartItems {
    return _cartItems.where((item) => isSelected(item.id)).toList();
  }

  void clearCart() {
    _cartItems.clear();
    _selectedItems.clear();
    notifyListeners();
  }

  Future<bool> submitSelectedItems(User user, List<Course> courses) async {
    final selectedItems = selectedCartItems;
    if (selectedItems.isEmpty) return false;

    try {
      for (var instance in selectedItems) {
        final course = courses.firstWhere(
          (c) => c.id == instance.courseId,
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
        final booking = Booking(
          id: FirebaseFirestore.instance.collection('bookings').doc().id,
          userId: user.uid,
          userEmail: user.email ?? 'anonymous@example.com',
          instanceId: instance.id,
          courseId: instance.courseId,
          courseName: course.name,
          className: instance.name,
          date: instance.date,
          time: course.time,
          teacher: instance.teacher,
          bookedAt: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .set(booking.toFirestore());
      }

      // Remove submitted items from cart
      for (var instance in selectedItems) {
        removeFromCart(instance);
      }

      return true;
    } catch (e) {
      debugPrint('Error submitting cart: $e');
      return false;
    }
  }

  // Legacy method for compatibility
  Future<bool> submitCart(User user, List<Course> courses) async {
    return submitSelectedItems(user, courses);
  }
}
