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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  
  debugPrint('Starting app initialization...');
  
  // Initialize shared preferences
  debugPrint('Initializing SharedPreferences...');
  final prefs = await SharedPreferences.getInstance();
  debugPrint('SharedPreferences initialized successfully');
  
  late final AuthService authService;
  bool canUseFirebase = false;
  
  // Only try to initialize Firebase once
  if (!_firebaseInitialized) {
    try {
      debugPrint('Attempting to initialize Firebase...');
      
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase already initialized, using existing instance');
        canUseFirebase = true;
        _firebaseInitialized = true;
      } else {
        // Attempt to initialize Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        
        // If we get here, Firebase initialization succeeded
        canUseFirebase = true;
        _firebaseInitialized = true;
        debugPrint('Firebase initialized successfully with default options');
      }
    } catch (e, stackTrace) {
      // Detailed error logging
      debugPrint('Firebase initialization failed with error: $e');
      debugPrint('Error details: ${e.toString()}');
      debugPrint('Stack trace: $stackTrace');
      
      // Try again with a fallback approach if possible
      try {
        debugPrint('Attempting Firebase initialization with fallback...');
        await Firebase.initializeApp();
        canUseFirebase = true;
        _firebaseInitialized = true;
        debugPrint('Firebase initialized with fallback approach');
      } catch (fallbackError) {
        debugPrint('Fallback Firebase initialization also failed: $fallbackError');
        canUseFirebase = false;
      }
    }
  } else {
    debugPrint('Using previously initialized Firebase instance');
    canUseFirebase = true;
  }
  
  if (canUseFirebase) {
    try {
      debugPrint('Setting up Firebase Authentication...');
      // Use real Firebase authentication
      authService = AuthService(
        auth: FirebaseAuth.instance,
        prefs: prefs,
      );
      debugPrint('Firebase Authentication service initialized successfully');
    } catch (authError) {
      debugPrint('Failed to initialize Firebase Authentication: $authError');
      debugPrint('Falling back to demo authentication mode');
      
      // Create a demo auth service as fallback
      authService = createDemoAuthService(prefs);
      
      // Create a demo user
      await setupDemoUser(authService, prefs);
      debugPrint('Demo authentication mode activated due to auth service failure');
    }
  } else {
    debugPrint('Firebase unavailable, setting up demo authentication mode');
    // Create a demo auth service
    authService = createDemoAuthService(prefs);
    
    // Create a demo user
    await setupDemoUser(authService, prefs);
    debugPrint('Using demo mode with local authentication');
  }
  
  try {
    debugPrint('Initializing app router...');
    // Initialize the router
    final appRouter = AppRouter(authService: authService);
    debugPrint('Router initialized successfully');
    
    // Run the app
    debugPrint('Starting main application UI...');
    
    // Create the CRM API service
    final crmApiService = CrmApiService();
    debugPrint('CRM API service initialized');
    
    // Create a completer to track the app initialization process
    final appInitCompleter = Completer<void>();
    
    // Run the app with splash screen
    runApp(
      AppWithSplash(
        initializationFuture: appInitCompleter.future,
        appServices: Provider<CrmApiService>.value(
          value: crmApiService,
          child: MyApp(
            router: appRouter.router, 
            authStateProvider: appRouter.authStateProvider,
          ),
        ),
      ),
    );
    
    // Delay completion slightly to ensure splash screen animations have time to start
    Future.delayed(const Duration(milliseconds: 200), () {
    
      // Mark initialization as complete
      appInitCompleter.complete();
      debugPrint('Application started successfully');
    });
  } catch (e) {
    debugPrint('Failed to initialize the application: $e');
    // Fall back to error screen
    runApp(const ErrorApp());
  }
  
  debugPrint('Application initialization completed');
}
/// Wrapper widget that handles the splash screen transition
class AppWithSplash extends StatelessWidget {
  final Future<void> initializationFuture;
  final Widget appServices;
  
  const AppWithSplash({
    Key? key,
    required this.initializationFuture,
    required this.appServices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tijus Academy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: SplashScreen(
        initializationFuture: initializationFuture,
        nextScreen: appServices,
      ),
    );
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
