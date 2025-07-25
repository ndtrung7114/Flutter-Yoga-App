import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Load saved credentials if remember me was enabled
  Future<void> _loadSavedCredentials() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final credentials = await authViewModel.getSavedCredentials();

    if (mounted &&
        credentials['email'] != null &&
        credentials['password'] != null) {
      setState(() {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
      });
      debugPrint('Saved credentials loaded for auto-fill');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Sign Up' : 'Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Name field (only for sign up)
            if (_isSignUp) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            if (authViewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  authViewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            // Remember Me checkbox (only for sign in)
            if (!_isSignUp)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: authViewModel.isRememberMe,
                      onChanged: (value) {
                        authViewModel.toggleRememberMe(value ?? false);
                      },
                    ),
                    const Text('Remember Me'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();
                final name = _nameController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                if (_isSignUp && name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
                  );
                  return;
                }

                bool success;
                if (_isSignUp) {
                  success = await authViewModel.signUp(
                    email,
                    password,
                    name: name,
                  );
                } else {
                  success = await authViewModel.signIn(email, password);
                }
                if (success) {
                  // Navigation is handled automatically by main.dart Consumer<AuthViewModel>
                  debugPrint(
                    'Sign in successful, navigation handled automatically',
                  );
                }
              },
              child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                  // Clear form when switching modes
                  if (_isSignUp) {
                    _nameController.clear();
                    _emailController.clear();
                    _passwordController.clear();
                  } else {
                    _nameController
                        .clear(); // Clear name when switching to sign in
                    // Load saved credentials when switching back to sign in
                    Future.delayed(
                      Duration.zero,
                      () => _loadSavedCredentials(),
                    );
                  }
                });
                // Clear any previous errors without signing out
                final authViewModel = Provider.of<AuthViewModel>(
                  context,
                  listen: false,
                );
                authViewModel.resetErrorMessage();
              },
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign In'
                    : 'Need an account? Sign Up',
              ),
            ),
            if (!_isSignUp) // Only show forgot password on sign in screen
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
          ],
        ),
      ),
    );
  }
}
