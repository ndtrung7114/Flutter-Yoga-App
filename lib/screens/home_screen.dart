import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'auth_screen.dart';
import 'class_list_screen.dart';
import 'cart_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Yoga Booking App'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingsScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authViewModel.signOut(clearRememberMe: false);
                  },
                ),
              ],
            ),
            body: const ClassListScreen(),
          );
        }
        return const AuthScreen();
      },
    );
  }
}
