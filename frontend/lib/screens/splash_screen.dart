import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    
    if (authProvider.isAuthenticated && mounted) {
      // Sync favorites and history on startup
      await authProvider.refreshAllData(context);
    }
    
    final isLoggedIn = authProvider.isAuthenticated;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isLoggedIn ? const HomeScreen() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF1E293B),
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "AURAFIT",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "NEO FASHION AI",
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
