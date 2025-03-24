import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'screens/splash_screen.dart';
import 'services/api/crm_api_service.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'routes/app_router.dart';
import 'services/auth_state_provider.dart';
import 'models/user_model.dart' as app;

// Track Firebase initialization status globally
bool _firebaseInitialized = false;

void main() {
  // Initialize Flutter binding but don't await any async operations yet
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  
  // Show splash screen immediately before performing any initialization
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tijus Academy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: SplashScreen(
        initializationFuture: _initializeApp(),
        nextScreen: MyAppLoader(),
      ),
    ),
  );
}

// Widget that loads the actual app after initialization is complete
class MyAppLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _buildInitializedApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return snapshot.data!;
        }
        
        // Show error screen if initialization failed
        if (snapshot.hasError) {
          return ErrorApp();
        }
        
        // This should rarely be visible as the splash screen should cover this loading period
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// This initializes the app and returns a Future that completes when the initialization is done
Future<void> _initializeApp() async {
  // Adding minimal delay to ensure the splash screen is displayed
  // This could be removed but helps ensure the splash screen animation starts
  await Future.delayed(Duration(milliseconds: 50));
  
  try {
    // We don't need to do anything here as the actual initialization happens in _buildInitializedApp
    // This Future.delayed just ensures the splash screen shows for at least 1 second
    await Future.delayed(Duration(seconds: 1));
  } catch (e) {
    debugPrint('Error during app init: $e');
    // Still complete the future even with an error so splash screen can transition
  }
}

