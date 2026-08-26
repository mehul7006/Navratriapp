import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isOrganizer => _currentUser?['user_type'] == 'organizer';
  bool get isUser => _currentUser?['user_type'] == 'user';
  bool get isSponsor => _currentUser?['user_type'] == 'sponsor';
  String? get houseNumber => _currentUser?['house_number'];

  // User Login: House Number = ID, Mobile = Password
  Future<bool> loginUser({
    required String houseNumber,
    required String mobileNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await DatabaseHelper.loginUser(
        houseNumber: houseNumber,
        mobileNumber: mobileNumber,
      );

      if (result != null) {
        _currentUser = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid house number or mobile number';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('ConnectException')) {
        _error = 'Cannot connect to database. Please check your connection.';
      } else if (msg.contains('timeout') || msg.contains('Timeout')) {
        _error = 'Database connection timed out. Please try again.';
      } else {
        _error = 'Login failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Organizer Login
  Future<bool> loginOrganizer({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await DatabaseHelper.loginOrganizer(
        username: username,
        password: password,
      );

      if (result != null) {
        _currentUser = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid username or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('ConnectException')) {
        _error = 'Cannot connect to database. Please check your connection.';
      } else if (msg.contains('timeout') || msg.contains('Timeout')) {
        _error = 'Database connection timed out. Please try again.';
      } else {
        _error = 'Login failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sponsor Login
  Future<bool> loginSponsor({
    required String houseNumber,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await DatabaseHelper.loginSponsor(
        houseNumber: houseNumber,
        password: password,
      );

      if (result != null) {
        _currentUser = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid house number or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('ConnectException')) {
        _error = 'Cannot connect to database. Please check your connection.';
      } else if (msg.contains('timeout') || msg.contains('Timeout')) {
        _error = 'Database connection timed out. Please try again.';
      } else {
        _error = 'Login failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register User
  Future<bool> registerUser({
    required String houseNumber,
    required String name,
    required String mobileNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await DatabaseHelper.registerUser(
        houseNumber: houseNumber,
        name: name,
        mobileNumber: mobileNumber,
      );

      if (userId > 0) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('ConnectException')) {
        _error = 'Cannot connect to database. Please check your connection.';
      } else if (msg.contains('timeout') || msg.contains('Timeout')) {
        _error = 'Database connection timed out. Please try again.';
      } else {
        _error = 'Registration failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update User Profile
  void updateUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    notifyListeners();
  }

  // Logout
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Clear Error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
