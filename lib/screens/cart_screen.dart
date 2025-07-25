import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/instance.dart';
import '../viewmodels/class_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartViewModel = Provider.of<CartViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final classViewModel = ClassViewModel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cartViewModel.cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                final hasSelected = cartViewModel.cartItems.any(
                  (item) => cartViewModel.isSelected(item.id),
                );
                for (var item in cartViewModel.cartItems) {
                  if (hasSelected) {
                    cartViewModel.toggleSelection(item.id);
                  } else {
                    if (!cartViewModel.isSelected(item.id)) {
                      cartViewModel.toggleSelection(item.id);
                    }
                  }
                }
              },
              child: Text(
                cartViewModel.cartItems.any(
                      (item) => cartViewModel.isSelected(item.id),
                    )
                    ? 'Deselect All'
                    : 'Select All',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: cartViewModel.cartItems.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Course>>(
                    future: classViewModel.getCourses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading courses'),
                        );
                      }
                      final courses = snapshot.data!;

                      // Group cart items by course
                      final groupedItems = <int, List<Instance>>{};
                      for (var instance in cartViewModel.cartItems) {
                        if (!groupedItems.containsKey(instance.courseId)) {
                          groupedItems[instance.courseId] = [];
                        }
                        groupedItems[instance.courseId]!.add(instance);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: groupedItems.length,
                        itemBuilder: (context, index) {
                          final courseId = groupedItems.keys.elementAt(index);
                          final instances = groupedItems[courseId]!;
                          final course = courses.firstWhere(
                            (c) => c.id == courseId,
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

                          return Card(
                            child: ExpansionTile(
                              title: Text(
                                course.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${instances.length} class(es) | £${course.price} each',
                              ),
                              children: instances.map((instance) {
                                return CheckboxListTile(
                                  title: Text(
                                    instance.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '👨‍🏫 Teacher: ${instance.teacher}',
                                      ),
                                      Text('📅 Class Date: ${instance.date}'),
                                      Text('🕐 Time: ${course.time}'),
                                      Text('💰 Price: £${course.price}'),
                                      if (instance.comments != null)
                                        Text('📝 Note: ${instance.comments}'),
                                    ],
                                  ),
                                  value: cartViewModel.isSelected(instance.id),
                                  onChanged: (bool? value) {
                                    cartViewModel.toggleSelection(instance.id);
                                  },
                                  secondary: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      cartViewModel.removeFromCart(instance);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${instance.name} removed from cart',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Consumer<CartViewModel>(
                        builder: (context, cart, child) {
                          final selectedCount = cart.selectedCartItems.length;
                          return Text(
                            'Selected: $selectedCount item(s)',
                            style: Theme.of(context).textTheme.titleMedium,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (authViewModel.user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please sign in to submit bookings',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (cartViewModel.selectedCartItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select at least one class to book',
                                  ),
                                ),
                              );
                              return;
                            }

                            final success = await cartViewModel
                                .submitSelectedItems(
                                  authViewModel.user!,
                                  await classViewModel.getCourses(),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Selected bookings submitted successfully'
                                      : 'Error submitting bookings',
                                ),
                              ),
                            );
                          },
                          child: const Text('Book Selected Classes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
