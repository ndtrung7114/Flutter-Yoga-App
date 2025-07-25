import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingsViewModel {
  Stream<List<Booking>> getBookings(String userId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}