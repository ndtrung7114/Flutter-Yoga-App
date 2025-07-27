import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/instance.dart';
import '../models/course.dart';
import '../viewmodels/class_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';

class InstanceSearchScreen extends StatefulWidget {
  const InstanceSearchScreen({super.key});

  @override
  _InstanceSearchScreenState createState() => _InstanceSearchScreenState();
}

class _InstanceSearchScreenState extends State<InstanceSearchScreen> {
  final ClassViewModel _viewModel = ClassViewModel();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _dayController.dispose();
    _timeController.dispose();
    _teacherController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    _courses = await _viewModel.getCourses();
    setState(() {});
  }

  Color _getCourseTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hatha':
        return Colors.green;
      case 'vinyasa':
        return Colors.blue;
      case 'ashtanga':
        return Colors.orange;
      case 'yin':
        return Colors.purple;
      case 'restorative':
        return Colors.teal;
      case 'hot':
        return Colors.red;
      case 'prenatal':
        return Colors.pink;
      case 'power':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Course? _getCourseById(int courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Class Instances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _dayController.clear();
                _timeController.clear();
                _teacherController.clear();
                _nameController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Filters Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Instance Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                          hintText: 'e.g., Morning Flow',
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _teacherController,
                        decoration: const InputDecoration(
                          labelText: 'Teacher',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'e.g., Sarah',
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dayController,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: 'e.g., 2025-01-15',
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                          hintText: 'e.g., 09:00',
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Active filters display
          if (_hasActiveFilters())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_nameController.text.isNotEmpty)
                    Chip(
                      label: Text('Name: "${_nameController.text}"'),
                      onDeleted: () {
                        setState(() {
                          _nameController.clear();
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_teacherController.text.isNotEmpty)
                    Chip(
                      label: Text('Teacher: "${_teacherController.text}"'),
                      onDeleted: () {
                        setState(() {
                          _teacherController.clear();
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_dayController.text.isNotEmpty)
                    Chip(
                      label: Text('Date: "${_dayController.text}"'),
                      onDeleted: () {
                        setState(() {
                          _dayController.clear();
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_timeController.text.isNotEmpty)
                    Chip(
                      label: Text('Time: "${_timeController.text}"'),
                      onDeleted: () {
                        setState(() {
                          _timeController.clear();
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                ],
              ),
            ),
          const Divider(),
          // Results Section
          Expanded(
            child: StreamBuilder<List<Instance>>(
              stream: _viewModel.searchInstances(
                nameQuery: _nameController.text,
                teacherQuery: _teacherController.text,
                dateQuery: _dayController.text,
                timeQuery: _timeController.text,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading instances'));
                }

                final filteredInstances = snapshot.data ?? [];

                if (filteredInstances.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasActiveFilters()
                              ? Icons.search_off
                              : Icons.event_note,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasActiveFilters()
                              ? 'No class instances match your search'
                              : 'Enter search criteria to find class instances',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_hasActiveFilters()) ...[
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _dayController.clear();
                                _timeController.clear();
                                _teacherController.clear();
                                _nameController.clear();
                              });
                            },
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Results summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey[100],
                      child: Text(
                        '${filteredInstances.length} class instance${filteredInstances.length != 1 ? 's' : ''} found',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredInstances.length,
                        itemBuilder: (context, index) {
                          final instance = filteredInstances[index];
                          final course = _getCourseById(instance.courseId);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: course != null
                                    ? _getCourseTypeColor(course.type)
                                    : Colors.grey,
                                child: Text(
                                  course?.type.isNotEmpty == true
                                      ? course!.type[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                instance.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('👨‍🏫 Teacher: ${instance.teacher}'),
                                  Text('📅 Date: ${instance.date}'),
                                  if (course != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCourseTypeColor(
                                          course.type,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getCourseTypeColor(
                                            course.type,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        'Course: ${course.name}',
                                        style: TextStyle(
                                          color: _getCourseTypeColor(
                                            course.type,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${course.time}'),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.timer,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${course.duration} min'),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        Text('£${course.price}'),
                                      ],
                                    ),
                                  ],
                                  if (instance.comments != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '💬 ${instance.comments}',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Provider.of<CartViewModel>(
                                    context,
                                    listen: false,
                                  ).addToCart(instance);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${instance.name} added to cart',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _dayController.text.isNotEmpty ||
        _timeController.text.isNotEmpty ||
        _teacherController.text.isNotEmpty ||
        _nameController.text.isNotEmpty;
  }
}
