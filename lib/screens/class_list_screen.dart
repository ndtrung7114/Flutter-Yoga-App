import 'package:flutter/material.dart';
import '../models/course.dart';
import '../viewmodels/class_viewmodel.dart';
import 'course_instances_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  _ClassListScreenState createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final ClassViewModel _viewModel = ClassViewModel();
  String _selectedCourseType = 'All'; // Filter state

  @override
  void dispose() {
    super.dispose();
  }

  // Helper method to assign colors to different course types
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Section
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Search replacement notice
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search for Class Instances',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use the search icon in the top bar to find specific class instances by date, time, teacher, or name.',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.search, color: Colors.blue[700]),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Filter Row
              Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter by type:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<List<Course>>(
                      stream: _viewModel.getCoursesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final courses = snapshot.data!;
                          // Get unique course types
                          final courseTypes = courses
                              .map((course) => course.type)
                              .where((type) => type.isNotEmpty)
                              .toSet()
                              .toList();
                          courseTypes.sort();
                          final allTypes = ['All', ...courseTypes];

                          return DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCourseType,
                            items: allTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Row(
                                  children: [
                                    if (type != 'All') ...[
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundColor: _getCourseTypeColor(
                                          type,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(type),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCourseType = newValue ?? 'All';
                              });
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
              // Active filters display
              if (_selectedCourseType != 'All')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_selectedCourseType != 'All')
                        Chip(
                          avatar: CircleAvatar(
                            radius: 8,
                            backgroundColor: _getCourseTypeColor(
                              _selectedCourseType,
                            ),
                          ),
                          label: Text('Type: $_selectedCourseType'),
                          onDeleted: () {
                            setState(() {
                              _selectedCourseType = 'All';
                            });
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Course>>(
            stream: _viewModel.getCoursesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading courses'));
              }
              final courses = snapshot.data ?? [];

              // Filter courses based on type filter only
              final filteredCourses = courses.where((course) {
                final matchesType =
                    _selectedCourseType == 'All' ||
                    course.type == _selectedCourseType;

                return matchesType;
              }).toList();

              if (filteredCourses.isEmpty) {
                final hasFilter = _selectedCourseType != 'All';
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasFilter ? Icons.filter_list_off : Icons.class_,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasFilter
                            ? 'No courses match your filter'
                            : 'No courses found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      if (hasFilter) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCourseType = 'All';
                            });
                          },
                          child: const Text('Clear Filter'),
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
                      '${filteredCourses.length} course${filteredCourses.length != 1 ? 's' : ''} found'
                      '${_selectedCourseType != 'All' ? ' • Type: $_selectedCourseType' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getCourseTypeColor(course.type),
                              child: Text(
                                course.type.isNotEmpty
                                    ? course.type[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              course.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                    course.type,
                                    style: TextStyle(
                                      color: _getCourseTypeColor(course.type),
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
                                    Text(
                                      '${course.dayOfWeek} at ${course.time}',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
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
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourseInstancesScreen(course: course),
                                ),
                              );
                            },
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
    );
  }
}
