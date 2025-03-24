import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Future<void>? initializationFuture;

  const SplashScreen({
    Key? key, 
    required this.nextScreen,
    this.initializationFuture,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;
  
  // For staggered text animation
  final String _appName = "Tiju's Academy";
  late List<Animation<double>> _letterAnimations;

  @override
  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Continuous pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Continuous rotation animation controller
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    );

    // Logo fade-in and scale animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Pulsing animation for logo
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Gentle rotation animation for logo
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05, // Subtle rotation of 5%
    ).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.easeInOut,
      ),
    );

    // Slide animation for text container
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Create staggered animations for each letter
    _letterAnimations = List.generate(_appName.length, (index) {
      // Scale the timing to ensure all animations fit within 0.0 to 1.0 range
      // Reserve 0.4 for initial animations, use 0.5 for all letter animations
      final letterAnimDuration = 0.5; // 50% of the total animation time for all letters
      final perLetterDuration = letterAnimDuration / _appName.length;
      
      final startTime = 0.4 + (index * perLetterDuration); // Staggered start, scaled to fit
      final endTime = startTime + perLetterDuration; // Each animation takes equal portion
      
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      );
    });

    // Start animations
    _mainController.forward();
    
    // Start continuous animations
    _pulseController.repeat(reverse: true);
    _rotateController.repeat(reverse: true);
    // Use the initialization Future if provided, otherwise use a timer
    if (widget.initializationFuture != null) {
      _handleAppInitialization();
    } else {
      // Fallback to timer-based transition if no future is provided
      Timer(const Duration(seconds: 3), _navigateToNextScreen);
    }
  }

  Future<void> _handleAppInitialization() async {
    try {
      // Wait for the initialization to complete
      await widget.initializationFuture;
      
      // Ensure the splash animation has played for at least 1.5 seconds
      // for a better user experience
      final elapsedTime = DateTime.now().difference(_animationStartTime);
      if (elapsedTime < const Duration(milliseconds: 1500)) {
        await Future.delayed(Duration(
          milliseconds: 1500 - elapsedTime.inMilliseconds,
        ));
      }
      
      // Navigate to the main app screen
      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      // Still navigate to next screen even if there was an error
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  final _animationStartTime = DateTime.now();

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with enhanced animations (fade, scale, pulse, and rotate)
            FadeTransition(
              opacity: _fadeInAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: RotationTransition(
                    turns: _rotateAnimation,
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 80,
                          color: Theme.of(context).primaryColor, // Match app's theme
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // App name with staggered letter-by-letter animation
            SlideTransition(
              position: _slideAnimation,
              child: Hero(
                tag: 'app_title',
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_appName.length, (index) {
                      final letter = _appName[index];
                      return FadeTransition(
                        opacity: _letterAnimations[index],
                        child: ScaleTransition(
                          scale: _letterAnimations[index],
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            
            // Enhanced loading indicator with animations
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.9 + (_pulseController.value * 0.2),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

