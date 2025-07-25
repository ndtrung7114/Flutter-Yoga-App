import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../models/course.dart';
import '../viewmodels/bookings_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/class_viewmodel.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  String _formatBookingDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    if (authViewModel.user == null) {
      return const Center(child: Text('Please sign in to view bookings'));
    }

    final viewModel = BookingsViewModel();
    final classViewModel = ClassViewModel();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<List<Booking>>(
        stream: viewModel.getBookings(authViewModel.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading bookings'));
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          return FutureBuilder<List<Course>>(
            future: classViewModel.getCourses(),
            builder: (context, courseSnapshot) {
              if (courseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (courseSnapshot.hasError) {
                return const Center(
                  child: Text('Error loading course details'),
                );
              }
              final courses = courseSnapshot.data ?? [];

              // Group bookings by course
              final groupedBookings = <int, List<Booking>>{};
              for (var booking in bookings) {
                if (!groupedBookings.containsKey(booking.courseId)) {
                  groupedBookings[booking.courseId] = [];
                }
                groupedBookings[booking.courseId]!.add(booking);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: groupedBookings.length,
                itemBuilder: (context, index) {
                  final courseId = groupedBookings.keys.elementAt(index);
                  final courseBookings = groupedBookings[courseId]!;
                  final course = courses.firstWhere(
                    (c) => c.id == courseId,
                    orElse: () => Course(
                      id: courseId,
                      dayOfWeek: '',
                      time: '',
                      capacity: 0,
                      duration: 0,
                      price: 0.0,
                      type: '',
                      name: 'Unknown Course',
                    ),
                  );

                  // If there's only one booking for this course, display it normally
                  if (courseBookings.length == 1) {
                    final booking = courseBookings.first;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            course.name.isNotEmpty
                                ? course.name[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          booking.className,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📚 Course: ${booking.courseName}'),
                            Text('👨‍🏫 Teacher: ${booking.teacher}'),
                            Text('📅 Class Date: ${booking.date}'),
                            Text('🕐 Time: ${booking.time}'),
                            Text('💰 Price: £${course.price}'),
                            Text('⏱️ Duration: ${course.duration} minutes'),
                            Text('📍 Type: ${course.type}'),
                            Text(
                              '🎯 Booked: ${_formatBookingDate(booking.bookedAt)}',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }

                  // If there are multiple bookings for this course, group them
                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          courseBookings.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        course.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${courseBookings.length} classes booked'),
                          Text(
                            '💰 £${course.price} per class | ⏱️ ${course.duration} min',
                          ),
                          Text('📍 ${course.type}'),
                        ],
                      ),
                      children: courseBookings.map((booking) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Card(
                            color: Theme.of(context).cardColor.withOpacity(0.5),
                            child: ListTile(
                              title: Text(
                                booking.className,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('👨‍🏫 Teacher: ${booking.teacher}'),
                                  Text('📅 Class Date: ${booking.date}'),
                                  Text('🕐 Time: ${booking.time}'),
                                  Text(
                                    '🎯 Booked: ${_formatBookingDate(booking.bookedAt)}',
                                  ),
                                ],
                              ),
                              dense: true,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
