import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'lawyer/lawyer_profile_completion_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkUserStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkUserStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Check if user is first time
      bool isFirstTime = await AuthService.isFirstTime();

      if (isFirstTime) {
        // Navigate to onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        // Check if user is logged in
        var session = await AuthService.getSavedUserSession();

        if (session['userId'] != null && AuthService.currentUser != null) {
          // User is logged in, check if lawyer needs to complete profile
          String userRole = session['role'] ?? '';
          if (userRole == AppConstants.lawyerRole) {
            bool isProfileCompleted =
                await AuthService.isLawyerProfileCompleted(
                  session['userId'] ?? '',
                );
            if (!isProfileCompleted) {
              // Lawyer needs to complete profile
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LawyerProfileCompletionScreen(),
                ),
              );
            } else {
              // Lawyer profile completed, navigate to home
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else {
            // Regular user, navigate to home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // User is not logged in, navigate to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // On error, navigate to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B4513), // Saddle Brown
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B4513), // Saddle Brown
              Color(0xFFA0522D), // Sienna
              Color(0xFF6B4423), // Dark Brown
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.gavel,
                          size: 60,
                          color: Color(0xFF8B4513), // Saddle Brown
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // App Name
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // App Tagline
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Legal Services at Your Fingertips',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),

              // Loading Indicator
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Loading Text
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Loading...',
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
