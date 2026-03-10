import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'landing_screen.dart';
import 'subscription_screen.dart';

/// Splash screen that waits for DB + Auth before navigating.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initialize();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    // 0. Check internet connection first
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = 'No internet connection.';
        });
        return;
      }
    } catch (e) {
      debugPrint('[SPLASH] Connectivity check failed: $e');
      // Proceed cautiously if plugin fails
    }

    // 1. Connect DB (wait until done)
    try {
      await DatabaseService.instance.connect();
      debugPrint('[SPLASH] DB connected');
    } catch (e) {
      debugPrint('[SPLASH] DB failed: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to connect to server.';
      });
      return;
    }

    // 2. Init auth (fetches user from DB)
    try {
      await AuthService.init();
      debugPrint('[SPLASH] Auth ready — loggedIn=${AuthService.isLoggedIn}, profile=${AuthService.isProfileComplete}');
    } catch (e) {
      debugPrint('[SPLASH] Auth failed: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load user profile.';
      });
      return;
    }

    if (!mounted) return;

    // 3. Navigate based on state
    Widget destination;
    if (!AuthService.isLoggedIn || !AuthService.isProfileComplete) {
      destination = const LandingScreen();
    } else {
      // Check subscription
      try {
        final hasSub = await AuthService.hasActiveSubscription();
        if (!hasSub) {
          destination = const SubscriptionScreen();
        } else {
          destination = const HomeScreen();
        }
      } catch (e) {
        debugPrint('[SPLASH] Sub check failed: $e');
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to verify subscription.';
        });
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => destination,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.appName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 40),
              
              if (_hasError) ...[
                Text(
                  _errorMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.redAccent.shade100,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initialize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                // Pulsing loader
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Opacity(
                    opacity: 0.4 + (_pulseCtrl.value * 0.6),
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accentLight,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
