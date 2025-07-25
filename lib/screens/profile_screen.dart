import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodels/auth_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isEditingName = false;
  bool _isChangingPassword = false;
  bool _isLoadingUserData = true; // Add loading state for user data
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _debugUserDocument(); // Add debug method
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes visible
    _loadUserData();
  }

  // Debug method to check user document structure
  Future<void> _debugUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        debugPrint('=== DEBUG USER DOCUMENT ===');
        debugPrint('User UID: ${user.uid}');
        debugPrint('User Email: ${user.email}');
        debugPrint('Document exists: ${doc.exists}');

        if (doc.exists) {
          final data = doc.data()!;
          debugPrint('Document data: $data');
          debugPrint('Has name field: ${data.containsKey('name')}');
          debugPrint('Name value: "${data['name']}"');
          debugPrint('Name type: ${data['name'].runtimeType}');
        }
        debugPrint('=== END DEBUG ===');
      } catch (e) {
        debugPrint('Debug error: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
      });

      // Load user data from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final name = data['name'] ?? '';
          debugPrint(
            'Loaded user data - Name: "$name", Email: "${user.email}"',
          );
          debugPrint('Firestore data: $data');
          debugPrint(
            'Name controller before update: "${_nameController.text}"',
          );

          setState(() {
            _nameController.text = name;
            _isLoadingUserData = false;
          });

          debugPrint('Name controller after update: "${_nameController.text}"');

          // If user doesn't have a name field, add it
          if (!data.containsKey('name')) {
            debugPrint(
              'User document missing name field, adding empty name field',
            );
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'name': ''});
          }
        } else {
          debugPrint('User document does not exist in Firestore');
          setState(() {
            _isLoadingUserData = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        setState(() {
          _isLoadingUserData = false;
        });
      }
    } else {
      debugPrint('No current user found');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Name cannot be empty';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': _nameController.text.trim()});

        setState(() {
          _isEditingName = false;
          _successMessage = 'Name updated successfully';
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update name: ${e.toString()}';
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    // Validation
    if (_currentPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Current password is required';
        _successMessage = null;
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'New password must be at least 6 characters';
        _successMessage = null;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Re-authenticate user with current password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(_newPasswordController.text);

        setState(() {
          _isChangingPassword = false;
          _successMessage = 'Password changed successfully';
          _errorMessage = null;
        });

        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      String errorMessage = 'Failed to change password';
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'New password is too weak';
      }

      setState(() {
        _errorMessage = errorMessage;
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('Manual refresh triggered');
              _loadUserData();
            },
            tooltip: 'Refresh Profile Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingUserData
                      ? const CircularProgressIndicator()
                      : Text(
                          _nameController.text.trim().isEmpty
                              ? 'No Name'
                              : _nameController.text.trim(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Error/Success Messages
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null || _successMessage != null)
              const SizedBox(height: 16),

            // Name Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isEditingName)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditingName = true;
                                _errorMessage = null;
                                _successMessage = null;
                              });
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingName) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _updateName,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditingName = false;
                                _errorMessage = null;
                                _successMessage = null;
                              });
                              _loadUserData(); // Reset name field
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ] else ...[
                      _isLoadingUserData
                          ? const SizedBox(
                              height: 20,
                              child: LinearProgressIndicator(),
                            )
                          : Text(
                              _nameController.text.trim().isEmpty
                                  ? 'No name set'
                                  : _nameController.text.trim(),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Email Section (Read-only)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email cannot be changed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isChangingPassword)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isChangingPassword = true;
                                _errorMessage = null;
                                _successMessage = null;
                              });
                            },
                            icon: const Icon(Icons.lock),
                            label: const Text('Change'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isChangingPassword) ...[
                      TextField(
                        controller: _currentPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Change Password'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isChangingPassword = false;
                                _errorMessage = null;
                                _successMessage = null;
                              });
                              _currentPasswordController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text('••••••••', style: TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await authViewModel.signOut(clearRememberMe: false);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          debugPrint('=== DEBUG BUTTON PRESSED ===');
          debugPrint('Current name controller text: "${_nameController.text}"');
          debugPrint(
            'Current email controller text: "${_emailController.text}"',
          );
          debugPrint('Is loading user data: $_isLoadingUserData');
          _debugUserDocument();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Name: "${_nameController.text}" - Check console for debug info',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        child: const Icon(Icons.bug_report),
        tooltip: 'Debug Profile Data',
      ),
    );
  }
}
