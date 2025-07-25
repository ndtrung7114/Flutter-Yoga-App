import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? _errorMessage;
  bool _isRememberMe = false;
  bool _hasManuallySignedOut = false;

  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isRememberMe => _isRememberMe;

  // SharedPreferences keys
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyManualSignOut = 'manual_sign_out';

  AuthViewModel() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    _loadRememberMe();
  }

  // Load remember me status and try auto-login
  Future<void> _loadRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isRememberMe = prefs.getBool(_keyRememberMe) ?? false;
      _hasManuallySignedOut = prefs.getBool(_keyManualSignOut) ?? false;

      debugPrint('Remember me status loaded: $_isRememberMe');
      debugPrint('Manual sign out flag: $_hasManuallySignedOut');

      if (_isRememberMe && !_hasManuallySignedOut) {
        final email = prefs.getString(_keyEmail);
        final password = prefs.getString(_keyPassword);

        if (email != null &&
            password != null &&
            email.isNotEmpty &&
            password.isNotEmpty) {
          debugPrint('Auto-login attempt for: $email');
          // Small delay to ensure Firebase is ready
          await Future.delayed(const Duration(milliseconds: 500));
          final success = await signIn(email, password, saveCredentials: false);

          if (!success) {
            debugPrint('Auto-login failed, but keeping remember me preference');
          }
        } else {
          debugPrint('Remember me is enabled but no saved credentials found');
        }
      } else if (_hasManuallySignedOut) {
        debugPrint('User manually signed out - skipping auto-login');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading remember me: $e');
      notifyListeners();
    }
  }

  // Save or clear remember me credentials
  Future<void> _saveRememberMe(String? email, String? password) async {
    final prefs = await SharedPreferences.getInstance();

    if (_isRememberMe && email != null && password != null) {
      await prefs.setBool(_keyRememberMe, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyPassword, password);
      debugPrint('Credentials saved for remember me');
    } else {
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPassword);
      debugPrint('Credentials cleared');
    }
  }

  // Get saved credentials for auto-fill
  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isRememberMeEnabled = prefs.getBool(_keyRememberMe) ?? false;

    debugPrint(
      'Getting saved credentials - Remember me enabled: $isRememberMeEnabled',
    );

    if (isRememberMeEnabled) {
      final email = prefs.getString(_keyEmail);
      final password = prefs.getString(_keyPassword);
      debugPrint(
        'Found saved email: ${email != null ? "***@${email.split('@').last}" : "null"}',
      );

      return {'email': email, 'password': password};
    } else {
      return {'email': null, 'password': null};
    }
  }

  // Toggle remember me status
  void toggleRememberMe(bool value) {
    _isRememberMe = value;
    debugPrint('Remember me toggled to: $value');

    if (!value) {
      // User explicitly unchecked remember me - clear everything
      _saveRememberMe(null, null);
      debugPrint('User disabled remember me - clearing all credentials');
    } else {
      // User checked remember me - save the preference
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) => p.setBool(_keyRememberMe, true));
      debugPrint('User enabled remember me - preference saved');
    }
    notifyListeners();
  }

  // Reset error message
  void resetErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method to completely clear remember me (for testing or user request)
  Future<void> clearRememberMe() async {
    debugPrint('Completely clearing remember me preference');
    _isRememberMe = false;
    await _saveRememberMe(null, null);
    notifyListeners();
  }

  // Method to update user profile information
  Future<bool> updateUserProfile({String? name}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'No user is currently signed in';
        notifyListeners();
        return false;
      }

      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updateData);
        debugPrint('User profile updated successfully');
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      notifyListeners();
      debugPrint('Profile update error: $e');
      return false;
    }
  }

  // Method to ensure user document has all required fields
  Future<void> ensureUserDocumentComplete() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final updates = <String, dynamic>{};

        // Check if name field exists, if not add empty string
        if (!data.containsKey('name')) {
          updates['name'] = '';
          debugPrint('Adding missing name field to user document');
        }

        // Apply updates if any
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
          debugPrint('User document updated with missing fields: $updates');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring user document completeness: $e');
    }
  }

  Future<bool> signUp(String email, String password, {String? name}) async {
    try {
      // Check if email already exists
      bool emailExists = await checkEmailExists(email);
      if (emailExists) {
        _errorMessage = 'An account with this email already exists.';
        notifyListeners();
        return false;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Create a document in the users collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name ?? '', // Add name field
        'role': 'user', // Set role to 'user' for User app
        'createdAt': DateTime.now().toString().split(
          ' ',
        )[0], // Add createdAt field as date string
      });
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().split('] ')[1];
      notifyListeners();
      debugPrint('Sign-up error: $e');
      return false;
    }
  }

  Future<bool> signIn(
    String email,
    String password, {
    bool saveCredentials = true,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check user role in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final userRole = userData?['role'];

        if (userRole != 'user') {
          // Sign out the user if they don't have 'user' role
          await _auth.signOut();
          _errorMessage = 'Access denied. This app is only for users.';
          notifyListeners();
          return false;
        }
      } else {
        // User document doesn't exist
        await _auth.signOut();
        _errorMessage = 'User data not found.';
        notifyListeners();
        return false;
      }

      // Save credentials if remember me is enabled and this is a manual login
      if (saveCredentials && _isRememberMe) {
        await _saveRememberMe(email, password);
        // Clear manual sign out flag since user has signed in manually
        _hasManuallySignedOut = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyManualSignOut);
        debugPrint(
          'Manual sign out flag cleared - auto-login will work on next app start',
        );
      }

      // Ensure user document has all required fields
      await ensureUserDocumentComplete();

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().split('] ')[1];
      notifyListeners();
      debugPrint('Sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut({bool clearRememberMe = false}) async {
    await _auth.signOut();

    final prefs = await SharedPreferences.getInstance();

    // Only clear remember me preference if explicitly requested
    if (clearRememberMe) {
      debugPrint('Clearing remember me preference completely');
      _isRememberMe = false;
      _hasManuallySignedOut = false;
      await _saveRememberMe(null, null);
      await prefs.remove(_keyManualSignOut);
    } else {
      debugPrint(
        'Sign out but preserving remember me preference and credentials',
      );
      // Set manual sign out flag to prevent auto-login until next manual sign in
      _hasManuallySignedOut = true;
      await prefs.setBool(_keyManualSignOut, true);
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().split('] ')[1];
      notifyListeners();
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  Future<bool> resetPasswordWithValidation(String email) async {
    try {
      // First validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _errorMessage = 'Please enter a valid email address.';
        notifyListeners();
        return false;
      }

      debugPrint('Attempting to send password reset email to: $email');

      // Check if user exists in Firestore and validate role
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        _errorMessage = 'No account found with this email address.';
        notifyListeners();
        return false;
      }

      // Check if user has 'user' role (not admin)
      final userData = userQuery.docs.first.data();
      final userRole = userData['role'];

      if (userRole != 'user') {
        _errorMessage = 'Password reset is only available for user accounts.';
        notifyListeners();
        return false;
      }

      // User exists and has correct role, send reset email
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent successfully to: $email');

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      debugPrint('Full password reset error: $errorMessage');

      if (errorMessage.contains('user-not-found') ||
          errorMessage.contains('USER_NOT_FOUND')) {
        _errorMessage = 'No account found with this email address.';
      } else if (errorMessage.contains('invalid-email') ||
          errorMessage.contains('INVALID_EMAIL')) {
        _errorMessage = 'Please enter a valid email address.';
      } else if (errorMessage.contains('too-many-requests') ||
          errorMessage.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
        _errorMessage = 'Too many requests. Please try again later.';
      } else if (errorMessage.contains('quota-exceeded')) {
        _errorMessage =
            'Service temporarily unavailable. Please try again later.';
      } else {
        // Extract the actual error message
        if (errorMessage.contains('] ')) {
          _errorMessage = errorMessage.split('] ')[1];
        } else {
          _errorMessage =
              'Failed to send password reset email. Please try again.';
        }
      }

      notifyListeners();
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      // Use Firestore to check if email exists instead of Firebase Auth
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return userQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Email check error: $e');
      return false;
    }
  }
}