// Performs the actual app initialization and builds the main app widget
Future<Widget> _buildInitializedApp() async {
  try {
    // Initialize shared preferences
    debugPrint('Initializing SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
    
    late final AuthService authService;
    bool canUseFirebase = false;
    
    // Initialize Firebase
    if (!_firebaseInitialized) {
      try {
        if (Firebase.apps.isNotEmpty) {
          canUseFirebase = true;
          _firebaseInitialized = true;
        } else {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          canUseFirebase = true;
          _firebaseInitialized = true;
        }
      } catch (e) {
        try {
          await Firebase.initializeApp();
          canUseFirebase = true;
          _firebaseInitialized = true;
        } catch (fallbackError) {
          canUseFirebase = false;
        }
      }
    } else {
      canUseFirebase = true;
    }
    
    // Initialize auth service
    if (canUseFirebase) {
      try {
        authService = AuthService(
          auth: FirebaseAuth.instance,
          prefs: prefs,
        );
      } catch (authError) {
        authService = createDemoAuthService(prefs);
        await setupDemoUser(authService, prefs);
      }
    } else {
      authService = createDemoAuthService(prefs);
      await setupDemoUser(authService, prefs);
    }
    
    // Initialize router
    final appRouter = AppRouter(authService: authService);
    
    // Initialize API service
    final crmApiService = CrmApiService();
    
    // Return the fully initialized app widget
    return Provider<CrmApiService>.value(
      value: crmApiService,
      child: MyApp(
        router: appRouter.router,
        authStateProvider: appRouter.authStateProvider,
      ),
    );
  } catch (e) {
    debugPrint('Failed to initialize application: $e');
    return const ErrorApp();
  }
}
/// The main app widget that configures the router and theme
class MyApp extends StatelessWidget {
  final GoRouter router;
  final AuthStateProvider authStateProvider;
  
  const MyApp({
    Key? key,
    required this.router,
    required this.authStateProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthStateProvider>.value(
      value: authStateProvider,
      child: MaterialApp.router(
        title: 'Tijus Academy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tijus Academy - Error',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize the application',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Please close and restart the application manually.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please close and reopen the application to try again'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Creates a demo authentication service that doesn't rely on Firebase
AuthService createDemoAuthService(SharedPreferences prefs) {
  debugPrint('Creating demo auth service...');
  final demoAuth = DemoFirebaseAuth();
  debugPrint('Demo Firebase Auth instance created');
  
  final service = AuthService(
    auth: demoAuth,
    prefs: prefs,
  );
  debugPrint('Demo auth service created successfully');
  return service;
}

/// Sets up a demo user in the authentication service
Future<void> setupDemoUser(AuthService authService, SharedPreferences prefs) async {
  debugPrint('Setting up demo user...');
  try {
    // Create a demo user
    final demoUser = app.User(
      id: 'demo-user-id',
      name: 'Demo User',
      email: 'demo@tijusacademy.com',
      authToken: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
    );
    debugPrint('Demo user created with ID: ${demoUser.id}');
    
    // Save the demo user to preferences
    await authService.saveUserToPrefs(demoUser);
    debugPrint('Demo user saved to preferences successfully');
    
    // Verify the user was saved correctly
    final isLoggedIn = await authService.isLoggedIn();
    debugPrint('Demo user login state verification: ${isLoggedIn ? 'Success' : 'Failed'}');
  } catch (e) {
    debugPrint('Error setting up demo user: $e');
    // Create a simpler demo user as fallback
    final fallbackUser = app.User(
      id: 'fallback-user',
      name: 'Fallback User',
      email: 'fallback@example.com',
      authToken: 'fallback-token',
    );
    await authService.saveUserToPrefs(fallbackUser);
    debugPrint('Fallback demo user set up as alternative');
  }
}

/// A minimal implementation of FirebaseAuth for demo mode
class DemoFirebaseAuth implements FirebaseAuth {
  DemoUser? _currentUser;
  
  @override
  User? get currentUser => _currentUser;
  
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Create a new demo user
    _currentUser = DemoUser(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: 'New User',
    );
    
    return DemoUserCredential(user: _currentUser);
  }
  
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Sign in with demo user
    _currentUser = DemoUser(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: 'Signed In User',
    );
    
    return DemoUserCredential(user: _currentUser);
  }
  
  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
  
  @override
  Stream<User?> authStateChanges() {
    return Stream.value(_currentUser);
  }
  
  @override
  Stream<User?> userChanges() {
    return Stream.value(_currentUser);
  }
  
  @override
  Stream<User?> idTokenChanges() {
    return Stream.value(_currentUser);
  }
  
  // Implement noSuchMethod to handle other methods we don't use
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print('Warning: ${invocation.memberName} is not implemented in DemoFirebaseAuth');
    return null;
  }
}
/// A minimal implementation of User for demo mode
class DemoUser implements User {
  final String _uid;
  final String _email;
  String _displayName;
  
  DemoUser({
    required String uid,
    required String email,
    required String displayName,
  }) : _uid = uid,
       _email = email,
       _displayName = displayName;
  
  @override
  String get uid => _uid;
  
  @override
  String? get email => _email;
  
  @override
  String? get displayName => _displayName;
  
  @override
  bool get emailVerified => true;
  
  @override
  bool get isAnonymous => false;
  
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return 'demo-token-${DateTime.now().millisecondsSinceEpoch}';
  }
  
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    return DemoUserCredential(user: this);
  }
  
  @override
  Future<void> updateDisplayName(String? displayName) async {
    _displayName = displayName ?? '';
  }
  
  @override
  Future<void> updateEmail(String newEmail) async {
    // Do nothing in demo mode
  }
  
  @override
  Future<void> updatePassword(String newPassword) async {
    // Do nothing in demo mode
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print('Warning: ${invocation.memberName} is not implemented for DemoUser');
    return null;
  }
}

/// A demo implementation of UserCredential for demo mode
class DemoUserCredential implements UserCredential {
  @override
  final DemoUser? user;
  
  DemoUserCredential({this.user});
  
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
  
  @override
  AuthCredential? get credential => null;
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print('Warning: ${invocation.memberName} is not implemented for DemoUserCredential');
    return null;
  }
}

/// A specialized error screen widget for network or initialization errors
/// This provides a user-friendly error message with a retry button
class NetworkErrorApp extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const NetworkErrorApp({
    Key? key, 
    this.errorMessage = 'Unable to connect to the server',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tijus Academy - Network Error',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Connection Error'),
          backgroundColor: Colors.deepOrange,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.signal_wifi_off,
                  size: 80, 
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 24),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry ?? () {
                    // Default retry action if none provided
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attempting to reconnect...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24, 
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
