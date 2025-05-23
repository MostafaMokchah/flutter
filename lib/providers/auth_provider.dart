import 'package:flutter/material.dart';
import 'package:mon_sirh_mobile/models/user.dart';
import 'package:mon_sirh_mobile/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Attempts automatic login by checking stored tokens or session
  Future<void> tryAutoLogin() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.getCurrentUser();
      _errorMessage = null;
      print("tryAutoLogin success: $_currentUser");
    } catch (e) {
      _errorMessage = "Failed to auto-login: $e";
      _currentUser = null;
      print("tryAutoLogin failed with error: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Log in using email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authService.login(email, password);
      if (_currentUser != null) {
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = "Login failed. Please check your credentials.";
        _currentUser = null;
        return false;
      }
    } catch (e) {
      _errorMessage = "An error occurred during login: $e";
      _currentUser = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register a new user using email and password
  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authService.register(email, password);
      if (_currentUser != null) {
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = "Inscription échouée. Veuillez vérifier les informations.";
        _currentUser = null;
        return false;
      }
    } catch (e) {
      _errorMessage = "Erreur pendant l'inscription : $e";
      _currentUser = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the current user and clears auth data
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Error during logout: $e";
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Private helper to update loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
