import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/instance.dart';
import '../viewmodels/class_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';

class CourseInstancesScreen extends StatefulWidget {
  final Course course;

  const CourseInstancesScreen({super.key, required this.course});

  @override
  _CourseInstancesScreenState createState() => _CourseInstancesScreenState();
}

class _CourseInstancesScreenState extends State<CourseInstancesScreen> {
  final ClassViewModel _viewModel = ClassViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.name)),
      body: Column(
        children: [
          // Course Information Card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Type: ${widget.course.type}'),
                  Text('Day: ${widget.course.dayOfWeek}'),
                  Text('Time: ${widget.course.time}'),
                  Text('Duration: ${widget.course.duration} minutes'),
                  Text('Capacity: ${widget.course.capacity} people'),
                  Text('Price: £${widget.course.price}'),
                  if (widget.course.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.course.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Available Classes Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Available Classes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Instance>>(
              stream: _viewModel.getInstancesByCourse(widget.course.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading classes'));
                }
                final instances = snapshot.data ?? [];
                if (instances.isEmpty) {
                  return const Center(
                    child: Text('No classes available for this course'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: instances.length,
                  itemBuilder: (context, index) {
                    final instance = instances[index];
                    return Card(
                      child: ListTile(
                        title: Text('${instance.name} - ${instance.teacher}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${instance.date}'),
                            Text('Time: ${widget.course.time}'),
                            if (instance.comments != null)
                              Text('Note: ${instance.comments}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            Provider.of<CartViewModel>(
                              context,
                              listen: false,
                            ).addToCart(instance);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${instance.name} added to cart'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
