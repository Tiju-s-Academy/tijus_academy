import 'package:flutter/material.dart';
import 'package:tijus_academy/services/auth_service.dart';
import 'dart:async';

/// Auth state provider class to handle authentication state changes
class AuthStateProvider extends ChangeNotifier {
  final AuthService _authService;
  bool _isLoggedIn = false;
  bool _isLoading = true;

  AuthStateProvider({required AuthService authService}) : _authService = authService {
    _checkAuthState();
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();
    _isLoggedIn = await _authService.isLoggedIn();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _authService.login(email, password);
    await _checkAuthState();
  }

  Future<void> register(String email, String password, String name) async {
    await _authService.register(email, password, name);
    await _checkAuthState();
  }

  Future<void> logout() async {
    await _authService.logout();
    await _checkAuthState();
  }

  void refreshState() {
    _checkAuthState();
  }
}

/// A class that refreshes the router when authentication state changes
class AuthStateRefreshStream extends ChangeNotifier {
  late final StreamController<void> _controller;
  late final StreamSubscription<void> _subscription;
  final AuthStateProvider _authStateProvider;

  AuthStateRefreshStream(this._authStateProvider) {
    _controller = StreamController<void>.broadcast();
    _subscription = _controller.stream.listen((_) => notifyListeners());
    
    // Listen to auth state changes
    _authStateProvider.addListener(() {
      if (!_authStateProvider.isLoading) {
        _controller.add(null);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.close();
    super.dispose();
  }
}

